import XCTest

@testable import Meownitor

final class AppLanguageTests: XCTestCase {
  func testExplicitAndSystemLanguageResolution() {
    XCTAssertTrue(AppLanguage.korean.isKorean(preferredLanguages: ["en-US"]))
    XCTAssertFalse(AppLanguage.english.isKorean(preferredLanguages: ["ko-KR"]))
    XCTAssertTrue(AppLanguage.system.isKorean(preferredLanguages: ["ko-KR"]))
    XCTAssertFalse(AppLanguage.system.isKorean(preferredLanguages: ["en-US"]))
  }
}
