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
