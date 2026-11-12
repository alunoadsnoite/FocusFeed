import ManagedSettings
import ManagedSettingsUI
import UIKit

final class FocusShield: ShieldConfigurationDataSource {
  private func configuration() -> ShieldConfiguration {
    let balance = (try? SessionCore.load().rewardSeconds) ?? 0
    let title = SessionCore.localized(
      "Você está em momento de foco! Mantenha a concentração.",
      "You're in a focus session. Stay focused.",
      "Estás en una sesión de enfoque. Mantén la concentración.")
    let subtitle = balance == 0
      ? SessionCore.localized(
          "Saldo: 0 min. Conclua um foco para ganhar recompensa.",
          "Balance: 0 min. Complete a focus session to earn reward time.",
          "Saldo: 0 min. Completa una sesión de enfoque para ganar tiempo.")
      : SessionCore.localized(
          "Use seu saldo no FocusFeed para liberar as redes.",
          "Use your balance in FocusFeed to unblock apps.",
          "Usa tu saldo en FocusFeed para desbloquear las apps.")
    let back = SessionCore.localized("Voltar ao FocusFeed", "Back to FocusFeed", "Volver a FocusFeed")
    return ShieldConfiguration(backgroundBlurStyle: .systemMaterialDark,
      backgroundColor: UIColor(red: 0.05, green: 0.18, blue: 0.17, alpha: 1),
      icon: UIImage(systemName: "timer"),
      title: ShieldConfiguration.Label(text: title, color: .white),
      subtitle: ShieldConfiguration.Label(text: subtitle, color: .white),
      primaryButtonLabel: ShieldConfiguration.Label(text: back, color: .white),
      primaryButtonBackgroundColor: .systemTeal)
  }
  override func configuration(shielding application: Application) -> ShieldConfiguration { configuration() }
  override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration { configuration() }
  override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration { configuration() }
  override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration { configuration() }
}
