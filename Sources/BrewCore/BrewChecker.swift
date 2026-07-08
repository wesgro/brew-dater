import Foundation

public enum BrewStatus: Equatable, Sendable {
    case upToDate
    case updatesAvailable(count: Int)
    case failed(reason: String)
}

public struct BrewChecker: Sendable {
    let runner: CommandRunning
    let brewPath: String

    public init(runner: CommandRunning, brewPath: String) {
        self.runner = runner
        self.brewPath = brewPath
    }

    public func checkForUpdates() -> BrewStatus {
        do {
            let update = try runner.run(brewPath, ["update"])
            guard update.exitCode == 0 else {
                return .failed(reason: update.stderr)
            }

            let outdated = try runner.run(brewPath, ["outdated", "--quiet"])
            guard outdated.exitCode == 0 else {
                return .failed(reason: outdated.stderr)
            }

            let packages = outdated.stdout
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            if packages.isEmpty {
                return .upToDate
            }
            return .updatesAvailable(count: packages.count)
        } catch {
            return .failed(reason: "\(error)")
        }
    }
}
