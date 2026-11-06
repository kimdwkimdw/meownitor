import XCTest

@testable import Meownitor

final class MacKindTests: XCTestCase {
  func testGenericIdentifiersUseHardwareInsteadOfTheModelPrefix() {
    XCTAssertEqual(kind("Mac17,3", battery: true, display: true), .portable)
    XCTAssertEqual(kind("Mac16,3", battery: false, display: true), .iMac)
    XCTAssertEqual(kind("Mac16,10", battery: false, display: false), .desktop)
    XCTAssertEqual(kind("Mac99,1", battery: true, display: true), .portable)
  }

  func testClamshellMacBookIsStillPortable() {
    XCTAssertEqual(kind("Mac17,3", battery: true, display: false), .portable)
  }

  func testLegacyModelNamesRemainAFallback() {
    XCTAssertEqual(kind("MacBookPro18,3", battery: false, display: false), .portable)
    XCTAssertEqual(kind("MacBookAir10,1", battery: false, display: false), .portable)
    XCTAssertEqual(kind("iMac21,1", battery: false, display: false), .iMac)
    XCTAssertEqual(kind("Macmini9,1", battery: false, display: false), .desktop)
    XCTAssertEqual(kind("Unknown", battery: false, display: false), .desktop)
  }

  private func kind(_ model: String, battery: Bool, display: Bool) -> MacKind {
    MacKind.detect(
      modelIdentifier: model, hasInternalBattery: battery, hasBuiltInDisplay: display
    )
  }
}
