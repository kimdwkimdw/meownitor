import Foundation

enum AppLanguage: String, CaseIterable {
  static let defaultsKey = "appLanguage"

  case system
  case korean
  case english

  static var selected: AppLanguage {
    get {
      AppLanguage(
        rawValue: UserDefaults.standard.string(forKey: defaultsKey) ?? ""
      ) ?? .system
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
    }
  }

  var isKorean: Bool {
    isKorean(preferredLanguages: Locale.preferredLanguages)
  }

  func isKorean(preferredLanguages: [String]) -> Bool {
    switch self {
    case .system:
      return preferredLanguages.first?.hasPrefix("ko") == true
    case .korean:
      return true
    case .english:
      return false
    }
  }

  func text(_ korean: String, _ english: String) -> String {
    isKorean ? korean : english
  }

  func pickerTitle(in interfaceLanguage: AppLanguage) -> String {
    switch self {
    case .system:
      return interfaceLanguage.text("시스템 설정", "System Default")
    case .korean:
      return "한국어"
    case .english:
      return interfaceLanguage.text("영어", "English")
    }
  }
}

extension KeyboardAccessStatus {
  func title(language: AppLanguage) -> String {
    switch self {
    case .granted:
      return language.text("✓ 키보드 입력이 확인되었습니다", "✓ Keyboard input verified")
    case .waitingForInput:
      return language.text(
        "권한 허용됨 · 키보드에서 키를 눌러 확인하세요", "Permission allowed · Press a key to verify")
    case .unavailable:
      return language.text(
        "권한 허용됨 · 키보드 감지 시작 실패 · 앱을 다시 열어주세요",
        "Permission allowed · Detection failed to start · Reopen the app")
    case .denied:
      return language.text(
        "입력 모니터링 꺼짐 · 키보드 감지 불가", "Input Monitoring off · Keyboard detection unavailable")
    case .unknown:
      return language.text(
        "입력 모니터링 미설정 · 권한을 요청하세요", "Input Monitoring not set up · Request permission")
    }
  }
}
