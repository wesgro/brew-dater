import BrewCore
import Foundation

final class Checklist {
    private(set) var failures = 0

    func check(_ name: String, _ condition: @autoclosure () -> Bool) {
        if condition() {
            print("✓ \(name)")
        } else {
            print("✗ \(name)")
            failures += 1
        }
    }
}

let checklist = Checklist()

// Slice 1: reports upToDate when brew outdated has no output
do {
    let runner = FakeCommandRunner(resultsByArgs: [
        ["outdated", "--quiet"]: CommandResult(stdout: "", stderr: "", exitCode: 0),
    ])
    let checker = BrewChecker(runner: runner, brewPath: "/opt/homebrew/bin/brew")

    checklist.check("reports upToDate when no outdated packages", checker.checkForUpdates() == .upToDate)
}

// Slice 2: reports count of outdated packages, ignoring blank lines
do {
    let runner = FakeCommandRunner(resultsByArgs: [
        ["outdated", "--quiet"]: CommandResult(stdout: "wget\ngit\njq\n\n", stderr: "", exitCode: 0),
    ])
    let checker = BrewChecker(runner: runner, brewPath: "/opt/homebrew/bin/brew")

    checklist.check(
        "reports updatesAvailable(3) for 3 outdated packages",
        checker.checkForUpdates() == .updatesAvailable(count: 3)
    )
}

// Slice 3: runs `brew update` before `brew outdated`
do {
    let runner = SpyCommandRunner(resultsByArgs: [
        ["outdated", "--quiet"]: CommandResult(stdout: "", stderr: "", exitCode: 0),
    ])
    let checker = BrewChecker(runner: runner, brewPath: "/opt/homebrew/bin/brew")

    _ = checker.checkForUpdates()

    checklist.check(
        "runs brew update before brew outdated",
        runner.callsInOrder == [["update"], ["outdated", "--quiet"]]
    )
}

// Slice 4: reports failure when the runner throws or a command exits nonzero
do {
    let checker = BrewChecker(runner: ThrowingCommandRunner(), brewPath: "/opt/homebrew/bin/brew")

    if case .failed = checker.checkForUpdates() {
        checklist.check("reports failed when runner throws", true)
    } else {
        checklist.check("reports failed when runner throws", false)
    }
}

do {
    let runner = FakeCommandRunner(resultsByArgs: [
        ["outdated", "--quiet"]: CommandResult(stdout: "", stderr: "brew: command not found", exitCode: 1),
    ])
    let checker = BrewChecker(runner: runner, brewPath: "/opt/homebrew/bin/brew")

    if case .failed = checker.checkForUpdates() {
        checklist.check("reports failed when brew outdated exits nonzero", true)
    } else {
        checklist.check("reports failed when brew outdated exits nonzero", false)
    }
}

// Slice 5: upgrade script content runs brew update && brew upgrade and stays open
do {
    let launcher = UpgradeLauncher(brewPath: "/opt/homebrew/bin/brew")
    let script = launcher.makeUpgradeScript()

    checklist.check(
        "upgrade script chains brew update && brew upgrade",
        script.contains("/opt/homebrew/bin/brew update && /opt/homebrew/bin/brew upgrade")
    )
    checklist.check(
        "upgrade script keeps the window open after finishing",
        script.contains("read")
    )
}

if checklist.failures > 0 {
    print("\n\(checklist.failures) check(s) failed")
    exit(1)
} else {
    print("\nAll checks passed")
}
