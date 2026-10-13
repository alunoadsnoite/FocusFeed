import ManagedSettings
import ManagedSettingsUI
import UIKit

final class FocusShield: ShieldConfigurationDataSource {
  private func configuration() -> ShieldConfiguration {
    let balance = (try? SessionCore.load().rewardSeconds) ?? 0
    return ShieldConfiguration(backgroundBlurStyle: .systemMaterialDark,
      backgroundColor: UIColor(red: 0.05, green: 0.18, blue: 0.17, alpha: 1),
      icon: UIImage(systemName: "timer"),
      title: ShieldConfiguration.Label(text: "Você está em momento de foco! Mantenha a concentração.", color: .white),
      subtitle: ShieldConfiguration.Label(text: balance == 0 ? "Saldo: 0 min. Conclua um foco para ganhar recompensa." : "Use seu saldo no FocusFeed para liberar as redes.", color: .white),
      primaryButtonLabel: ShieldConfiguration.Label(text: "Voltar ao FocusFeed", color: .white),
      primaryButtonBackgroundColor: .systemTeal)
  }
  override func configuration(shielding application: Application) -> ShieldConfiguration { configuration() }
  override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration { configuration() }
  override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration { configuration() }
  override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration { configuration() }
}
