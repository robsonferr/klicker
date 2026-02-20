import Cocoa
import ServiceManagement
import UniformTypeIdentifiers

// MARK: - Localization Helper

private var currentBundle: Bundle = Bundle.main

func L(_ key: String) -> String {
    currentBundle.localizedString(forKey: key, value: nil, table: nil)
}

func setAppLanguage(_ code: String) {
    UserDefaults.standard.set([code], forKey: "AppleLanguages")
    if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
       let bundle = Bundle(path: path) {
        currentBundle = bundle
    }
}

func loadAppLanguage() {
    if let langs = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String],
       let first = langs.first,
       let path = Bundle.main.path(forResource: first, ofType: "lproj"),
       let bundle = Bundle(path: path) {
        currentBundle = bundle
    } else if let path = Bundle.main.path(forResource: "pt-BR", ofType: "lproj"),
              let bundle = Bundle(path: path) {
        currentBundle = bundle
    }
}

let appVersion = "0.1.0"

class ClickSoundApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var isEnabled = true
    private var volume: Float = 0.5
    private var leftSoundName = "Tink"
    private var rightSoundName = "Pop"
    private var aboutWindow: NSWindow?

    private var toggleMenuItem: NSMenuItem!
    private var loginMenuItem: NSMenuItem!
    private var languageMenu: NSMenu!
    private var leftSoundMenu: NSMenu!
    private var rightSoundMenu: NSMenu!
    private var volumeMenu: NSMenu!

    private var monitor: Any?

    private let systemSounds = [
        "Tink", "Pop", "Purr", "Hero", "Blow", "Bottle",
        "Frog", "Funk", "Glass", "Morse", "Ping", "Submarine", "Sosumi", "Basso"
    ]

    private let defaults = UserDefaults.standard

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        loadAppLanguage()
        loadSettings()
        setupStatusBar()
        checkAccessibility()
        startMonitoring()
    }

    // MARK: - Settings

    private func loadSettings() {
        if let s = defaults.string(forKey: "leftSound") { leftSoundName = s }
        if let s = defaults.string(forKey: "rightSound") { rightSoundName = s }
        if defaults.object(forKey: "volume") != nil { volume = defaults.float(forKey: "volume") }
        if defaults.object(forKey: "enabled") != nil { isEnabled = defaults.bool(forKey: "enabled") }
    }

    private func saveSettings() {
        defaults.set(leftSoundName, forKey: "leftSound")
        defaults.set(rightSoundName, forKey: "rightSound")
        defaults.set(volume, forKey: "volume")
        defaults.set(isEnabled, forKey: "enabled")
    }

    // MARK: - Menu Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusIcon()

        let menu = NSMenu()

        // About
        let aboutItem = NSMenuItem(title: L("menu.about"), action: #selector(showAbout), keyEquivalent: "")
        aboutItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
        aboutItem.target = self
        menu.addItem(aboutItem)
        menu.addItem(.separator())

        // Toggle
        toggleMenuItem = NSMenuItem(
            title: isEnabled ? L("menu.enabled") : L("menu.disabled"),
            action: #selector(toggle),
            keyEquivalent: "t"
        )
        toggleMenuItem.state = isEnabled ? .on : .off
        toggleMenuItem.target = self
        menu.addItem(toggleMenuItem)
        menu.addItem(.separator())

        // Left click sound
        leftSoundMenu = buildSoundMenu(selected: leftSoundName, action: #selector(setLeftSound(_:)))
        let leftItem = NSMenuItem(title: L("menu.left_click"), action: nil, keyEquivalent: "")
        leftItem.image = NSImage(systemSymbolName: "computermouse.click.fill", accessibilityDescription: nil)
        leftItem.submenu = leftSoundMenu
        menu.addItem(leftItem)

        // Right click sound
        rightSoundMenu = buildSoundMenu(selected: rightSoundName, action: #selector(setRightSound(_:)))
        let rightItem = NSMenuItem(title: L("menu.right_click"), action: nil, keyEquivalent: "")
        rightItem.image = NSImage(systemSymbolName: "computermouse.click.fill", accessibilityDescription: nil)
        rightItem.submenu = rightSoundMenu
        menu.addItem(rightItem)

        menu.addItem(.separator())

        // Volume
        volumeMenu = buildVolumeMenu()
        let volItem = NSMenuItem(title: L("menu.volume"), action: nil, keyEquivalent: "")
        volItem.image = NSImage(systemSymbolName: "speaker.wave.2.fill", accessibilityDescription: nil)
        volItem.submenu = volumeMenu
        menu.addItem(volItem)

        menu.addItem(.separator())

        // Custom sound file
        let customItem = NSMenuItem(
            title: L("menu.load_custom_sound"),
            action: #selector(loadCustomSound),
            keyEquivalent: ""
        )
        customItem.image = NSImage(systemSymbolName: "folder.fill", accessibilityDescription: nil)
        customItem.target = self
        menu.addItem(customItem)

        menu.addItem(.separator())

        // Launch at login
        loginMenuItem = NSMenuItem(
            title: L("menu.launch_at_login"),
            action: #selector(toggleLoginItem),
            keyEquivalent: ""
        )
        loginMenuItem.image = NSImage(systemSymbolName: "person.badge.clock", accessibilityDescription: nil)
        loginMenuItem.target = self
        loginMenuItem.state = isLoginItemEnabled() ? .on : .off
        menu.addItem(loginMenuItem)

        menu.addItem(.separator())

        // Language
        languageMenu = buildLanguageMenu()
        let langItem = NSMenuItem(title: L("menu.language"), action: nil, keyEquivalent: "")
        langItem.image = NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
        langItem.submenu = languageMenu
        menu.addItem(langItem)

        menu.addItem(.separator())

        // Quit
        let quitItem = NSMenuItem(title: L("menu.quit"), action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func buildSoundMenu(selected: String, action: Selector) -> NSMenu {
        let menu = NSMenu()
        for name in systemSounds {
            let item = NSMenuItem(title: name, action: action, keyEquivalent: "")
            item.target = self
            item.state = (name == selected) ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    private func buildVolumeMenu() -> NSMenu {
        let menu = NSMenu()
        let levels: [(String, Float)] = [("25%", 0.25), ("50%", 0.5), ("75%", 0.75), ("100%", 1.0)]
        for (title, val) in levels {
            let item = NSMenuItem(title: title, action: #selector(setVolume(_:)), keyEquivalent: "")
            item.target = self
            item.tag = Int(val * 100)
            item.state = (abs(volume - val) < 0.01) ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    private let supportedLanguages: [(code: String, name: String)] = [
        ("pt-BR", "Português (Brasil)"),
        ("en", "English"),
    ]

    private func currentLanguageCode() -> String {
        if let langs = defaults.array(forKey: "AppleLanguages") as? [String],
           let first = langs.first {
            return first
        }
        return "pt-BR"
    }

    private func buildLanguageMenu() -> NSMenu {
        let menu = NSMenu()
        let current = currentLanguageCode()
        for lang in supportedLanguages {
            let item = NSMenuItem(title: lang.name, action: #selector(changeLanguage(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = lang.code
            item.state = (lang.code == current) ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    @objc private func changeLanguage(_ sender: NSMenuItem) {
        guard let code = sender.representedObject as? String else { return }
        setAppLanguage(code)

        // Update language menu checkmarks
        for item in languageMenu.items {
            item.state = (item.representedObject as? String == code) ? .on : .off
        }

        // Rebuild the entire menu with new language
        rebuildMenu()
    }

    private func rebuildMenu() {
        statusItem.menu = nil
        setupStatusBar()
    }

    private func updateStatusIcon() {
        if let button = statusItem.button {
            button.title = ""
            button.image = drawMenuBarIcon(enabled: isEnabled)
        }
    }

    private func drawMenuBarIcon(enabled: Bool) -> NSImage {
        let size: CGFloat = 18
        let image = NSImage(size: NSSize(width: size * 1.4, height: size))

        image.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }

        let s = size
        NSColor.black.setFill()
        NSColor.black.setStroke()

        // -- Cursor arrow (left side) --
        let cursorScale = s / 280.0
        let cx = s * 0.20
        let cy = s * 0.52

        ctx.saveGState()
        ctx.translateBy(x: cx, y: cy)
        ctx.scaleBy(x: cursorScale, y: cursorScale)

        let arrow = CGMutablePath()
        arrow.move(to: CGPoint(x: 0, y: 100))
        arrow.addLine(to: CGPoint(x: 0, y: -100))
        arrow.addLine(to: CGPoint(x: 70, y: -30))
        arrow.addLine(to: CGPoint(x: 108, y: -85))
        arrow.addLine(to: CGPoint(x: 135, y: -68))
        arrow.addLine(to: CGPoint(x: 95, y: -10))
        arrow.addLine(to: CGPoint(x: 150, y: -10))
        arrow.closeSubpath()

        ctx.addPath(arrow)
        ctx.fillPath()
        ctx.restoreGState()

        // -- Sound waves (right side, only when enabled) --
        if enabled {
            let waveX = s * 0.85
            let waveY = s * 0.50

            ctx.setLineWidth(1.5)
            ctx.setLineCap(.round)

            for i in 0..<3 {
                let radius = s * (0.12 + Double(i) * 0.10)
                let alpha = 1.0 - Double(i) * 0.25

                ctx.saveGState()
                ctx.setAlpha(alpha)

                let startAngle = -CGFloat.pi / 3.5
                let endAngle = CGFloat.pi / 3.5

                ctx.addArc(center: CGPoint(x: waveX, y: waveY),
                           radius: radius,
                           startAngle: startAngle,
                           endAngle: endAngle,
                           clockwise: false)
                ctx.strokePath()
                ctx.restoreGState()
            }
        }

        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    private func updateSoundMenuState(_ menu: NSMenu, selected: String) {
        for item in menu.items {
            if let path = item.representedObject as? String {
                item.state = (path == selected) ? .on : .off
            } else {
                item.state = (item.title == selected) ? .on : .off
            }
        }
    }

    // MARK: - Accessibility

    private func checkAccessibility() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let opts = [key: true] as CFDictionary
        if !AXIsProcessTrustedWithOptions(opts) {
            print(L("accessibility.warning"))
            print("   " + L("accessibility.instructions"))
            print("   " + L("accessibility.add_app"))
        }
    }

    // MARK: - Event Monitoring

    private func startMonitoring() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] event in
            guard let self = self, self.isEnabled else { return }

            let name = (event.type == .leftMouseDown) ? self.leftSoundName : self.rightSoundName
            self.playSound(named: name)
        }
    }

    // MARK: - Sound Playback

    private func playSound(named name: String) {
        var sound: NSSound?

        if FileManager.default.fileExists(atPath: name) {
            sound = NSSound(contentsOfFile: name, byReference: false)
        } else {
            sound = NSSound(named: NSSound.Name(name))
        }

        guard let original = sound, let copy = original.copy() as? NSSound else { return }
        copy.volume = volume
        copy.play()
    }

    // MARK: - Actions

    @objc private func toggle() {
        isEnabled.toggle()
        toggleMenuItem.title = isEnabled ? L("menu.enabled") : L("menu.disabled")
        toggleMenuItem.state = isEnabled ? .on : .off
        updateStatusIcon()
        saveSettings()
    }

    @objc private func setLeftSound(_ sender: NSMenuItem) {
        leftSoundName = (sender.representedObject as? String) ?? sender.title
        updateSoundMenuState(leftSoundMenu, selected: leftSoundName)
        saveSettings()
        playSound(named: leftSoundName)
    }

    @objc private func setRightSound(_ sender: NSMenuItem) {
        rightSoundName = (sender.representedObject as? String) ?? sender.title
        updateSoundMenuState(rightSoundMenu, selected: rightSoundName)
        saveSettings()
        playSound(named: rightSoundName)
    }

    @objc private func setVolume(_ sender: NSMenuItem) {
        volume = Float(sender.tag) / 100.0
        for item in volumeMenu.items {
            item.state = (item.tag == sender.tag) ? .on : .off
        }
        saveSettings()
        playSound(named: leftSoundName)
    }

    @objc private func loadCustomSound() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.audio]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.title = L("menu.custom_sound_panel_title")

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let path = url.path
        let fileName = url.lastPathComponent

        addCustomSoundItem(to: leftSoundMenu, fileName: fileName, path: path, action: #selector(setLeftSound(_:)))
        addCustomSoundItem(to: rightSoundMenu, fileName: fileName, path: path, action: #selector(setRightSound(_:)))

        leftSoundName = path
        updateSoundMenuState(leftSoundMenu, selected: leftSoundName)
        saveSettings()
        playSound(named: path)
    }

    private func addCustomSoundItem(to menu: NSMenu, fileName: String, path: String, action: Selector) {
        if menu.items.contains(where: { ($0.representedObject as? String) == path }) { return }

        menu.addItem(.separator())
        let item = NSMenuItem(title: "♪ \(fileName)", action: action, keyEquivalent: "")
        item.target = self
        item.representedObject = path
        menu.addItem(item)
    }

    // MARK: - About Window

    @objc private func showAbout() {
        if let w = aboutWindow, w.isVisible {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let width: CGFloat = 320
        let height: CGFloat = 380
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L("menu.about")
        window.center()
        window.isReleasedWhenClosed = false

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

        // App icon
        let iconView = NSImageView(frame: NSRect(x: (width - 96) / 2, y: height - 130, width: 96, height: 96))
        if let icon = NSImage(named: "AppIcon") ?? NSApp.applicationIconImage {
            iconView.image = icon
        }
        iconView.imageScaling = .scaleProportionallyUpOrDown
        contentView.addSubview(iconView)

        // App name
        let nameLabel = NSTextField(labelWithString: "Klicker")
        nameLabel.font = .boldSystemFont(ofSize: 20)
        nameLabel.alignment = .center
        nameLabel.frame = NSRect(x: 0, y: height - 165, width: width, height: 28)
        contentView.addSubview(nameLabel)

        // Version
        let versionLabel = NSTextField(labelWithString: "\(L("about.version")) \(appVersion)")
        versionLabel.font = .systemFont(ofSize: 12)
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.alignment = .center
        versionLabel.frame = NSRect(x: 0, y: height - 188, width: width, height: 18)
        contentView.addSubview(versionLabel)

        // Description
        let descLabel = NSTextField(wrappingLabelWithString: L("about.description"))
        descLabel.font = .systemFont(ofSize: 12)
        descLabel.textColor = .secondaryLabelColor
        descLabel.alignment = .center
        descLabel.frame = NSRect(x: 30, y: height - 238, width: width - 60, height: 40)
        contentView.addSubview(descLabel)

        // Separator
        let separator = NSBox(frame: NSRect(x: 30, y: height - 255, width: width - 60, height: 1))
        separator.boxType = .separator
        contentView.addSubview(separator)

        // Author
        let authorLabel = NSTextField(labelWithString: L("about.author"))
        authorLabel.font = .systemFont(ofSize: 11)
        authorLabel.textColor = .tertiaryLabelColor
        authorLabel.alignment = .center
        authorLabel.frame = NSRect(x: 0, y: height - 282, width: width, height: 16)
        contentView.addSubview(authorLabel)

        // GitHub link button
        let githubButton = NSButton(frame: NSRect(x: (width - 160) / 2, y: height - 315, width: 160, height: 28))
        githubButton.title = "GitHub"
        githubButton.bezelStyle = .rounded
        githubButton.target = self
        githubButton.action = #selector(openGitHub)
        contentView.addSubview(githubButton)

        // Copyright
        let copyrightLabel = NSTextField(labelWithString: L("about.copyright"))
        copyrightLabel.font = .systemFont(ofSize: 10)
        copyrightLabel.textColor = .tertiaryLabelColor
        copyrightLabel.alignment = .center
        copyrightLabel.frame = NSRect(x: 0, y: 15, width: width, height: 14)
        contentView.addSubview(copyrightLabel)

        window.contentView = contentView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        aboutWindow = window
    }

    @objc private func openGitHub() {
        NSWorkspace.shared.open(URL(string: "https://github.com/robsonferr/klicker")!)
    }

    // MARK: - Login Item

    private func isLoginItemEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    @objc private func toggleLoginItem() {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                } else {
                    try SMAppService.mainApp.register()
                }
            } catch {
                print("Erro ao alterar item de login: \(error)")
            }
            loginMenuItem.state = isLoginItemEnabled() ? .on : .off
        }
    }

    @objc private func quit() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
        NSApp.terminate(nil)
    }
}

// MARK: - Entry Point

let app = NSApplication.shared
let delegate = ClickSoundApp()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
