import Foundation
import XCTest

@testable import Meownitor

final class MonitorStatusTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 0)

  func testPermissionIsOptionalAndDoesNotHideProgress() {
    XCTAssertEqual(title(), "MacBook 사용 12/25분")
    XCTAssertEqual(title(access: .denied), "MacBook 사용 12/25분 · 키보드 감지 꺼짐")
    XCTAssertEqual(
      title(access: .unknown, language: .english),
      "MacBook use: 12/25 min · Keyboard detection off"
    )
  }

  func testExternalGearExplainsWhyAlertsArePaused() {
    XCTAssertEqual(title(display: true), "외장 모니터 사용 중 · 알림 일시 정지")
    XCTAssertEqual(title(keyboard: true), "외장 키보드 사용 중 · 알림 일시 정지")
  }

  func testUnverifiedAndFailedDetectionAreNotReportedAsReady() {
    XCTAssertEqual(title(access: .waitingForInput), "MacBook 사용 12/25분 · 키보드 확인 대기")
    XCTAssertEqual(title(access: .unavailable), "MacBook 사용 12/25분 · 키보드 감지 오류")
  }

  func testIdleAndSnoozeAreVisible() {
    XCTAssertEqual(title(idle: 90), "입력 대기 · 누적 12/25분")
    XCTAssertEqual(title(until: now.addingTimeInterval(61)), "알림 미루기 · 2분 남음")
    XCTAssertEqual(title(until: now), "MacBook 사용 12/25분")
  }

  func testDesktopAndIMacKeepTheirSeparatePolicies() {
    XCTAssertEqual(title(kind: .desktop), "이 Mac에서는 자세 알림 사용 안 함")
    XCTAssertEqual(title(kind: .iMac), "iMac · 휴식 알림만 사용")
  }

  private func title(
    kind: MacKind = .portable, display: Bool = false, keyboard: Bool = false,
    access: KeyboardAccessStatus = .granted, idle: TimeInterval = 0,
    until: Date? = nil, language: AppLanguage = .korean
  ) -> String {
    AppDelegate.statusTitle(
      MonitorSnapshot(
        now: now, macKind: kind, hasExternalDisplay: display,
        isUsingExternalKeyboard: keyboard, keyboardAccessStatus: access, idleSeconds: idle
      ),
      activeSeconds: 12 * 60, snoozedUntil: until, language: language
    )
  }
}
