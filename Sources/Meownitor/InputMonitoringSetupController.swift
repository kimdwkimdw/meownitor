import AppKit

final class AppDragIcon: NSImageView, NSDraggingSource {
  let appURL: URL

  init(appURL: URL, language: AppLanguage) {
    self.appURL = appURL
    super.init(frame: .zero)
    image = NSWorkspace.shared.icon(forFile: appURL.path)
    imageScaling = .scaleProportionallyUpOrDown
    toolTip = language.text(
      "이 아이콘을 입력 모니터링 목록으로 드래그하세요", "Drag this icon into the Input Monitoring list")
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
  private let keyboardMonitor: ExternalKeyboardMonitor
  private let status = NSTextField(wrappingLabelWithString: "")
  private var refreshTimer: Timer?

  init(language: AppLanguage, keyboardMonitor: ExternalKeyboardMonitor) {
    self.language = language
    self.keyboardMonitor = keyboardMonitor
    let panel = NSPanel(
      contentRect: CGRect(x: 0, y: 0, width: 400, height: 540),
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

    let instructions = NSTextField(
      wrappingLabelWithString: language.text(
        "외장 키보드를 구분하기 위한 선택 권한입니다.\n\n1. ‘권한 요청’을 누르고 시스템 설정 > 개인정보 보호 및 보안 > 입력 모니터링에서 Meownitor를 켜세요.\n2. 목록에 없으면 아래 아이콘을 목록으로 드래그하거나 + 버튼으로 추가하세요.\n3. 필요하면 앱을 다시 연 뒤 키보드에서 키를 눌러 실제 감지를 확인하세요.",
        "Optional permission to distinguish external keyboards.\n\n1. Click Request Permission, then enable Meownitor in System Settings > Privacy & Security > Input Monitoring.\n2. If it is missing, drag the icon below into the list or add it with +.\n3. Reopen the app if needed, then press a key to verify detection."
      ))
    instructions.font = .systemFont(ofSize: 13)
    instructions.widthAnchor.constraint(equalToConstant: 360).isActive = true
    stack.addArrangedSubview(instructions)

    let icon = AppDragIcon(appURL: Bundle.main.bundleURL, language: language)
    icon.widthAnchor.constraint(equalToConstant: 64).isActive = true
    icon.heightAnchor.constraint(equalToConstant: 64).isActive = true
    stack.addArrangedSubview(icon)
    stack.addArrangedSubview(
      NSTextField(labelWithString: language.text("↑ 이 앱을 드래그하세요", "↑ Drag this app")))

    for (title, action) in [
      (language.text("권한 요청", "Request Permission"), #selector(requestPermission)),
      (
        language.text("입력 모니터링 설정 열기", "Open Input Monitoring Settings"),
        #selector(openSystemSettings)
      ),
      (language.text("Finder에서 앱 보기", "Show App in Finder"), #selector(revealApp)),
      (language.text("앱 다시 열기", "Reopen App"), #selector(reopenApp(_:))),
    ] {
      let button = NSButton(title: title, target: self, action: action)
      button.bezelStyle = .rounded
      stack.addArrangedSubview(button)
    }

    let appPath = NSTextField(wrappingLabelWithString: Bundle.main.bundleURL.path)
    appPath.font = .systemFont(ofSize: 11)
    appPath.textColor = .secondaryLabelColor
    appPath.widthAnchor.constraint(equalToConstant: 360).isActive = true
    stack.addArrangedSubview(appPath)

    let repair = NSTextField(
      wrappingLabelWithString: language.text(
        "이미 켜져 있는데 감지되지 않으면 먼저 앱을 다시 열어주세요. 업데이트 후에도 안 되면 기존 Meownitor 항목을 − 버튼으로 제거하고 위 앱을 다시 추가하세요. 권한 없이도 자세 알림은 사용할 수 있습니다.",
        "If enabled but not detected, reopen the app first. If an update left a stale entry, remove Meownitor with − and add this app again. Posture alerts also work without this permission."
      ))
    repair.font = .systemFont(ofSize: 12)
    repair.textColor = .secondaryLabelColor
    repair.widthAnchor.constraint(equalToConstant: 360).isActive = true
    stack.addArrangedSubview(repair)
    status.font = .systemFont(ofSize: 12, weight: .semibold)
    status.widthAnchor.constraint(equalToConstant: 360).isActive = true
    stack.addArrangedSubview(status)
    refreshStatus()
    panel.contentView?.layoutSubtreeIfNeeded()
    panel.setContentSize(CGSize(width: 400, height: stack.fittingSize.height + 40))
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  deinit {
    refreshTimer?.invalidate()
  }

  func show() {
    if let screen = window?.screen ?? NSScreen.main {
      window?.setFrameTopLeftPoint(
        CGPoint(
          x: screen.visibleFrame.minX + 20, y: screen.visibleFrame.maxY - 40
        ))
    }
    showWindow(nil)
    window?.orderFrontRegardless()
    refreshStatus()
    refreshTimer?.invalidate()
    let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
      self?.refreshStatus()
    }
    RunLoop.main.add(timer, forMode: .common)
    refreshTimer = timer
    openSystemSettings()
  }

  func windowWillClose(_ notification: Notification) {
    refreshTimer?.invalidate()
    refreshTimer = nil
  }

  private func refreshStatus() {
    keyboardMonitor.refreshAccess()
    let state = keyboardMonitor.accessStatus
    status.stringValue = state.title(language: language)
    status.textColor = state == .granted ? .systemGreen : .systemOrange
  }

  @objc private func requestPermission() {
    keyboardMonitor.requestAccess()
    refreshStatus()
    openSystemSettings()
  }

  @objc private func reopenApp(_ sender: NSButton) {
    guard sender.isEnabled else { return }
    sender.isEnabled = false
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.createsNewApplicationInstance = true
    configuration.arguments = ["--settings-preview"]
    NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration) {
      [weak self] _, error in
      DispatchQueue.main.async {
        if let error {
          sender.isEnabled = true
          let alert = NSAlert()
          alert.messageText =
            self?.language.text("앱을 다시 열 수 없습니다", "Couldn't reopen the app") ?? "Meownitor"
          alert.informativeText = error.localizedDescription
          alert.runModal()
        } else {
          NSApp.terminate(nil)
        }
      }
    }
  }

  @objc private func openSystemSettings() {
    let url = URL(
      string:
        "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ListenEvent"
    )!
    NSWorkspace.shared.open(url)
  }

  @objc private func revealApp() {
    NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
  }
}
