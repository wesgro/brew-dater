import Foundation

public struct UpgradeLauncher: Sendable {
    let brewPath: String

    public init(brewPath: String) {
        self.brewPath = brewPath
    }

    public func makeUpgradeScript() -> String {
        """
        #!/bin/bash
        \(brewPath) update && \(brewPath) upgrade
        echo
        echo "Done. Press any key to close."
        read -n 1
        """
    }

    /// Writes the upgrade script to a temp `.command` file and opens it, which
    /// routes to the user's default terminal app via LaunchServices.
    public func launch() throws {
        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("brewmenu-upgrade-\(UUID().uuidString)")
            .appendingPathExtension("command")

        try makeUpgradeScript().write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [scriptURL.path]
        try process.run()
    }
}
