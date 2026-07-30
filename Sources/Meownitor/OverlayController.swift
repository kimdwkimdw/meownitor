import AppKit
import Carbon

enum EscapePressAction: Equatable {
  case ignore
  case showHint
  case dismiss
}

struct EscapeDismissalState {
  static let timeout: TimeInterval = 2
  static let debounce: TimeInterval = 0.25
  private(set) var firstPressUptime: TimeInterval?
  private var lastPressUptime: TimeInterval?

  mutating func press(at uptime: TimeInterval) -> EscapePressAction {
    if let lastPressUptime, uptime - lastPressUptime < Self.debounce {
      return .ignore
    }
    lastPressUptime = uptime
    if let firstPressUptime, uptime - firstPressUptime <= Self.timeout {
      self.firstPressUptime = nil
      return .dismiss
    }
    firstPressUptime = uptime
    return .showHint
  }

  mutating func reset() {
    firstPressUptime = nil
    lastPressUptime = nil
  }
}

private let escapeHotKeyHandler: EventHandlerUPP = { _, event, userData in
  guard let event, let userData else { return OSStatus(eventNotHandledErr) }
  let controller = Unmanaged<OverlayController>.fromOpaque(userData)
    .takeUnretainedValue()
  controller.handleEscapeEvent(kind: GetEventKind(event))
  return noErr
}

private final class OverlayPanel: NSPanel {
  override func cancelOperation(_ sender: Any?) {
    // Carbon handles ESC so AppKit must not close the panel on the first press.
  }
}

final class SpriteView: NSView {
  private let frames: [CGImage]
  private lazy var playback =
    Array(repeating: 0, count: 12)
    + frames.indices.dropFirst().flatMap { [$0, $0] }
  private var playbackIndex = 0
  private var displayedFrame = 0
  private var timer: Timer?
  var pixelSize: CGSize {
    CGSize(width: frames[0].width, height: frames[0].height)
  }

  init?(atlasURL: URL) {
    guard let image = NSImage(contentsOf: atlasURL),
      let atlas = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    else {
      return nil
    }

    frames = Self.frames(from: atlas)
    guard frames.count == 7 else { return nil }
    super.init(frame: .zero)
    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor
    layer?.contentsGravity = .resizeAspect
    layer?.magnificationFilter = .linear
    layer?.minificationFilter = .linear
    layer?.opacity = 1
    layer?.contents = frames[0]
  }

  static func frames(from atlas: CGImage) -> [CGImage] {
    guard atlas.height > 0, atlas.width % atlas.height == 0 else { return [] }
    let columns = atlas.width / atlas.height
    guard columns > 1 else { return [] }
    return (0..<columns).compactMap { index in
      atlas.cropping(
        to: CGRect(
          x: index * atlas.height,
          y: 0,
          width: atlas.height,
          height: atlas.height
        ))
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    if window == nil {
      timer?.invalidate()
      timer = nil
    } else if timer == nil {
      layer?.contentsScale = window?.backingScaleFactor ?? 1
      let timer = Timer(timeInterval: 1.0 / 12.0, repeats: true) { [weak self] _ in
        self?.advance()
      }
      RunLoop.main.add(timer, forMode: .common)
      self.timer = timer
    }
  }

  private func advance() {
    playbackIndex = (playbackIndex + 1) % playback.count
    let nextFrame = playback[playbackIndex]
    guard nextFrame != displayedFrame else { return }
    displayedFrame = nextFrame
    layer?.contents = frames[nextFrame]
  }
}

final class OverlayController {
  private var panel: NSPanel?
  private var snoozeHandler: ((TimeInterval) -> Void)?
  private var settingsHandler: (() -> Void)?
  private var escapeHotKey: EventHotKeyRef?
  private var escapeEventHandler: EventHandlerRef?
  private var escapeState = EscapeDismissalState()
  private var escapeKeyIsDown = false
  private weak var escapeMessageLabel: NSTextField?
  private var escapeOriginalMessage = ""
  private var escapeOriginalAlignment = NSTextAlignment.natural
  private var escapeHintMessage = ""
  private var escapeHintReset: DispatchWorkItem?

  func showLarge(
    message: String,
    language: AppLanguage,
    cat: CatProfile,
    onSnooze: @escaping (TimeInterval) -> Void
  ) {
    guard let screen = Self.targetScreen else { return }
    dismiss()
    snoozeHandler = onSnooze
    panel = makePanel(frame: screen.frame, level: .screenSaver)

    let content = NSView(frame: screen.frame)
    content.wantsLayer = true
    content.layer?.backgroundColor = NSColor.clear.cgColor

    let dimmer = NSView(frame: content.bounds)
    dimmer.wantsLayer = true
    dimmer.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.48).cgColor
    content.addSubview(dimmer)

