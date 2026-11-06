import AppKit
import XCTest

@testable import Meownitor

final class InputMonitoringSetupTests: XCTestCase {
  func testOnlyMissingPermissionRequiresPermissionOnboarding() {
    XCTAssertTrue(KeyboardAccessStatus.unknown.needsPermission)
    XCTAssertTrue(KeyboardAccessStatus.denied.needsPermission)
    XCTAssertFalse(KeyboardAccessStatus.waitingForInput.needsPermission)
    XCTAssertFalse(KeyboardAccessStatus.unavailable.needsPermission)
    XCTAssertFalse(KeyboardAccessStatus.granted.needsPermission)
  }

  func testOnlyVerifiedInputHasASuccessTitle() {
    for language in [AppLanguage.korean, .english] {
      XCTAssertTrue(KeyboardAccessStatus.granted.title(language: language).hasPrefix("✓"))
      for status in [KeyboardAccessStatus.unknown, .denied, .waitingForInput, .unavailable] {
        XCTAssertFalse(status.title(language: language).contains("✓"))
      }
    }
  }

  func testDragExportsAppFileURLRatherThanIconImage() throws {
    let appURL = URL(fileURLWithPath: "/Applications/목펴라냥 Test.app", isDirectory: true)
    let icon = AppDragIcon(appURL: appURL, language: .korean)
    icon.frame = CGRect(x: 0, y: 0, width: 64, height: 64)
    let item = icon.draggingItem()
    let writer = try XCTUnwrap(item.item as? NSPasteboardWriting)
    let pasteboard = NSPasteboard.withUniqueName()
    defer { pasteboard.releaseGlobally() }

    XCTAssertTrue(pasteboard.writeObjects([writer]))
    let exportedURL = try XCTUnwrap(pasteboard.string(forType: .fileURL))
    XCTAssertEqual(URL(string: exportedURL)?.standardizedFileURL, appURL.standardizedFileURL)
    XCTAssertEqual(item.draggingFrame, icon.bounds)
    XCTAssertTrue(icon.acceptsFirstMouse(for: nil))
  }
}
