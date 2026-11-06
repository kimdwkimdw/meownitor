import Foundation
import IOKit.hid
import XCTest

@testable import Meownitor

final class ExternalKeyboardMonitorTests: XCTestCase {
  func testBothNativePermissionChecksMustAllowListening() {
    XCTAssertEqual(
      ExternalKeyboardMonitor.permissionStatus(hidAccess: kIOHIDAccessTypeGranted, canListen: true),
      .granted
    )
    XCTAssertEqual(
      ExternalKeyboardMonitor.permissionStatus(
        hidAccess: kIOHIDAccessTypeGranted, canListen: false),
      .denied
    )
    XCTAssertEqual(
      ExternalKeyboardMonitor.permissionStatus(hidAccess: kIOHIDAccessTypeDenied, canListen: true),
      .denied
    )
    XCTAssertEqual(
      ExternalKeyboardMonitor.permissionStatus(hidAccess: kIOHIDAccessTypeUnknown, canListen: true),
      .unknown
    )
  }

  func testMissingPermissionNeverOpensManagerOrClaimsSuccess() {
    for permission in [KeyboardAccessStatus.unknown, .denied] {
      let io = KeyboardIO(permission: permission)
      let monitor = io.monitor()
      monitor.recordKeyDown(isExternal: true)
      XCTAssertEqual(monitor.accessStatus, permission)
      XCTAssertEqual(io.openCount, 0)
      XCTAssertFalse(monitor.isUsingExternalKeyboard)
    }
  }

  func testOpenFailureIsNotReportedAsPermissionSuccess() {
    let io = KeyboardIO(permission: .granted)
    io.openResult = kIOReturnNotPermitted
    let monitor = io.monitor()
    monitor.recordKeyDown(isExternal: true)
    XCTAssertEqual(monitor.accessStatus, .unavailable)
    XCTAssertEqual(io.closeCount, 1)
    XCTAssertFalse(monitor.isUsingExternalKeyboard)
  }

  func testAllowedPermissionStillNeedsAnActualKeyDown() {
    let io = KeyboardIO(permission: .granted)
    let monitor = io.monitor()
    XCTAssertEqual(monitor.accessStatus, .waitingForInput)
    monitor.refreshAccess()
    XCTAssertEqual(monitor.accessStatus, .waitingForInput)
    XCTAssertEqual(io.openCount, 1)
    monitor.recordKeyDown(isExternal: true)
    XCTAssertEqual(monitor.accessStatus, .granted)
    XCTAssertTrue(monitor.isUsingExternalKeyboard)
    monitor.recordKeyDown(isExternal: false)
    XCTAssertFalse(monitor.isUsingExternalKeyboard)
  }

  func testRevocationClearsExternalKeyboardAndRequiresVerificationAgain() {
    let io = KeyboardIO(permission: .granted)
    let monitor = io.monitor()
    monitor.recordKeyDown(isExternal: true)
    XCTAssertTrue(monitor.isUsingExternalKeyboard)
    io.permission = .denied
    monitor.refreshAccess()
    XCTAssertEqual(monitor.accessStatus, .denied)
    XCTAssertFalse(monitor.isUsingExternalKeyboard)
    XCTAssertEqual(io.closeCount, 1)
    monitor.recordKeyDown(isExternal: true)
    XCTAssertEqual(monitor.accessStatus, .denied)
    io.permission = .granted
    monitor.refreshAccess()
    XCTAssertEqual(monitor.accessStatus, .waitingForInput)
    XCTAssertFalse(monitor.isUsingExternalKeyboard)
    XCTAssertEqual(io.openCount, 2)
  }

  func testExpiredExternalKeyDownDoesNotPauseAlerts() {
    let io = KeyboardIO(permission: .granted)
    let monitor = io.monitor()
    monitor.recordKeyDown(isExternal: true, at: Date().addingTimeInterval(-10 * 60))
    XCTAssertFalse(monitor.isUsingExternalKeyboard)
  }
}

private final class KeyboardIO {
  var permission: KeyboardAccessStatus
  var openResult = kIOReturnSuccess
  var openCount = 0
  var closeCount = 0

  init(permission: KeyboardAccessStatus) {
    self.permission = permission
  }

  func monitor() -> ExternalKeyboardMonitor {
    ExternalKeyboardMonitor(
      checkAccess: { self.permission },
      openManager: { _ in
        self.openCount += 1
        return self.openResult
      },
      closeManager: { _ in
        self.closeCount += 1
        return kIOReturnSuccess
      }
    )
  }
}
