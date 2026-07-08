import Foundation

public struct UpgradeLauncher: Sendable {
    let brewPath: String

    public init(brewPath: String) {
        self.brewPath = brewPath
    }

    /// `sentinelPath` is touched once brew finishes, so a watcher can detect completion.
    /// Closing is only attempted for Apple's Terminal.app (detected via $TERM_PROGRAM);
    /// other terminal apps just exit normally and rely on their own profile settings.
    public func makeUpgradeScript(sentinelPath: String) -> String {
        """
        #!/bin/bash
        \(brewPath) update && \(brewPath) upgrade
        touch '\(sentinelPath)'
        if [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
            osascript -e 'tell application "Terminal" to close (every window whose tty is "'"$(tty)"'")' &
        fi
        exit
        """
    }

    /// Writes the upgrade script to a temp `.command` file and opens it, which
    /// routes to the user's default terminal app via LaunchServices. Returns the
    /// sentinel file URL the script touches on completion, so callers can detect
    /// when the upgrade has finished.
    @discardableResult
    public func launch() throws -> URL {
        let id = UUID().uuidString
        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("brewmenu-upgrade-\(id)")
            .appendingPathExtension("command")
        let sentinelURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("brewmenu-upgrade-\(id)")
            .appendingPathExtension("done")

        try makeUpgradeScript(sentinelPath: sentinelURL.path).write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [scriptURL.path]
        try process.run()

        return sentinelURL
    }
}
