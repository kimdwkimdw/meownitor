import AppKit
import CoreGraphics
import Foundation
import IOKit.hid

final class ExternalKeyboardMonitor {
  private let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
  private var lastEvent: (date: Date, external: Bool)?
  private var isOpen = false
  private(set) var accessStatus: KeyboardAccessStatus

  init() {
    accessStatus = Self.currentAccessStatus

    let matching: [String: Any] = [
      kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
      kIOHIDDeviceUsageKey: kHIDUsage_GD_Keyboard,
    ]
    IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
    IOHIDManagerRegisterInputValueCallback(
      manager,
      { context, _, _, value in
        guard let context else { return }
        Unmanaged<ExternalKeyboardMonitor>
          .fromOpaque(context)
          .takeUnretainedValue()
          .record(value)
      },
      Unmanaged.passUnretained(self).toOpaque()
    )
    IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
    refreshAccess()
  }

  deinit {
    IOHIDManagerUnscheduleFromRunLoop(
      manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
    if isOpen {
      IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }
  }

  var isUsingExternalKeyboard: Bool {
    guard let lastEvent, Date().timeIntervalSince(lastEvent.date) < 10 * 60 else {
      return false
    }
    return lastEvent.external
  }

  func refreshAccess() {
    accessStatus = Self.currentAccessStatus
    if accessStatus == .granted, !isOpen {
      isOpen =
        IOHIDManagerOpen(
          manager,
          IOOptionBits(kIOHIDOptionsTypeNone)
        ) == kIOReturnSuccess
    } else if accessStatus != .granted, isOpen {
      IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
      isOpen = false
    }
  }

  private func record(_ value: IOHIDValue) {
    let element = IOHIDValueGetElement(value)
    guard IOHIDElementGetUsagePage(element) == kHIDPage_KeyboardOrKeypad,
      IOHIDValueGetIntegerValue(value) != 0
    else {
      return
    }
    let device = IOHIDElementGetDevice(element)
    lastEvent = (Date(), !Self.isBuiltIn(device))
  }

  private static func isBuiltIn(_ device: IOHIDDevice) -> Bool {
    if let builtIn = IOHIDDeviceGetProperty(
      device,
      kIOHIDBuiltInKey as CFString
    ) as? Bool, builtIn {
      return true
    }

    let transport = property(kIOHIDTransportKey, from: device).lowercased()
    let product = property(kIOHIDProductKey, from: device).lowercased()
    return transport == "spi" || product.contains("internal keyboard")
  }

  private static func property(_ key: String, from device: IOHIDDevice) -> String {
    IOHIDDeviceGetProperty(device, key as CFString) as? String ?? ""
  }

  static var currentAccessStatus: KeyboardAccessStatus {
    switch IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) {
    case kIOHIDAccessTypeGranted:
      return .granted
    case kIOHIDAccessTypeDenied:
      return .denied
    default:
      return .unknown
    }
  }

  static func requestAccess() {
    _ = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
  }
}

struct SystemSnapshotProvider {
  let keyboardMonitor: ExternalKeyboardMonitor

  func snapshot(now: Date = Date()) -> MonitorSnapshot {
    keyboardMonitor.refreshAccess()
    return MonitorSnapshot(
      now: now,
      macKind: Self.macKind,
      hasExternalDisplay: Self.hasExternalDisplay,
      isUsingExternalKeyboard: keyboardMonitor.isUsingExternalKeyboard,
      keyboardAccessStatus: keyboardMonitor.accessStatus,
      idleSeconds: Self.idleSeconds
    )
  }

  static var modelIdentifier: String {
    var size = 0
    guard sysctlbyname("hw.model", nil, &size, nil, 0) == 0 else {
      return "Unknown"
    }
    var bytes = [CChar](repeating: 0, count: size)
    guard sysctlbyname("hw.model", &bytes, &size, nil, 0) == 0 else {
      return "Unknown"
    }
    return String(cString: bytes)
  }

  static var macKind: MacKind {
    let model = modelIdentifier
    if model.hasPrefix("MacBook") { return .portable }
    if model.hasPrefix("iMac") { return .iMac }
    return .desktop
  }

  static var hasExternalDisplay: Bool {
    var count: UInt32 = 0
    guard CGGetOnlineDisplayList(0, nil, &count) == .success, count > 0 else {
      return false
    }
    var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
    guard CGGetOnlineDisplayList(count, &displays, &count) == .success else {
      return false
    }
    return displays.prefix(Int(count)).contains { CGDisplayIsBuiltin($0) == 0 }
  }

  static var idleSeconds: TimeInterval {
    let eventTypes: [CGEventType] = [
      .keyDown, .mouseMoved, .leftMouseDown, .rightMouseDown,
      .otherMouseDown, .scrollWheel,
    ]
    return eventTypes.map {
      CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0)
    }.min() ?? .infinity
  }
}

final class MonitoringEngine {
  private let provider: SystemSnapshotProvider
  private let onAction: (MonitorAction) -> Void
  private let onStatus: (MonitorSnapshot, TimeInterval) -> Void
  private var policy = MonitorPolicy()
  private var timer: Timer?

  init(
    provider: SystemSnapshotProvider,
    onAction: @escaping (MonitorAction) -> Void,
    onStatus: @escaping (MonitorSnapshot, TimeInterval) -> Void
  ) {
    self.provider = provider
    self.onAction = onAction
    self.onStatus = onStatus
  }

  func start() {
    tick()
    let timer = Timer(timeInterval: 5, repeats: true) { [weak self] _ in
      self?.tick()
    }
    timer.tolerance = 1
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  func snooze(until date: Date) {
    policy.snooze(until: date)
  }

  private func tick() {
    let snapshot = provider.snapshot()
    let action = policy.evaluate(snapshot)
    onStatus(snapshot, policy.activeSeconds)
    if action != .none {
      onAction(action)
    }
  }
}
