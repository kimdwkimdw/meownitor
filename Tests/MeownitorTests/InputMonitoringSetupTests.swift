import AppKit
import XCTest

@testable import Meownitor

final class InputMonitoringSetupTests: XCTestCase {
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
