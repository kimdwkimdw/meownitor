import Foundation
import XCTest

@testable import Meownitor

final class MonitorPolicyTests: XCTestCase {
  func testPortableWarningNeeds25ActiveMinutesWithoutExternalGear() {
    var configuration = MonitorPolicy.Configuration()
    configuration.postureWarningAfter = 25 * 60
    var policy = MonitorPolicy(configuration: configuration)
    let start = Date(timeIntervalSince1970: 0)

    XCTAssertEqual(policy.evaluate(snapshot(at: start)), .none)
    for second in stride(from: 5, through: 25 * 60, by: 5) {
      let action = policy.evaluate(snapshot(at: start.addingTimeInterval(TimeInterval(second))))
      if second < 25 * 60 {
        XCTAssertEqual(action, .none)
      } else {
        XCTAssertEqual(action, .showLargeCat)
      }
    }
  }

  func testExternalKeyboardResetsPortableSession() {
    var configuration = MonitorPolicy.Configuration()
    configuration.postureWarningAfter = 10
    var policy = MonitorPolicy(configuration: configuration)
    let start = Date(timeIntervalSince1970: 0)

    XCTAssertEqual(policy.evaluate(snapshot(at: start)), .none)
    XCTAssertEqual(policy.evaluate(snapshot(at: start.addingTimeInterval(5))), .none)
    XCTAssertEqual(
      policy.evaluate(snapshot(at: start.addingTimeInterval(10), externalKeyboard: true)),
      .none
    )
    XCTAssertEqual(policy.activeSeconds, 0)
  }

  func testExternalDisplayResetsPortableSession() {
    var configuration = MonitorPolicy.Configuration()
    configuration.postureWarningAfter = 10
    var policy = MonitorPolicy(configuration: configuration)
    let start = Date(timeIntervalSince1970: 0)

    XCTAssertEqual(policy.evaluate(snapshot(at: start)), .none)
    XCTAssertEqual(policy.evaluate(snapshot(at: start.addingTimeInterval(5))), .none)
    XCTAssertEqual(
      policy.evaluate(snapshot(at: start.addingTimeInterval(10), externalDisplay: true)),
      .none
    )
    XCTAssertEqual(policy.activeSeconds, 0)
    XCTAssertEqual(policy.evaluate(snapshot(at: start.addingTimeInterval(15))), .none)
    XCTAssertEqual(policy.evaluate(snapshot(at: start.addingTimeInterval(20))), .showLargeCat)
  }

  func testShortIdlePausesAndLongIdleResetsSession() {
    var configuration = MonitorPolicy.Configuration()
    configuration.postureWarningAfter = 10
    var pausedPolicy = MonitorPolicy(configuration: configuration)
    let start = Date(timeIntervalSince1970: 0)

    XCTAssertEqual(pausedPolicy.evaluate(snapshot(at: start)), .none)
    XCTAssertEqual(pausedPolicy.evaluate(snapshot(at: start.addingTimeInterval(5))), .none)
    XCTAssertEqual(
      pausedPolicy.evaluate(snapshot(at: start.addingTimeInterval(10), idleSeconds: 90)),
      .none
    )
    XCTAssertEqual(pausedPolicy.activeSeconds, 5)
    XCTAssertEqual(
      pausedPolicy.evaluate(snapshot(at: start.addingTimeInterval(15))),
      .showLargeCat
    )

    var resetPolicy = MonitorPolicy(configuration: configuration)
    XCTAssertEqual(resetPolicy.evaluate(snapshot(at: start)), .none)
    XCTAssertEqual(resetPolicy.evaluate(snapshot(at: start.addingTimeInterval(5))), .none)
    XCTAssertEqual(
      resetPolicy.evaluate(snapshot(at: start.addingTimeInterval(10), idleSeconds: 300)),
      .none
    )
    XCTAssertEqual(resetPolicy.activeSeconds, 0)
    XCTAssertEqual(resetPolicy.evaluate(snapshot(at: start.addingTimeInterval(15))), .none)
    XCTAssertEqual(resetPolicy.evaluate(snapshot(at: start.addingTimeInterval(20))), .showLargeCat)
  }

