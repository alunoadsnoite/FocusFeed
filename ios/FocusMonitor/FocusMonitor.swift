import DeviceActivity
import Foundation

final class FocusMonitor: DeviceActivityMonitor {
  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    reconcile(activity)
  }
  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    reconcile(activity)
  }
  private func reconcile(_ activity: DeviceActivityName) {
    do {
      let before = try SessionCore.load()
      // stopMonitoring also invokes intervalDidEnd: ignore obsolete callbacks.
      guard SessionCore.monitorName(before.session) == activity else { return }
      let p = try SessionCore.refresh()
      if SessionCore.monitorName(p.session) != activity { try SessionCore.schedule(p) }
    } catch {
      // Remove stale shields if persistent storage/monitoring becomes unavailable.
      SessionCore.store.clearAllSettings()
      try? SessionCore.transaction { SessionCore.interrupt(&$0, "Monitor Screen Time interrompido. Abra o FocusFeed para retomar.") }
    }
  }
}
