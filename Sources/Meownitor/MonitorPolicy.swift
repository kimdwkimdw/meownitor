import Foundation

enum MacKind {
  case portable
  case iMac
  case desktop
}

enum KeyboardAccessStatus {
  case granted
  case denied
  case unknown
}

struct MonitorSnapshot {
  let now: Date
  let macKind: MacKind
  let hasExternalDisplay: Bool
  let isUsingExternalKeyboard: Bool
  let keyboardAccessStatus: KeyboardAccessStatus
  let idleSeconds: TimeInterval
}

enum MonitorAction: Equatable {
  case none
  case showLargeCat
  case showBreakCat
}

struct MonitorPolicy {
  struct Configuration {
    var postureWarningAfter: TimeInterval = 25 * 60
    var activeIdleLimit: TimeInterval = 60
    var sessionResetAfter: TimeInterval = 5 * 60
    var iMacBreakRange: ClosedRange<TimeInterval> = (30 * 60)...(60 * 60)
  }

  private(set) var activeSeconds: TimeInterval = 0
  private(set) var snoozedUntil: Date?
  private var lastTick: Date?
  private var nextIMacBreak: Date?
  private let configuration: Configuration

  init(configuration: Configuration = .init()) {
    self.configuration = configuration
  }

  mutating func snooze(until date: Date) {
    snoozedUntil = date
    activeSeconds = 0
  }

  mutating func evaluate(_ snapshot: MonitorSnapshot) -> MonitorAction {
    defer { lastTick = snapshot.now }

    switch snapshot.macKind {
    case .iMac:
      activeSeconds = 0
      snoozedUntil = nil
      if nextIMacBreak == nil {
        scheduleNextBreak(after: snapshot.now)
      }
      guard let nextIMacBreak, snapshot.now >= nextIMacBreak else {
        return .none
      }
      scheduleNextBreak(after: snapshot.now)
      return .showBreakCat

    case .desktop:
      activeSeconds = 0
      snoozedUntil = nil
      return .none

    case .portable:
      nextIMacBreak = nil
    }

    guard !snapshot.hasExternalDisplay, !snapshot.isUsingExternalKeyboard else {
      activeSeconds = 0
      snoozedUntil = nil
      return .none
    }

    if snapshot.idleSeconds >= configuration.sessionResetAfter {
      activeSeconds = 0
      snoozedUntil = nil
      return .none
    }

    if let snoozedUntil {
      guard snapshot.now >= snoozedUntil else {
        activeSeconds = 0
        return .none
      }
      self.snoozedUntil = nil
      activeSeconds = configuration.postureWarningAfter
    }

    guard snapshot.idleSeconds <= configuration.activeIdleLimit else {
      return .none
    }

    let elapsed = min(max(snapshot.now.timeIntervalSince(lastTick ?? snapshot.now), 0), 15)
    activeSeconds += elapsed
    guard activeSeconds >= configuration.postureWarningAfter else {
      return .none
    }

    activeSeconds = 0
    return .showLargeCat
  }

  private mutating func scheduleNextBreak(after date: Date) {
    nextIMacBreak = date.addingTimeInterval(
      .random(in: configuration.iMacBreakRange)
    )
  }
}