  func testWarningRearmsAfterAnotherFullSession() {
    var configuration = MonitorPolicy.Configuration()
    configuration.postureWarningAfter = 10
    var policy = MonitorPolicy(configuration: configuration)
    let start = Date(timeIntervalSince1970: 0)

    XCTAssertEqual(policy.evaluate(snapshot(at: start)), .none)
    XCTAssertEqual(policy.evaluate(snapshot(at: start.addingTimeInterval(5))), .none)
    XCTAssertEqual(policy.evaluate(snapshot(at: start.addingTimeInterval(10))), .showLargeCat)
    XCTAssertEqual(policy.evaluate(snapshot(at: start.addingTimeInterval(15))), .none)
    XCTAssertEqual(policy.evaluate(snapshot(at: start.addingTimeInterval(20))), .showLargeCat)
  }

  func testSnoozeWaitsThenWarnsOnTheNextActiveTick() {
    var configuration = MonitorPolicy.Configuration()
    configuration.postureWarningAfter = 10
    var policy = MonitorPolicy(configuration: configuration)
    let start = Date(timeIntervalSince1970: 0)

    policy.snooze(until: start.addingTimeInterval(30 * 60))
    XCTAssertEqual(
      policy.evaluate(snapshot(at: start.addingTimeInterval(30 * 60 - 1))),
      .none
    )
    XCTAssertEqual(
      policy.evaluate(snapshot(at: start.addingTimeInterval(30 * 60))),
      .showLargeCat
    )
  }

  func testExternalGearCancelsSnoozeAndStartsAFreshSession() {
    var configuration = MonitorPolicy.Configuration()
    configuration.postureWarningAfter = 10
    var policy = MonitorPolicy(configuration: configuration)
    let start = Date(timeIntervalSince1970: 0)

    policy.snooze(until: start.addingTimeInterval(30))
    XCTAssertEqual(
      policy.evaluate(
        snapshot(
          at: start.addingTimeInterval(5),
          externalDisplay: true,
          externalKeyboard: true
        )),
      .none
    )
    XCTAssertNil(policy.snoozedUntil)
    XCTAssertEqual(
      policy.evaluate(
        snapshot(
          at: start.addingTimeInterval(25),
          externalDisplay: true,
          externalKeyboard: true
        )),
      .none
    )
    XCTAssertEqual(policy.evaluate(snapshot(at: start.addingTimeInterval(30))), .none)
    XCTAssertEqual(
      policy.evaluate(snapshot(at: start.addingTimeInterval(35))),
      .showLargeCat
    )
  }

  func testIMacOnlyShowsBreakCat() {
    var configuration = MonitorPolicy.Configuration()
    configuration.iMacBreakRange = 10...10
    var policy = MonitorPolicy(configuration: configuration)
    let start = Date(timeIntervalSince1970: 0)

    XCTAssertEqual(policy.evaluate(snapshot(at: start, kind: .iMac)), .none)
    XCTAssertEqual(
      policy.evaluate(snapshot(at: start.addingTimeInterval(10), kind: .iMac)),
      .showBreakCat
    )
  }

  func testOtherDesktopMacNeverShowsAlert() {
    var configuration = MonitorPolicy.Configuration()
    configuration.postureWarningAfter = 5
    var policy = MonitorPolicy(configuration: configuration)
    let start = Date(timeIntervalSince1970: 0)

    XCTAssertEqual(policy.evaluate(snapshot(at: start, kind: .desktop)), .none)
    XCTAssertEqual(
      policy.evaluate(snapshot(at: start.addingTimeInterval(60), kind: .desktop)),
      .none
    )
  }

  private func snapshot(
    at date: Date,
    kind: MacKind = .portable,
    externalDisplay: Bool = false,
    externalKeyboard: Bool = false,
    idleSeconds: TimeInterval = 0
  ) -> MonitorSnapshot {
    MonitorSnapshot(
      now: date,
      macKind: kind,
      hasExternalDisplay: externalDisplay,
      isUsingExternalKeyboard: externalKeyboard,
      keyboardAccessStatus: .granted,
      idleSeconds: idleSeconds
    )
  }
}
