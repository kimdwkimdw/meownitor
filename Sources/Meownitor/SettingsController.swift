import AppKit

final class SettingsController: NSWindowController, NSWindowDelegate {
  private let language: AppLanguage
  private let onPreview: () -> Void
  private let onOpenInputSettings: () -> Void
  private let onLanguageChanged: (AppLanguage) -> Void
  private let onCatChanged: (CatProfile) -> Void
  private let languagePicker = NSPopUpButton()
  private let catPicker = NSPopUpButton()
  private let previewButton = NSButton()
  private let packStatus = NSTextField(labelWithString: "")
  private let packButton = NSButton()
  private let packProgress = NSProgressIndicator()
  private let permissionStatus = NSTextField(labelWithString: "")

  init(
    language: AppLanguage,
    onPreview: @escaping () -> Void,
    onOpenInputSettings: @escaping () -> Void,
    onLanguageChanged: @escaping (AppLanguage) -> Void,
    onCatChanged: @escaping (CatProfile) -> Void
  ) {
    self.language = language
    self.onPreview = onPreview
    self.onOpenInputSettings = onOpenInputSettings
    self.onLanguageChanged = onLanguageChanged
    self.onCatChanged = onCatChanged

    let window = NSWindow(
      contentRect: CGRect(x: 0, y: 0, width: 570, height: 680),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    window.title = language.text("목펴라냥 설정", "Meownitor Settings")
    window.center()
    window.isReleasedWhenClosed = false
    super.init(window: window)
    window.delegate = self
    window.contentView = makeContent()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  func show() {
    refresh()
    showWindow(nil)
    NSApp.activate(ignoringOtherApps: true)
    window?.makeKeyAndOrderFront(nil)
    Task { @MainActor [weak self] in
      try? await CatPackStore.shared.refreshCatalog()
      self?.refreshPackControls()
    }
  }

  func windowDidBecomeKey(_ notification: Notification) {
    refresh()
  }

  private func makeContent() -> NSView {
    let content = NSView()
    let stack = NSStackView()
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = 14
    stack.translatesAutoresizingMaskIntoConstraints = false
    content.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 28),
      stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -28),
      stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 26),
    ])

    stack.addArrangedSubview(sectionTitle(language.text("언어", "Language")))
    languagePicker.addItems(
      withTitles: AppLanguage.allCases.map { $0.pickerTitle(in: language) }
    )
    languagePicker.selectItem(
      at: AppLanguage.allCases.firstIndex(of: language) ?? 0
    )
    languagePicker.target = self
    languagePicker.action = #selector(selectLanguage)
    languagePicker.widthAnchor.constraint(equalToConstant: 300).isActive = true
    stack.addArrangedSubview(languagePicker)
    stack.addArrangedSubview(separator())

    stack.addArrangedSubview(sectionTitle(language.text("고양이", "Cat")))
    stack.addArrangedSubview(
      bodyLabel(
        language.text(
          "엘사는 앱에 포함됩니다. 다른 고양이는 필요할 때만 내려받고 언제든 삭제할 수 있습니다.",
          "Elsa is included. Download other cats only when you want them, and remove them anytime."
        )
      )
    )
    catPicker.addItems(withTitles: CatProfile.all.map { $0.pickerTitle(in: language) })
    catPicker.selectItem(at: CatProfile.all.firstIndex(of: .selected) ?? 0)
    catPicker.target = self
    catPicker.action = #selector(selectCat)
    catPicker.widthAnchor.constraint(equalToConstant: 430).isActive = true
    stack.addArrangedSubview(catPicker)

    packStatus.font = .systemFont(ofSize: 12)
    packStatus.textColor = .secondaryLabelColor
    stack.addArrangedSubview(packStatus)

    let packControls = NSStackView()
    packControls.orientation = .horizontal
    packControls.spacing = 8
    packButton.target = self
    packButton.action = #selector(manageCatPack)
    packButton.bezelStyle = .rounded
    packControls.addArrangedSubview(packButton)
    packProgress.style = .spinning
    packProgress.controlSize = .small
    packProgress.isDisplayedWhenStopped = false
    packControls.addArrangedSubview(packProgress)
    stack.addArrangedSubview(packControls)

    previewButton.title = previewTitle()
    previewButton.target = self
    previewButton.action = #selector(previewCat)
    previewButton.bezelStyle = .rounded
    stack.addArrangedSubview(previewButton)
    stack.addArrangedSubview(separator())

    stack.addArrangedSubview(
      sectionTitle(language.text("키보드 감지", "Keyboard Detection"))
    )
    permissionStatus.font = .systemFont(ofSize: 13, weight: .semibold)
    stack.addArrangedSubview(permissionStatus)
    stack.addArrangedSubview(
      bodyLabel(
        language.text(
          "입력 모니터링을 허용하면 MacBook 내장 키보드와 외장 키보드 중 어떤 키보드를 사용하는지 구분해 불필요한 알림을 줄입니다.",
          "Input Monitoring lets Meownitor tell whether you’re using the MacBook keyboard or an external keyboard, preventing unnecessary alerts."
        )
      )
    )
    stack.addArrangedSubview(
      bodyLabel(
        language.text(
          "권한 없이도 사용할 수 있습니다. 이 경우 외장 모니터 연결 여부만 확인하며, 모니터가 연결되어 있으면 알림이 나타나지 않습니다.",
          "Meownitor also works without this permission. In that mode, it checks only for an external display and keeps alerts off while one is connected."
        )
      )
    )

    let permissionButton = NSButton(
      title: language.text(
        "입력 모니터링 설정 열기",
        "Open Input Monitoring Settings"
      ),
      target: self,
      action: #selector(openInputSettings)
    )
    permissionButton.bezelStyle = .rounded
    stack.addArrangedSubview(permissionButton)
    stack.addArrangedSubview(separator())

    stack.addArrangedSubview(
      sectionTitle(language.text("알림 미루기", "Snooze Alerts"))
    )
    stack.addArrangedSubview(
      bodyLabel(
        language.text(
          "고양이가 나타나면 알림을 30분, 1시간 또는 2시간 미룰 수 있습니다.",
          "When your cat appears, you can snooze alerts for 30 minutes, 1 hour, or 2 hours."
        )
      )
    )
    return content
  }

  private func refresh() {
    refreshPackControls()
    switch ExternalKeyboardMonitor.currentAccessStatus {
    case .granted:
      permissionStatus.stringValue =
        language.text(
          "✓ 입력 모니터링이 켜져 있습니다",
          "✓ Input Monitoring is on"
        )
      permissionStatus.textColor = .systemGreen
    case .denied:
      permissionStatus.stringValue =
        language.text(
          "입력 모니터링이 꺼져 있습니다",
          "Input Monitoring is off"
        )
      permissionStatus.textColor = .systemOrange
    case .unknown:
      permissionStatus.stringValue =
        language.text(
          "입력 모니터링이 아직 설정되지 않았습니다",
          "Input Monitoring isn’t set up yet"
        )
      permissionStatus.textColor = .systemOrange
    }
  }

  private func sectionTitle(_ text: String) -> NSTextField {
    let label = NSTextField(labelWithString: text)
    label.font = .systemFont(ofSize: 17, weight: .semibold)
    return label
  }

  private func bodyLabel(_ text: String) -> NSTextField {
    let label = NSTextField(wrappingLabelWithString: text)
    label.font = .systemFont(ofSize: 13)
    label.textColor = .secondaryLabelColor
    label.maximumNumberOfLines = 0
    label.widthAnchor.constraint(equalToConstant: 514).isActive = true
    return label
  }

  private func separator() -> NSBox {
    let box = NSBox()
    box.boxType = .separator
    box.widthAnchor.constraint(equalToConstant: 514).isActive = true
    return box
  }

  @objc private func previewCat() {
    guard let cat = catalogCat, CatPackStore.shared.isInstalled(cat) else { return }
    if CatProfile.selected != cat {
      CatProfile.selected = cat
      onCatChanged(cat)
    }
    onPreview()
  }

  @objc private func selectCat() {
    guard let cat = catalogCat else { return }
    if CatPackStore.shared.isInstalled(cat) {
      CatProfile.selected = cat
      onCatChanged(cat)
    }
    refreshPackControls()
  }

  private func previewTitle() -> String {
    language.text(
      "\(CatProfile.selected.nameKo) 미리보기",
      "Preview \(CatProfile.selected.nameEn)"
    )
  }

  private var catalogCat: CatProfile? {
    guard CatProfile.all.indices.contains(catPicker.indexOfSelectedItem) else { return nil }
    return CatProfile.all[catPicker.indexOfSelectedItem]
  }

  private func refreshPackControls() {
    guard let cat = catalogCat else { return }
    let store = CatPackStore.shared
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file

    if cat.id == "elsa" {
      packStatus.stringValue = language.text(
        "앱에 기본 포함됨",
        "Included with the app"
      )
      packButton.isHidden = true
      previewButton.isEnabled = true
    } else if store.isInstalled(cat) {
      packStatus.stringValue = language.text(
        "설치됨 · \(formatter.string(fromByteCount: store.installedBytes(for: cat)))",
        "Installed · \(formatter.string(fromByteCount: store.installedBytes(for: cat)))"
      )
      packButton.title = language.text("삭제", "Remove")
      packButton.isHidden = false
      packButton.isEnabled = true
      previewButton.isEnabled = true
    } else if let pack = store.pack(for: cat) {
      packStatus.stringValue = language.text(
        "미설치 · \(formatter.string(fromByteCount: pack.bytes)) 다운로드",
        "Not installed · \(formatter.string(fromByteCount: pack.bytes)) download"
      )
      packButton.title = language.text("다운로드", "Download")
      packButton.isHidden = false
      packButton.isEnabled = true
      previewButton.isEnabled = false
    } else {
      packStatus.stringValue = language.text(
        "애니메이션 제작 및 검수 중",
        "Animation production and review in progress"
      )
      packButton.title = language.text("준비 중", "Coming soon")
      packButton.isHidden = false
      packButton.isEnabled = false
      previewButton.isEnabled = false
    }
    previewButton.title = language.text(
      "\(cat.nameKo) 미리보기",
      "Preview \(cat.nameEn)"
    )
  }

  @objc private func manageCatPack() {
    guard let cat = catalogCat, cat.id != "elsa" else { return }
    let store = CatPackStore.shared
    if store.isInstalled(cat) {
      do {
        if CatProfile.selected == cat {
          CatProfile.selected = CatProfile.all[0]
          onCatChanged(CatProfile.all[0])
        }
        try store.remove(cat)
        refreshPackControls()
      } catch {
        showPackError(error)
      }
      return
    }

    packButton.isEnabled = false
    catPicker.isEnabled = false
    packProgress.startAnimation(nil)
    Task { @MainActor [weak self] in
      do {
        try await store.install(cat)
        CatProfile.selected = cat
        self?.onCatChanged(cat)
        self?.finishPackOperation()
      } catch {
        self?.finishPackOperation()
        self?.showPackError(error)
      }
    }
  }

  private func finishPackOperation() {
    packProgress.stopAnimation(nil)
    catPicker.isEnabled = true
    refreshPackControls()
  }

  private func showPackError(_ error: Error) {
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = language.text(
      "고양이 팩을 처리할 수 없습니다",
      "Couldn’t manage the cat pack"
    )
    alert.informativeText = error.localizedDescription
    alert.runModal()
  }

  @objc private func selectLanguage() {
    guard AppLanguage.allCases.indices.contains(languagePicker.indexOfSelectedItem) else {
      return
    }
    onLanguageChanged(
      AppLanguage.allCases[languagePicker.indexOfSelectedItem]
    )
  }

  @objc private func openInputSettings() {
    onOpenInputSettings()
  }
}
