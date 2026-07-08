import AppKit
import BrewCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    private let checker: BrewChecker
    private let upgradeLauncher: UpgradeLauncher
    private var status: BrewStatus = .upToDate

    private let checkInterval: TimeInterval = 6 * 60 * 60
    private var timer: Timer?
    private var upgradeWatchTimer: Timer?

    private lazy var statusMenuItem = NSMenuItem(title: "Checking…", action: nil, keyEquivalent: "")

    override init() {
        let brewPath = Self.resolveBrewPath()
        checker = BrewChecker(runner: ProcessCommandRunner(), brewPath: brewPath)
        upgradeLauncher = UpgradeLauncher(brewPath: brewPath)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItemButton()
        configureMenu()
        applyStatus(.upToDate)

        if let fake = ProcessInfo.processInfo.environment["BREWMENU_FAKE_STATUS"] {
            applyStatus(Self.fakeStatus(for: fake))
        } else {
            refresh()
        }

        timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    private func configureStatusItemButton() {
        guard let button = statusItem.button else { return }
        button.image = Self.mugImage(tint: nil)
    }

    private static func mugImage(tint: NSColor?) -> NSImage? {
        guard let image = NSImage(systemSymbolName: "mug", accessibilityDescription: "Homebrew") else {
            return nil
        }
        guard let tint else {
            image.isTemplate = true
            return image
        }
        let tinted = image.withSymbolConfiguration(.init(paletteColors: [tint]))
        tinted?.isTemplate = false
        return tinted
    }

    private func configureMenu() {
        let menu = NSMenu()

        let eyebrowItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        eyebrowItem.isEnabled = false
        eyebrowItem.attributedTitle = NSAttributedString(
            string: "brew dater",
            attributes: [
                .font: NSFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: NSColor.secondaryLabelColor,
            ]
        )
        menu.addItem(eyebrowItem)

        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        menu.addItem(.separator())

        let upgradeItem = NSMenuItem(title: "Upgrade Now", action: #selector(upgradeNow), keyEquivalent: "")
        upgradeItem.target = self
        menu.addItem(upgradeItem)

        let checkItem = NSMenuItem(title: "Check Now", action: #selector(checkNow), keyEquivalent: "")
        checkItem.target = self
        menu.addItem(checkItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func checkNow() {
        refresh()
    }

    @objc private func upgradeNow() {
        guard let sentinelURL = try? upgradeLauncher.launch() else { return }
        watchForUpgradeCompletion(at: sentinelURL)
    }

    /// Polls for the sentinel file the upgrade script touches when brew finishes,
    /// then re-checks status so the icon reflects the real post-upgrade state.
    private func watchForUpgradeCompletion(at sentinelURL: URL) {
        upgradeWatchTimer?.invalidate()
        upgradeWatchTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, FileManager.default.fileExists(atPath: sentinelURL.path) else { return }
                self.upgradeWatchTimer?.invalidate()
                try? FileManager.default.removeItem(at: sentinelURL)
                self.refresh()
            }
        }
    }

    private func refresh() {
        Task {
            let result = await Task.detached { [checker] in
                checker.checkForUpdates()
            }.value
            applyStatus(result)
        }
    }

    private func applyStatus(_ status: BrewStatus) {
        self.status = status

        switch status {
        case .upToDate:
            statusItem.button?.image = Self.mugImage(tint: nil)
            statusMenuItem.title = "Up to date"
        case .updatesAvailable(let count):
            statusItem.button?.image = Self.mugImage(tint: .systemRed)
            statusMenuItem.title = count == 1 ? "1 update available" : "\(count) updates available"
        case .failed(let reason):
            statusItem.button?.image = Self.mugImage(tint: .systemOrange)
            statusMenuItem.title = "Check failed: \(reason)"
        }
    }

    private static func resolveBrewPath() -> String {
        let candidates = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
        return candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) ?? candidates[0]
    }

    private static func fakeStatus(for value: String) -> BrewStatus {
        switch value {
        case "updates": return .updatesAvailable(count: 3)
        case "fail": return .failed(reason: "fake failure")
        default: return .upToDate
        }
    }
}
