import AppKit

final class AppDragIcon: NSImageView, NSDraggingSource {
  let appURL: URL

  init(appURL: URL, language: AppLanguage) {
    self.appURL = appURL
    super.init(frame: .zero)
    image = NSWorkspace.shared.icon(forFile: appURL.path)
    imageScaling = .scaleProportionallyUpOrDown
    toolTip = language.text("이 아이콘을 입력 모니터링 목록으로 드래그하세요", "Drag this icon into the Input Monitoring list")
    setAccessibilityLabel(language.text("드래그할 Meownitor 앱", "Meownitor app to drag"))
    setAccessibilityHelp(toolTip)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
  override func mouseDown(with event: NSEvent) {}

  func draggingItem() -> NSDraggingItem {
    let item = NSDraggingItem(pasteboardWriter: appURL as NSURL)
    item.setDraggingFrame(bounds, contents: image)
    return item
  }

  override func mouseDragged(with event: NSEvent) {
    beginDraggingSession(with: [draggingItem()], event: event, source: self)
  }

  func draggingSession(
    _ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext
  ) -> NSDragOperation {
    .copy
  }
}

final class InputMonitoringSetupController: NSWindowController, NSWindowDelegate {
  private let language: AppLanguage
  private let status = NSTextField(wrappingLabelWithString: "")
  private var refreshTimer: Timer?

  init(language: AppLanguage) {
    self.language = language
    let panel = NSPanel(
      contentRect: CGRect(x: 0, y: 0, width: 360, height: 390),
      styleMask: [.titled, .closable, .utilityWindow],
      backing: .buffered, defer: false
    )
    panel.title = language.text("입력 모니터링 설정", "Set Up Input Monitoring")
    panel.level = .floating
    panel.hidesOnDeactivate = false
    panel.isReleasedWhenClosed = false
    super.init(window: panel)
    panel.delegate = self

    let stack = NSStackView()
    stack.orientation = .vertical
    stack.alignment = .centerX
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false
    panel.contentView?.addSubview(stack)
    if let content = panel.contentView {
      NSLayoutConstraint.activate([
        stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
        stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
        stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
      ])
    }

    let instructions = NSTextField(wrappingLabelWithString: language.text(
      "1. 아래 앱 아이콘을 시스템 설정의 입력 모니터링 목록으로 끌어다 놓으세요.\n2. Meownitor를 켜고, macOS가 요청하면 ‘종료 및 다시 열기’를 선택하세요.",
      "1. Drag the app icon below into the Input Monitoring list in System Settings.\n2. Turn on Meownitor, then choose Quit & Reopen if macOS asks."
    ))
    instructions.font = .systemFont(ofSize: 13)
    instructions.widthAnchor.constraint(equalToConstant: 320).isActive = true
    stack.addArrangedSubview(instructions)

    let icon = AppDragIcon(appURL: Bundle.main.bundleURL, language: language)
    icon.widthAnchor.constraint(equalToConstant: 64).isActive = true
    icon.heightAnchor.constraint(equalToConstant: 64).isActive = true
    stack.addArrangedSubview(icon)
    stack.addArrangedSubview(NSTextField(labelWithString: language.text("↑ 이 앱을 드래그하세요", "↑ Drag this app")))

    for (title, action) in [
      (language.text("입력 모니터링 설정 열기", "Open Input Monitoring Settings"), #selector(openSystemSettings)),
      (language.text("Finder에서 앱 보기", "Show App in Finder"), #selector(revealApp)),
    ] {
      let button = NSButton(title: title, target: self, action: action)
      button.bezelStyle = .rounded
      stack.addArrangedSubview(button)
    }

    let repair = NSTextField(wrappingLabelWithString: language.text(
      "이미 켜져 있는데 인식되지 않나요? 목록에서 기존 Meownitor를 − 버튼으로 제거한 뒤 위 아이콘을 다시 넣어주세요.",
      "Already enabled but not detected? Remove the old Meownitor entry with the − button, then drag this icon in again."
    ))
    repair.font = .systemFont(ofSize: 12)
    repair.textColor = .secondaryLabelColor
    repair.widthAnchor.constraint(equalToConstant: 320).isActive = true
    stack.addArrangedSubview(repair)
    status.font = .systemFont(ofSize: 12, weight: .semibold)
    status.widthAnchor.constraint(equalToConstant: 320).isActive = true
    stack.addArrangedSubview(status)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  deinit {
    refreshTimer?.invalidate()
  }

  func show() {
    if let screen = window?.screen ?? NSScreen.main {
      window?.setFrameTopLeftPoint(CGPoint(
        x: screen.visibleFrame.minX + 20, y: screen.visibleFrame.maxY - 40
      ))
    }
    showWindow(nil)
    window?.orderFrontRegardless()
    refreshStatus()
    refreshTimer?.invalidate()
    refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      self?.refreshStatus()
    }
    openSystemSettings()
  }

  func windowWillClose(_ notification: Notification) {
    refreshTimer?.invalidate()
    refreshTimer = nil
  }

  private func refreshStatus() {
    let granted = ExternalKeyboardMonitor.currentAccessStatus == .granted
    status.stringValue = granted
      ? language.text("✓ 입력 모니터링이 켜져 있습니다", "✓ Input Monitoring is on")
      : language.text("권한 적용 대기 중 · 필요하면 앱을 다시 열어주세요", "Waiting for permission · Reopen the app if needed")
    status.textColor = granted ? .systemGreen : .secondaryLabelColor
  }

  @objc private func openSystemSettings() {
    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
    NSWorkspace.shared.open(url)
  }

  @objc private func revealApp() {
    NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
  }
}
