import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  private let overlay = OverlayController()
  private var engine: MonitoringEngine?
  private var statusMenuItem: NSMenuItem?
  private var loginMenuItem: NSMenuItem?
  private var settingsController: SettingsController?

  private var language: AppLanguage {
    .selected
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    configureMenu()
    enableLaunchAtLogin()

    let keyboardMonitor = ExternalKeyboardMonitor()
    let provider = SystemSnapshotProvider(keyboardMonitor: keyboardMonitor)
    let initialSnapshot = provider.snapshot()
    engine = MonitoringEngine(
      provider: provider,
      onAction: { [weak self] action in self?.handle(action) },
      onStatus: { [weak self] snapshot, activeSeconds in
        self?.updateStatus(snapshot, activeSeconds: activeSeconds)
      }
    )
    if let snoozedUntil = UserDefaults.standard.object(forKey: "snoozedUntil") as? Date,
      snoozedUntil > Date()
    {
      engine?.snooze(until: snoozedUntil)
    } else {
      UserDefaults.standard.removeObject(forKey: "snoozedUntil")
    }
    engine?.start()

    if initialSnapshot.macKind == .portable,
      initialSnapshot.keyboardAccessStatus != .granted,
      !CommandLine.arguments.contains("--preview"),
      !CommandLine.arguments.contains("--small-preview"),
      !CommandLine.arguments.contains("--settings-preview")
    {
      DispatchQueue.main.async { [weak self] in
        self?.showPermissionNotice()
      }
    }

    if CommandLine.arguments.contains("--preview") {
      DispatchQueue.main.async { [weak self] in
        self?.handle(.showLargeCat)
      }
    }
    if CommandLine.arguments.contains("--small-preview") {
      DispatchQueue.main.async { [weak self] in
        self?.handle(.showBreakCat)
      }
    }
    if CommandLine.arguments.contains("--settings-preview") {
      DispatchQueue.main.async { [weak self] in
        self?.showSettings()
      }
    }
  }

  private func configureMenu() {
    statusItem.button?.image = NSImage(
      systemSymbolName: "cat.fill",
      accessibilityDescription: "Meownitor"
    )
    statusItem.button?.toolTip = "목펴라냥 · Meownitor"

    let menu = NSMenu()
    let status = NSMenuItem(
      title: language.text("상태 확인 중…", "Checking your setup…"),
      action: nil,
      keyEquivalent: ""
    )
    status.isEnabled = false
    menu.addItem(status)
    statusMenuItem = status
    menu.addItem(.separator())

    let preview = NSMenuItem(
      title: language.text(
        "\(CatProfile.selected.nameKo) 보기",
        "Show \(CatProfile.selected.nameEn)"
      ),
      action: #selector(showPreview),
      keyEquivalent: ""
    )
    preview.target = self
    menu.addItem(preview)

    let settings = NSMenuItem(
      title: language.text("설정…", "Settings…"),
      action: #selector(showSettings),
      keyEquivalent: ","
    )
    settings.target = self
    menu.addItem(settings)

    let login = NSMenuItem(
      title: language.text("로그인 시 자동 실행", "Launch at Login"),
      action: #selector(toggleLaunchAtLogin),
      keyEquivalent: ""
    )
    login.target = self
    menu.addItem(login)
    loginMenuItem = login
    refreshLoginMenu()

    let inputSettings = NSMenuItem(
      title: language.text(
        "입력 모니터링 설정 열기",
        "Open Input Monitoring Settings"
      ),
      action: #selector(openInputMonitoringSettings),
      keyEquivalent: ""
    )
    inputSettings.target = self
    menu.addItem(inputSettings)

    menu.addItem(.separator())
    let quit = NSMenuItem(
      title: language.text("목펴라냥 종료", "Quit Meownitor"),
      action: #selector(quit),
      keyEquivalent: "q"
    )
    quit.target = self
    menu.addItem(quit)
    statusItem.menu = menu
  }

  private func handle(_ action: MonitorAction) {
    switch action {
    case .none:
      break
    case .showLargeCat:
      overlay.showLarge(
        message: language.text(
          "외장 모니터를 연결하고 목을 펴라냥!",
          "Connect another display and sit up straight."
        ),
        language: language,
        cat: .selected,
        onSnooze: { [weak self] duration in
          self?.snooze(for: duration)
        }
      )
    case .showBreakCat:
      overlay.showSmall(
        message: language.text(
          "잠깐 쉬면서 몸을 펴주세요.",
          "Take a moment to stretch."
        ),
        language: language,
        cat: .selected
      )
    }
  }

  private func updateStatus(_ snapshot: MonitorSnapshot, activeSeconds: TimeInterval) {
    let title: String
    if snapshot.macKind == .iMac {
      title = language.text(
        "iMac · 휴식 알림만 사용",
        "iMac · Break reminders only"
      )
    } else if snapshot.macKind == .desktop {
      title = language.text(
        "이 Mac에서는 자세 알림 사용 안 함",
        "Posture alerts unavailable on this Mac"
      )
    } else if snapshot.hasExternalDisplay {
      title = language.text(
        "외장 모니터 사용 중 · 알림 일시 정지",
        "External display in use · Alerts paused"
      )
    } else if snapshot.keyboardAccessStatus != .granted {
      title = language.text(
        "키보드 감지 꺼짐 · 모니터만 확인 중",
        "Keyboard detection off · Display only"
      )
    } else if snapshot.isUsingExternalKeyboard {
      title = language.text(
        "외장 키보드 사용 중 · 알림 일시 정지",
        "External keyboard in use · Alerts paused"
      )
    } else {
      let minutes = Int(activeSeconds / 60)
      title = language.text(
        "MacBook 사용 \(minutes)/25분",
        "MacBook use: \(minutes)/25 min"
      )
    }
    statusMenuItem?.title = title
  }

  private func enableLaunchAtLogin() {
    guard SMAppService.mainApp.status != .enabled,
      SMAppService.mainApp.status != .requiresApproval
    else {
      refreshLoginMenu()
      return
    }
    do {
      try SMAppService.mainApp.register()
    } catch {
      NSLog("Could not enable launch at login: \(error.localizedDescription)")
    }
    refreshLoginMenu()
  }

  private func refreshLoginMenu() {
    switch SMAppService.mainApp.status {
    case .enabled:
      loginMenuItem?.state = .on
      loginMenuItem?.title = language.text("로그인 시 자동 실행", "Launch at Login")
    case .requiresApproval:
      loginMenuItem?.state = .mixed
      loginMenuItem?.title =
        language.text(
          "로그인 시 자동 실행 (승인 필요)",
          "Launch at Login (Approval required)"
        )
    default:
      loginMenuItem?.state = .off
      loginMenuItem?.title = language.text("로그인 시 자동 실행", "Launch at Login")
    }
  }

  @objc private func showPreview() {
    handle(.showLargeCat)
  }

  @objc private func showSettings() {
    if settingsController == nil {
      settingsController = SettingsController(
        language: language,
        onPreview: { [weak self] in self?.showPreview() },
        onOpenInputSettings: { [weak self] in self?.openInputMonitoringSettings() },
        onLanguageChanged: { [weak self] selection in
          self?.applyLanguage(selection)
        },
        onCatChanged: { [weak self] _ in
          self?.overlay.dismiss()
          self?.configureMenu()
        }
      )
    }
    settingsController?.show()
  }

  private func showPermissionNotice() {
    overlay.showPermissionNotice(
      message: language.text(
        "입력 모니터링을 허용하면 외장 키보드를 사용하는 동안 알림을 띄우지 않습니다. 허용하지 않아도 외장 모니터 연결 여부만으로 사용할 수 있습니다.",
        "Allow Input Monitoring to pause alerts while you use an external keyboard. Without it, Meownitor can still use external-display detection."
      ),
      settingsTitle: language.text("설정 열기", "Open Settings"),
      language: language,
      cat: .selected,
      onOpenSettings: { [weak self] in self?.showSettings() }
    )
  }

  private func applyLanguage(_ selection: AppLanguage) {
    AppLanguage.selected = selection
    overlay.dismiss()
    settingsController?.close()
    settingsController = nil
    configureMenu()
    showSettings()
  }

  private func snooze(for duration: TimeInterval) {
    let until = Date().addingTimeInterval(duration)
    UserDefaults.standard.set(until, forKey: "snoozedUntil")
    engine?.snooze(until: until)
  }

  @objc private func openInputMonitoringSettings() {
    ExternalKeyboardMonitor.requestAccess()
    guard
      let url = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
      )
    else {
      return
    }
    NSWorkspace.shared.open(url)
  }

  @objc private func toggleLaunchAtLogin() {
    do {
      if SMAppService.mainApp.status == .enabled {
        try SMAppService.mainApp.unregister()
      } else {
        try SMAppService.mainApp.register()
      }
    } catch {
      NSLog("Could not update launch at login: \(error.localizedDescription)")
    }
    refreshLoginMenu()
  }

  @objc private func quit() {
    NSApp.terminate(nil)
  }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.run()
