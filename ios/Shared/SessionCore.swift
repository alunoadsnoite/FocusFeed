import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import UserNotifications
import Darwin

struct FocusSession: Codable {
  var id = ""
  var phase = "idle"
  var focusTotalSeconds: Int64 = 1500
  var focusRemainingSeconds: Int64 = 1500
  var rewardRemainingSeconds: Int64 = 0
  var deadlineElapsed: Int64 = 0
  var deadlineWall: Int64 = 0
  var boot: Int64 = -1
  var resumeFocus = false
}
struct FocusEvent: Codable { var id: String; var title: String; var message: String }
struct FocusProgress: Codable {
  var version = 2
  var apps: [String: Bool] = [:]
  var rewardSeconds: Int64 = 0
  var focusByDay: [String: Int64] = [:]
  var session = FocusSession()
  var credited: Set<String> = []
  var events: [FocusEvent] = []
  var notice = ""
}

/// Shared by Runner and extensions. An App Group lock prevents duplicate credits.
enum SessionCore {
  static let group = "group.io.github.alunoadsnoite.focusfeed"
  static let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("focusfeed"))
  static var elapsed: Int64 {
    var info = mach_timebase_info_data_t()
    mach_timebase_info(&info)
    return Int64(Double(mach_continuous_time()) * Double(info.numer) / Double(info.denom) / 1_000_000)
  }
  static var wall: Int64 { Int64(Date().timeIntervalSince1970 * 1000) }
  static var boot: Int64 { (wall - elapsed) / 1000 }
  static func active(_ phase: String) -> Bool { ["focus", "reward", "locked"].contains(phase) }
  static func label(_ seconds: Int64) -> String {
    seconds % 60 == 0 ? "\(seconds / 60) min" : "\(seconds / 60) min \(seconds % 60) s"
  }
  static func directory() throws -> URL {
    guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
      throw failure("Configure o App Group e a assinatura no Xcode para salvar a sessão compartilhada.")
    }
    return url
  }
  static func failure(_ message: String) -> NSError { NSError(domain: "FocusFeed", code: 1, userInfo: [NSLocalizedDescriptionKey: message]) }
  static func withLock<T>(_ operation: (URL) throws -> T) throws -> T {
    let directory = try directory()
    let fd = open(directory.appendingPathComponent("session.lock").path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
    guard fd >= 0 else { throw failure("Falha no armazenamento local.") }
    defer { flock(fd, LOCK_UN); close(fd) }
    guard flock(fd, LOCK_EX) == 0 else { throw failure("Falha ao acessar o progresso.") }
    return try operation(directory)
  }
  static func read(_ url: URL) throws -> FocusProgress {
    let file = url.appendingPathComponent("progress-v2.json")
    if FileManager.default.fileExists(atPath: file.path) {
      let p = try JSONDecoder().decode(FocusProgress.self, from: Data(contentsOf: file))
      guard p.version == 2, p.rewardSeconds >= 0,
            ["idle", "focus", "paused", "reward", "locked"].contains(p.session.phase),
            (1...3600).contains(p.session.focusTotalSeconds), p.session.focusRemainingSeconds >= 0,
            p.session.rewardRemainingSeconds >= 0, p.focusByDay.values.allSatisfy({ $0 >= 0 }) else {
        throw failure("Progresso salvo inválido; nenhum dado foi sobrescrito.")
      }
      return p
    }
    var p = FocusProgress()
    if let old = UserDefaults.standard.string(forKey: "focusfeed.progress.v1"),
       let data = old.data(using: .utf8) {
      guard let j = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            j["version"] as? Int == 1, let balance = j["rewardSeconds"] as? Int64,
            let history = j["focusByDay"] as? [String: Int64], balance >= 0 else {
        throw failure("Progresso anterior inválido.")
      }
      p.rewardSeconds = balance; p.focusByDay = history
    }
    // Persist the migration before an extension can create an empty ledger.
    try write(p, url)
    return p
  }
  static func write(_ p: FocusProgress, _ url: URL) throws {
    try JSONEncoder().encode(p).write(to: url.appendingPathComponent("progress-v2.json"), options: .atomic)
  }
  static func load() throws -> FocusProgress { try withLock { try read($0) } }
  static func transaction<T>(_ operation: (inout FocusProgress) throws -> T) throws -> T {
    try withLock { url in
      var p = try read(url)
      let result = try operation(&p)
      try write(p, url)
      return result
    }
  }
  static func selection() throws -> FamilyActivitySelection {
    let url = try directory().appendingPathComponent("selection.json")
    if !FileManager.default.fileExists(atPath: url.path) { return FamilyActivitySelection() }
    return try JSONDecoder().decode(FamilyActivitySelection.self, from: Data(contentsOf: url))
  }
  static func saveSelection(_ selection: FamilyActivitySelection) throws {
    try withLock { try JSONEncoder().encode(selection).write(to: $0.appendingPathComponent("selection.json"), options: .atomic) }
  }
  static func interrupt(_ p: inout FocusProgress, _ reason: String) {
    if ["focus", "reward"].contains(p.session.phase) {
      p.session.phase = p.session.focusRemainingSeconds > 0 && !p.session.id.isEmpty ? "paused" : "locked"
      p.session.rewardRemainingSeconds = 0
      p.session.resumeFocus = false
      p.session.deadlineElapsed = 0; p.session.deadlineWall = 0
    }
    p.notice = reason
  }
  static func advance(_ p: inout FocusProgress) {
    guard active(p.session.phase) else { return }
    if p.session.phase != "locked" && abs(p.session.boot - boot) > 5 {
      interrupt(&p, "Celular reiniciado ou relógio alterado. O foco foi pausado sem gerar crédito durante a interrupção.")
      return
    }
    if p.session.phase == "reward" {
      p.session.rewardRemainingSeconds = max(0, (p.session.deadlineElapsed - elapsed + 999) / 1000)
      if p.session.rewardRemainingSeconds > 0 { return }
      p.events.append(FocusEvent(id: "reward-\(p.session.id)-\(p.session.deadlineWall)", title: "Pausa encerrada", message: "Seu tempo de pausa acabou!"))
      p.session.phase = p.session.resumeFocus ? "focus" : "locked"
      if p.session.resumeFocus {
        p.session.deadlineElapsed += p.session.focusRemainingSeconds * 1000
        p.session.deadlineWall += p.session.focusRemainingSeconds * 1000
        p.session.resumeFocus = false
      }
    }
    if p.session.phase == "focus" {
      p.session.focusRemainingSeconds = max(0, (p.session.deadlineElapsed - elapsed + 999) / 1000)
      if p.session.focusRemainingSeconds == 0 {
        if p.credited.insert(p.session.id).inserted {
          let earned = p.session.focusTotalSeconds / 5
          p.rewardSeconds += earned
          let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"; formatter.locale = Locale(identifier: "en_US_POSIX")
          let day = formatter.string(from: Date(timeIntervalSince1970: Double(p.session.deadlineWall) / 1000))
          p.focusByDay[day, default: 0] += p.session.focusTotalSeconds
          p.events.append(FocusEvent(id: "focus-\(p.session.id)", title: "Foco concluído!", message: "Foco concluído! Você ganhou \(label(earned))"))
        }
        p.session.phase = "idle"; p.session.deadlineElapsed = 0; p.session.deadlineWall = 0
        p.notice = "Foco concluído. Recompensa adicionada ao saldo."
      }
    }
  }
  static func monitorName(_ s: FocusSession) -> DeviceActivityName {
    DeviceActivityName("focusfeed.\(s.id).\(s.phase).\(s.deadlineWall)")
  }
  static func applyShields(_ p: FocusProgress) throws {
    let selection = try selection()
    let blocking = ["focus", "locked"].contains(p.session.phase) && AuthorizationCenter.shared.authorizationStatus == .approved
    store.shield.applications = blocking && !selection.applicationTokens.isEmpty ? selection.applicationTokens : nil
    store.shield.applicationCategories = blocking && !selection.categoryTokens.isEmpty ? .specific(selection.categoryTokens) : nil
    store.shield.webDomains = blocking && !selection.webDomainTokens.isEmpty ? selection.webDomainTokens : nil
  }
  static func schedule(_ p: FocusProgress) throws {
    let center = DeviceActivityCenter()
    let old = center.activities
    guard ["focus", "reward"].contains(p.session.phase) else {
      if !old.isEmpty { center.stopMonitoring(old) }; try applyShields(p); return
    }
    let end = Date(timeIntervalSince1970: Double(p.session.deadlineWall) / 1000)
    guard end > Date() else { try applyShields(p); return }
    // DeviceActivity requires a >=15-minute interval. An already-ongoing window
    // can end sooner: backdate the start, keeping the actual deadline unchanged.
    let start = min(Date(), end.addingTimeInterval(-16 * 60))
    let calendar = Calendar.current
    let units: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
    var startParts = calendar.dateComponents(units, from: start); startParts.calendar = calendar
    var endParts = calendar.dateComponents(units, from: end); endParts.calendar = calendar
    let name = monitorName(p.session)
    try center.startMonitoring(name, during: DeviceActivitySchedule(intervalStart: startParts, intervalEnd: endParts, repeats: false))
    let obsolete = old.filter { $0 != name }
    if !obsolete.isEmpty { center.stopMonitoring(obsolete) }
    try applyShields(p)
  }
  static func deliverEvents() throws {
    let events: [FocusEvent] = try transaction { p in
      let events = p.events; p.events = []; return events
    }
    for event in events {
      let content = UNMutableNotificationContent(); content.title = event.title; content.body = event.message; content.sound = .default
      UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: event.id, content: content, trigger: nil))
    }
  }
  static func refresh(checkMonitoring: Bool = false) throws -> FocusProgress {
    let p: FocusProgress = try transaction { p in
      if active(p.session.phase) && AuthorizationCenter.shared.authorizationStatus != .approved {
        interrupt(&p, "Autorização Screen Time revogada. Retome o foco após autorizar.")
      } else if checkMonitoring && ["focus", "reward"].contains(p.session.phase) &&
                  !DeviceActivityCenter().activities.contains(monitorName(p.session)) {
        interrupt(&p, "Monitor interrompido. Foco pausado para evitar crédito sem proteção.")
      } else { advance(&p) }
      return p
    }
    try applyShields(p)
    try deliverEvents()
    return p
  }
}
