import Foundation
import XCTest

@testable import Meownitor

final class PermissionNoticeTests: XCTestCase {
  func testOnlyDontShowAgainPersistsAcrossInstances() {
    let suite = "MeownitorTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }

    let overlay = OverlayController(defaults: defaults)
    XCTAssertTrue(overlay.shouldShowPermissionNotice)
    overlay.dismiss()
    XCTAssertTrue(OverlayController(defaults: defaults).shouldShowPermissionNotice)

    overlay.hidePermissionNotice()
    XCTAssertFalse(overlay.shouldShowPermissionNotice)
    XCTAssertFalse(
      OverlayController(defaults: UserDefaults(suiteName: suite)!).shouldShowPermissionNotice
    )
  }
}
