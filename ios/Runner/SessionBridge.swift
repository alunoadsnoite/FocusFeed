import Flutter
import UIKit
import SwiftUI
import FamilyControls
import DeviceActivity
import UserNotifications

private struct AppSelectionView: View {
  @State var selection: FamilyActivitySelection
  var done: (FamilyActivitySelection?) -> Void
  var body: some View {
    NavigationStack {
      FamilyActivityPicker(selection: $selection)
        .navigationTitle("Apps para bloquear")
        .toolbar {
          ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { done(nil) } }
          ToolbarItem(placement: .confirmationAction) { Button("Salvar") { done(selection) } }
        }
    }
  }
}
final class SessionBridge {
  private static let worker = DispatchQueue(label: "focusfeed.session")
  private static var presenting = false
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "focusfeed/session", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      if call.method == "apps" { result([]); return }
      if call.method == "requestNotifications" {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
          DispatchQueue.main.async {
            if !granted, let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            result(granted)
          }
        }
        return
      }
      if call.method == "pickApps" { pickApps(result); return }
      let arguments = call.arguments as? [String: Any] ?? [:]
      worker.async {
        do {
          let before = try SessionCore.refresh(checkMonitoring: true)
          let progress: FocusProgress = try SessionCore.transaction { p in
            switch call.method {
            case "initialize", "status": break
            case "start":
              guard AuthorizationCenter.shared.authorizationStatus == .approved else { throw SessionCore.failure("Autorize o Screen Time antes de iniciar.") }
              guard !["focus", "reward"].contains(p.session.phase) else { throw SessionCore.failure("Já existe uma sessão ativa.") }
              let seconds = (arguments["seconds"] as? NSNumber)?.int64Value ?? p.session.focusTotalSeconds
              guard (60...3600).contains(seconds) else { throw SessionCore.failure("Duração inválida.") }
              if p.session.phase != "paused" && !(p.session.phase == "locked" && p.session.focusRemainingSeconds > 0 && !p.session.id.isEmpty) {
                p.session = FocusSession(id: UUID().uuidString, focusTotalSeconds: seconds, focusRemainingSeconds: seconds)
              }
              p.session.phase = "focus"; p.session.boot = SessionCore.boot
              p.session.deadlineElapsed = SessionCore.elapsed + p.session.focusRemainingSeconds * 1000
              p.session.deadlineWall = SessionCore.wall + p.session.focusRemainingSeconds * 1000
              p.notice = ""
            case "pause":
              guard p.session.phase == "focus" else { throw SessionCore.failure("Não há foco em andamento.") }
              p.session.phase = "paused"; p.session.deadlineElapsed = 0; p.session.deadlineWall = 0
            case "stop":
              let total = p.session.focusTotalSeconds
              p.session = FocusSession(focusTotalSeconds: total, focusRemainingSeconds: total); p.notice = ""
            case "reward":
              guard AuthorizationCenter.shared.authorizationStatus == .approved else { throw SessionCore.failure("Autorize o Screen Time antes de liberar as redes.") }
              let seconds = (arguments["seconds"] as? NSNumber)?.int64Value ?? 0
              guard seconds > 0, seconds <= p.rewardSeconds, seconds <= 86400,
                    p.session.phase != "reward" else { throw SessionCore.failure("Saldo insuficiente ou recompensa já ativa.") }
              p.session.resumeFocus = p.session.phase == "focus"
              if !["focus", "paused"].contains(p.session.phase) { p.session.focusRemainingSeconds = 0 }
              if p.session.id.isEmpty { p.session.id = UUID().uuidString }
              p.rewardSeconds -= seconds; p.session.phase = "reward"
              p.session.rewardRemainingSeconds = seconds
              p.session.deadlineElapsed = SessionCore.elapsed + seconds * 1000
              p.session.deadlineWall = SessionCore.wall + seconds * 1000
              p.session.boot = SessionCore.boot; p.notice = ""
            case "duration":
              let seconds = (arguments["seconds"] as? NSNumber)?.int64Value ?? 0
              guard p.session.phase == "idle", (60...3600).contains(seconds) else { throw SessionCore.failure("Pare a sessão antes de alterar a duração.") }
              p.session.focusTotalSeconds = seconds; p.session.focusRemainingSeconds = seconds
            default: throw SessionCore.failure("Operação desconhecida.")
            }
            return p
          }
          do {
            let name = SessionCore.monitorName(progress.session)
            if ["focus", "reward"].contains(progress.session.phase) {
              if !DeviceActivityCenter().activities.contains(name) { try SessionCore.schedule(progress) }
              else { try SessionCore.applyShields(progress) }
            } else { try SessionCore.schedule(progress) }
          } catch {
            try SessionCore.transaction { $0 = before }
            // Restore the previous protection if the system rejects a new schedule.
            do { try SessionCore.schedule(before) } catch {
              try SessionCore.transaction { SessionCore.interrupt(&$0, "Monitor indisponível. Retome o foco no app.") }
              SessionCore.store.clearAllSettings()
            }
            throw SessionCore.failure("O Screen Time não aceitou o agendamento. Nenhum saldo foi gasto. Tente novamente.")
          }
          respond(progress, result)
        } catch {
          DispatchQueue.main.async { result(FlutterError(code: "session_error", message: error.localizedDescription, details: nil)) }
        }
      }
    }
  }
  static func respond(_ p: FocusProgress, _ result: @escaping FlutterResult) {
    do {
      let encoded = String(data: try JSONEncoder().encode(p), encoding: .utf8)!
      let selection = try SessionCore.selection()
      let count = selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
      let phase = p.session.phase
      let running = phase == "locked" || (["focus", "reward"].contains(phase) && DeviceActivityCenter().activities.contains(SessionCore.monitorName(p.session)))
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        DispatchQueue.main.async { result(["progress": encoded, "monitorRunning": running,
          "permissionsReady": AuthorizationCenter.shared.authorizationStatus == .approved,
          "notificationsEnabled": [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus),
          "selectionCount": count, "platform": "ios"]) }
      }
    } catch { DispatchQueue.main.async { result(FlutterError(code: "storage_error", message: error.localizedDescription, details: nil)) } }
  }
  private static func pickApps(_ result: @escaping FlutterResult) {
    guard !presenting else { result(FlutterError(code: "busy", message: "Seleção já aberta.", details: nil)); return }
    do {
      let progress = try SessionCore.load()
      guard progress.session.phase == "idle", AuthorizationCenter.shared.authorizationStatus == .approved else {
        throw SessionCore.failure("Pare a sessão e autorize Screen Time antes de selecionar apps.")
      }
      let selection = try SessionCore.selection()
      let windows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }
      guard var host = windows.first(where: { $0.isKeyWindow })?.rootViewController else { throw SessionCore.failure("Tela indisponível.") }
      while let presented = host.presentedViewController { host = presented }
      presenting = true
      let picker = UIHostingController(rootView: AppSelectionView(selection: selection) { selected in
        host.dismiss(animated: true) {
          presenting = false
          do {
            if let selected { try SessionCore.saveSelection(selected) }
            respond(try SessionCore.load(), result)
          } catch { result(FlutterError(code: "storage_error", message: error.localizedDescription, details: nil)) }
        }
      })
      picker.isModalInPresentation = true
      host.present(picker, animated: true)
    } catch { result(FlutterError(code: "selection_error", message: error.localizedDescription, details: nil)) }
  }
}
final class FocusNoticeDelegate: NSObject, UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.banner, .list, .sound])
  }
}
