import XCTest
@testable import Runner

final class RunnerTests: XCTestCase {
  func testCompletionCreditsExactlyOnce() {
    var p = FocusProgress()
    p.session = FocusSession(id: "focus-test", phase: "focus", focusTotalSeconds: 1500,
      focusRemainingSeconds: 1, deadlineElapsed: SessionCore.elapsed - 1000,
      deadlineWall: SessionCore.wall - 1000, boot: SessionCore.boot)
    SessionCore.advance(&p); SessionCore.advance(&p)
    XCTAssertEqual(p.rewardSeconds, 300)
    XCTAssertEqual(p.focusByDay.values.reduce(0, +), 1500)
    XCTAssertEqual(p.credited, ["focus-test"])
    XCTAssertEqual(p.events.count, 1)
  }
  func testRebootDoesNotGenerateReward() {
    var p = FocusProgress()
    p.session = FocusSession(id: "reboot-test", phase: "focus", focusTotalSeconds: 60,
      focusRemainingSeconds: 30, deadlineElapsed: 0, deadlineWall: SessionCore.wall,
      boot: SessionCore.boot - 3600)
    SessionCore.advance(&p)
    XCTAssertEqual(p.session.phase, "paused")
    XCTAssertEqual(p.session.focusRemainingSeconds, 30)
    XCTAssertEqual(p.rewardSeconds, 0)
  }
  func testRewardExpiryReturnsToLocked() {
    var p = FocusProgress()
    p.session = FocusSession(id: "reward-test", phase: "reward", focusRemainingSeconds: 0,
      rewardRemainingSeconds: 1, deadlineElapsed: SessionCore.elapsed - 1000,
      deadlineWall: SessionCore.wall - 1000, boot: SessionCore.boot)
    SessionCore.advance(&p)
    XCTAssertEqual(p.session.phase, "locked")
    XCTAssertEqual(p.rewardSeconds, 0)
    XCTAssertEqual(p.events.singleMessage, "Seu tempo de pausa acabou!")
  }
  func testSnapshotRoundTripPreservesFractionsAndSessionIdentity() throws {
    var p = FocusProgress(); p.rewardSeconds = 312
    p.session.id = "saved-session"; p.session.phase = "paused"; p.session.focusRemainingSeconds = 900
    let decoded = try JSONDecoder().decode(FocusProgress.self, from: JSONEncoder().encode(p))
    XCTAssertEqual(decoded.rewardSeconds, 312)
    XCTAssertEqual(decoded.session.id, "saved-session")
    XCTAssertEqual(decoded.session.focusRemainingSeconds, 900)
  }
}
private extension Array where Element == FocusEvent {
  var singleMessage: String? { count == 1 ? first?.message : nil }
}
