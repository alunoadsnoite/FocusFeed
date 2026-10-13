import ManagedSettings
import UserNotifications

final class FocusShieldAction: ShieldActionDelegate {
  private func respond(_ action: ShieldAction, completion: @escaping (ShieldActionResponse) -> Void) {
    // Define this flag only with an SDK that includes the iOS 26.5 API.
    #if FOCUSFEED_OPEN_PARENT_APP
    if #available(iOS 26.5, *) { completion(.openParentalControlsApp); return }
    #endif
    // Older iOS versions do not expose a public API to open the host from a shield.
    // Close the blocked app; tapping this local notification opens Runner normally.
    let content = UNMutableNotificationContent()
    content.title = "Voltar ao FocusFeed"; content.body = "Toque para abrir o FocusFeed e consultar seu timer e saldo."
    UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "open-focusfeed", content: content, trigger: nil))
    completion(.close)
  }
  override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) { respond(action, completion: completionHandler) }
  override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) { respond(action, completion: completionHandler) }
  override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) { respond(action, completion: completionHandler) }
}