    if let url = Self.randomSequenceURL(for: cat), let sprite = SpriteView(atlasURL: url) {
      let catHeight = min(
        screen.frame.height * 0.72,
        760,
        sprite.pixelSize.height / screen.backingScaleFactor
      )
      sprite.frame = CGRect(
        x: (screen.frame.width - catHeight) / 2,
        y: max(30, screen.frame.height * 0.06),
        width: catHeight,
        height: catHeight
      )
      content.addSubview(sprite)
    }

    let (messageCard, messageLabel) = largeMessageCard(
      message,
      maxWidth: min(760, screen.frame.width - 120)
    )
    messageCard.translatesAutoresizingMaskIntoConstraints = false
    content.addSubview(messageCard)
    NSLayoutConstraint.activate([
      messageCard.centerXAnchor.constraint(equalTo: content.centerXAnchor),
      messageCard.topAnchor.constraint(equalTo: content.topAnchor, constant: 64),
      messageCard.widthAnchor.constraint(greaterThanOrEqualToConstant: 320),
      messageCard.widthAnchor.constraint(
        lessThanOrEqualToConstant: min(760, screen.frame.width - 120)),
    ])

    let snoozeStack = NSStackView()
    snoozeStack.orientation = .horizontal
    snoozeStack.spacing = 12
    snoozeStack.alignment = .centerY
    for minutes in [30, 60, 120] {
      let title = Self.snoozeTitle(minutes: minutes, language: language)
      let button = NSButton(
        title: title,
        target: self,
        action: #selector(snooze(_:))
      )
      button.tag = minutes
      button.bezelStyle = .rounded
      button.controlSize = .large
      button.setAccessibilityLabel(title)
      snoozeStack.addArrangedSubview(button)
    }
    let stackWidth = min(
      screen.frame.width - 80,
      max(390, snoozeStack.fittingSize.width)
    )
    snoozeStack.frame = CGRect(
      x: (screen.frame.width - stackWidth) / 2,
      y: 28,
      width: stackWidth,
      height: 48
    )
    content.addSubview(snoozeStack)

    let close = closeButton(label: language.text("닫기", "Close"))
    close.setFrameOrigin(
      CGPoint(
        x: 20,
        y: content.bounds.height - close.frame.height - 20
      )
    )
    content.addSubview(close)
    panel?.contentView = content
    beginEscapeHandling(messageLabel: messageLabel, language: language)
    panel?.orderFrontRegardless()
  }

  func showPermissionNotice(
    message: String,
    settingsTitle: String,
    language: AppLanguage,
    cat: CatProfile,
    onOpenSettings: @escaping () -> Void
  ) {
    guard let screen = Self.targetScreen else { return }
    dismiss()
    settingsHandler = onOpenSettings

    let size = CGSize(width: 430, height: 250)
    let frame = CGRect(
      x: screen.visibleFrame.maxX - size.width - 24,
      y: screen.visibleFrame.minY + 24,
      width: size.width,
      height: size.height
    )
    panel = makePanel(frame: frame, level: .floating)
    let content = NSView(frame: CGRect(origin: .zero, size: size))
    content.wantsLayer = true
    content.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    content.layer?.cornerRadius = 18

    if let url = Self.idleSequenceURL(for: cat), let sprite = SpriteView(atlasURL: url) {
      sprite.frame = CGRect(x: 16, y: 70, width: 142, height: 142)
      content.addSubview(sprite)
    }

    let title = NSTextField(labelWithString: Self.permissionTitle(language: language))
    title.font = .systemFont(ofSize: 17, weight: .semibold)
    title.frame = CGRect(x: 168, y: 191, width: 238, height: 24)
    content.addSubview(title)

    let body = NSTextField(wrappingLabelWithString: message)
    body.font = .systemFont(ofSize: 13)
    body.textColor = .secondaryLabelColor
    body.frame = CGRect(x: 168, y: 82, width: 238, height: 104)
    content.addSubview(body)

    let settings = NSButton(
      title: settingsTitle,
      target: self,
      action: #selector(openSettings)
    )
    settings.bezelStyle = .rounded
    settings.frame = CGRect(x: 168, y: 36, width: 154, height: 32)
    content.addSubview(settings)

    let close = closeButton(label: language.text("닫기", "Close"))
    close.setFrameOrigin(
      CGPoint(
        x: 16,
        y: content.bounds.height - close.frame.height - 16
      )
    )
    content.addSubview(close)
    panel?.contentView = content
    beginEscapeHandling(messageLabel: body, language: language)
    panel?.orderFrontRegardless()
  }

