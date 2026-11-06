import AppKit
import CoreGraphics
import Foundation
import IOKit.hid
import IOKit.ps

final class ExternalKeyboardMonitor {
  private let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
  private var lastEvent: (date: Date, external: Bool)?
  private var isOpen = false
  private let checkAccess: () -> KeyboardAccessStatus
  private let openManager: (IOHIDManager) -> IOReturn
  private let closeManager: (IOHIDManager) -> IOReturn
  private(set) var accessStatus: KeyboardAccessStatus

  init(
    checkAccess: @escaping () -> KeyboardAccessStatus = {
      ExternalKeyboardMonitor.currentAccessStatus
    },
    openManager: @escaping (IOHIDManager) -> IOReturn = {
      IOHIDManagerOpen($0, IOOptionBits(kIOHIDOptionsTypeNone))
    },
    closeManager: @escaping (IOHIDManager) -> IOReturn = {
      IOHIDManagerClose($0, IOOptionBits(kIOHIDOptionsTypeNone))
    }
  ) {
    self.checkAccess = checkAccess
    self.openManager = openManager
    self.closeManager = closeManager
    accessStatus = .unknown

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
    IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
    refreshAccess()
  }

  deinit {
    IOHIDManagerUnscheduleFromRunLoop(
      manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
    if isOpen {
      _ = closeManager(manager)
    }
  }

  var isUsingExternalKeyboard: Bool {
    guard accessStatus == .granted, isOpen,
      let lastEvent, Date().timeIntervalSince(lastEvent.date) < 10 * 60
    else {
      return false
    }
    return lastEvent.external
  }

  func refreshAccess() {
    let permission = checkAccess()
    guard permission == .granted else {
      if isOpen { _ = closeManager(manager) }
      isOpen = false
      lastEvent = nil
      accessStatus = permission
      return
    }
    if !isOpen {
      isOpen = openManager(manager) == kIOReturnSuccess
      guard isOpen else {
        // A failed manager open can leave individual devices open.
        _ = closeManager(manager)
        lastEvent = nil
        accessStatus = .unavailable
        return
      }
    }
    accessStatus = lastEvent == nil ? .waitingForInput : .granted
  }

  func requestAccess() {
    _ = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
    refreshAccess()
  }

  func recordKeyDown(isExternal: Bool, at date: Date = Date()) {
    guard isOpen, checkAccess() == .granted else { return }
    lastEvent = (date, isExternal)
    accessStatus = .granted
  }

  private func record(_ value: IOHIDValue) {
    let element = IOHIDValueGetElement(value)
    guard IOHIDElementGetUsagePage(element) == kHIDPage_KeyboardOrKeypad,
      IOHIDValueGetIntegerValue(value) != 0
    else {
      return
    }
    let device = IOHIDElementGetDevice(element)
    recordKeyDown(isExternal: !Self.isBuiltIn(device))
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

  private static var currentAccessStatus: KeyboardAccessStatus {
    permissionStatus(
      hidAccess: IOHIDCheckAccess(kIOHIDRequestTypeListenEvent),
      canListen: CGPreflightListenEventAccess()
    )
  }

  static func permissionStatus(hidAccess: IOHIDAccessType, canListen: Bool) -> KeyboardAccessStatus
  {
    switch hidAccess {
    case kIOHIDAccessTypeGranted:
      return canListen ? .granted : .denied
    case kIOHIDAccessTypeDenied:
      return .denied
    default:
      return .unknown
    }
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
    MacKind.detect(
      modelIdentifier: modelIdentifier,
      hasInternalBattery: hasInternalBattery,
      hasBuiltInDisplay: onlineDisplays.contains { CGDisplayIsBuiltin($0) != 0 }
    )
  }

  static var hasInternalBattery: Bool {
    guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
      let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
    else { return false }
    return sources.contains { source in
      let description =
        IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue()
        as? [String: Any]
      return description?[kIOPSTypeKey] as? String == kIOPSInternalBatteryType
    }
  }

  static var hasExternalDisplay: Bool {
    onlineDisplays.contains { CGDisplayIsBuiltin($0) == 0 }
  }

  private static var onlineDisplays: [CGDirectDisplayID] {
    var count: UInt32 = 0
    guard CGGetOnlineDisplayList(0, nil, &count) == .success, count > 0 else {
      return []
    }
    var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
    guard CGGetOnlineDisplayList(count, &displays, &count) == .success else {
      return []
    }
    return Array(displays.prefix(Int(count)))
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
  private let onStatus: (MonitorSnapshot, TimeInterval, Date?) -> Void
  private var policy = MonitorPolicy()
  private var timer: Timer?

  init(
    provider: SystemSnapshotProvider,
    onAction: @escaping (MonitorAction) -> Void,
    onStatus: @escaping (MonitorSnapshot, TimeInterval, Date?) -> Void
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
    onStatus(snapshot, policy.activeSeconds, policy.snoozedUntil)
    if action != .none {
      onAction(action)
    }
  }
}