  func showSmall(message: String, language: AppLanguage, cat: CatProfile) {
    guard let screen = Self.targetScreen else { return }
    dismiss()

    let size = CGSize(width: 300, height: 210)
    let frame = CGRect(
      x: screen.visibleFrame.maxX - size.width - 24,
      y: screen.visibleFrame.minY + 24,
      width: size.width,
      height: size.height
    )
    panel = makePanel(frame: frame, level: .floating)
    let content = NSView(frame: CGRect(origin: .zero, size: size))
    content.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(dismiss)))

    if let url = Self.idleSequenceURL(for: cat), let sprite = SpriteView(atlasURL: url) {
      sprite.frame = CGRect(x: 78, y: 48, width: 143, height: 143)
      content.addSubview(sprite)
    }

    let label = messageLabel(message, fontSize: 16)
    label.frame = CGRect(x: 12, y: 8, width: 276, height: 36)
    content.addSubview(label)
    let close = closeButton(label: language.text("닫기", "Close"))
    close.setFrameOrigin(
      CGPoint(
        x: 16,
        y: content.bounds.height - close.frame.height - 16
      )
    )
    content.addSubview(close)
    panel?.contentView = content
    beginEscapeHandling(messageLabel: label, language: language)
    panel?.orderFrontRegardless()
  }

  @objc func dismiss() {
    endEscapeHandling()
    panel?.close()
    panel = nil
    snoozeHandler = nil
    settingsHandler = nil
  }

  fileprivate func handleEscapeEvent(kind: UInt32) {
    if kind == UInt32(kEventHotKeyReleased) {
      escapeKeyIsDown = false
      return
    }
    guard kind == UInt32(kEventHotKeyPressed), !escapeKeyIsDown, panel != nil else {
      return
    }
    escapeKeyIsDown = true
    switch escapeState.press(at: ProcessInfo.processInfo.systemUptime) {
    case .ignore:
      break
    case .showHint:
      showEscapeHint()
    case .dismiss:
      dismiss()
    }
  }

  @objc private func snooze(_ sender: NSButton) {
    let handler = snoozeHandler
    dismiss()
    handler?(TimeInterval(sender.tag * 60))
  }

  @objc private func openSettings() {
    let handler = settingsHandler
    dismiss()
    handler?()
  }

  private func makePanel(frame: CGRect, level: NSWindow.Level) -> NSPanel {
    let panel = OverlayPanel(
      contentRect: frame,
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    panel.level = level
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.colorSpace = .sRGB
    panel.hasShadow = false
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    panel.isReleasedWhenClosed = false
    return panel
  }

  private func beginEscapeHandling(
    messageLabel: NSTextField,
    language: AppLanguage
  ) {
    escapeMessageLabel = messageLabel
    escapeOriginalMessage = messageLabel.stringValue
    escapeOriginalAlignment = messageLabel.alignment
    escapeHintMessage = language.text(
      "ESC를 한 번 더 누르면 닫혀요",
      "Press ESC again to close"
    )

    var eventTypes = [
      EventTypeSpec(
        eventClass: OSType(kEventClassKeyboard),
        eventKind: UInt32(kEventHotKeyPressed)
      ),
      EventTypeSpec(
        eventClass: OSType(kEventClassKeyboard),
        eventKind: UInt32(kEventHotKeyReleased)
      ),
    ]
    let handlerStatus = eventTypes.withUnsafeMutableBufferPointer { events in
      InstallEventHandler(
        GetApplicationEventTarget(),
        escapeHotKeyHandler,
        events.count,
        events.baseAddress,
        Unmanaged.passUnretained(self).toOpaque(),
        &escapeEventHandler
      )
    }
    guard handlerStatus == noErr else { return }

    let hotKeyID = EventHotKeyID(signature: 0x4D45_4F57, id: 1)
    var status = RegisterEventHotKey(
      UInt32(kVK_Escape),
      0,
      hotKeyID,
      GetApplicationEventTarget(),
      OptionBits(kEventHotKeyExclusive),
      &escapeHotKey
    )
    if status != noErr {
      status = RegisterEventHotKey(
        UInt32(kVK_Escape),
        0,
        hotKeyID,
        GetApplicationEventTarget(),
        OptionBits(kEventHotKeyNoOptions),
        &escapeHotKey
      )
    }
    if status != noErr, let escapeEventHandler {
      RemoveEventHandler(escapeEventHandler)
      self.escapeEventHandler = nil
    }
  }

  private func showEscapeHint() {
    escapeMessageLabel?.stringValue = escapeHintMessage
    escapeMessageLabel?.alignment = .center
    escapeHintReset?.cancel()
    let reset = DispatchWorkItem { [weak self] in
      self?.escapeState.reset()
      self?.restoreEscapeMessage()
    }
    escapeHintReset = reset
    DispatchQueue.main.asyncAfter(
      deadline: .now() + EscapeDismissalState.timeout,
      execute: reset
    )
  }

  private func endEscapeHandling() {
    escapeHintReset?.cancel()
    escapeHintReset = nil
    restoreEscapeMessage()
    escapeMessageLabel = nil
    escapeOriginalMessage = ""
    escapeHintMessage = ""
    escapeState.reset()
    escapeKeyIsDown = false
    if let escapeHotKey {
      UnregisterEventHotKey(escapeHotKey)
      self.escapeHotKey = nil
    }
    if let escapeEventHandler {
      RemoveEventHandler(escapeEventHandler)
      self.escapeEventHandler = nil
    }
  }

  private func restoreEscapeMessage() {
    escapeMessageLabel?.stringValue = escapeOriginalMessage
    escapeMessageLabel?.alignment = escapeOriginalAlignment
  }

  private func messageLabel(_ text: String, fontSize: CGFloat) -> NSTextField {
    let label = NSTextField(labelWithString: text)
    label.alignment = .center
    label.font = .systemFont(ofSize: fontSize, weight: .bold)
    label.textColor = .white
    label.maximumNumberOfLines = 2
    label.lineBreakMode = .byWordWrapping
    label.wantsLayer = true
    label.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.72).cgColor
    label.layer?.cornerRadius = 18
    return label
  }

  private func largeMessageCard(
    _ text: String,
    maxWidth: CGFloat
  ) -> (NSView, NSTextField) {
    let card = NSView()
    card.wantsLayer = true
    card.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.72).cgColor
    card.layer?.cornerRadius = 18

    let label = NSTextField(wrappingLabelWithString: text)
    label.alignment = .center
    label.font = .systemFont(ofSize: 34, weight: .bold)
    label.textColor = .white
    label.maximumNumberOfLines = 2
    label.lineBreakMode = .byWordWrapping
    label.preferredMaxLayoutWidth = maxWidth - 56
    label.translatesAutoresizingMaskIntoConstraints = false
    card.addSubview(label)

    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 28),
      label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -28),
      label.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
      label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
    ])
    return (card, label)
  }

  private func closeButton(label: String) -> NSButton {
    let button = NSWindow.standardWindowButton(
      .closeButton,
      for: [.borderless, .nonactivatingPanel]
    )!
    button.target = self
    button.action = #selector(dismiss)
    button.toolTip = label
    button.setAccessibilityLabel(label)
    return button
  }

  private static func randomSequenceURL(for cat: CatProfile) -> URL? {
    sequenceURLs(for: cat).randomElement()
  }

  private static var targetScreen: NSScreen? {
    let screens = NSScreen.screens
    let builtIn = screens.map { screen in
      guard
        let number = screen.deviceDescription[
          NSDeviceDescriptionKey("NSScreenNumber")
        ] as? NSNumber
      else {
        return false
      }
      return CGDisplayIsBuiltin(CGDirectDisplayID(number.uint32Value)) != 0
    }
    guard let index = targetScreenIndex(for: builtIn) else { return nil }
    return screens[index]
  }

  static func targetScreenIndex(for builtIn: [Bool]) -> Int? {
    builtIn.firstIndex(of: true)
  }

  private static func idleSequenceURL(for cat: CatProfile) -> URL? {
    sequenceURLs(for: cat).first { $0.lastPathComponent.hasPrefix("00-idle") }
  }

  static func sequenceURLs(for cat: CatProfile) -> [URL] {
    let installed = CatPackStore.shared.sequenceURLs(for: cat)
    if !installed.isEmpty {
      return installed
    }

    let bundled =
      Bundle.main.urls(
        forResourcesWithExtension: cat.assetExtension,
        subdirectory: cat.assetSubdirectory
      ) ?? []
    if !bundled.isEmpty {
      return bundled.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    let localDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      .appendingPathComponent(cat.localAssetDirectory)
    let local =
      (try? FileManager.default.contentsOfDirectory(
        at: localDirectory,
        includingPropertiesForKeys: nil
      )) ?? []
    return local.filter { $0.pathExtension == cat.assetExtension }
      .sorted { $0.lastPathComponent < $1.lastPathComponent }
  }

  private static func permissionTitle(language: AppLanguage) -> String {
    language.text("키보드 감지", "Keyboard Detection")
  }

  private static func snoozeTitle(minutes: Int, language: AppLanguage) -> String {
    if minutes == 60 {
      return language.text("1시간 미루기", "Snooze for 1 hour")
    }
    if minutes == 120 {
      return language.text("2시간 미루기", "Snooze for 2 hours")
    }
    return language.text("30분 미루기", "Snooze for 30 min")
  }
}
