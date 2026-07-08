import BrewCore

struct FakeCommandRunner: CommandRunning {
    var resultsByArgs: [[String]: CommandResult]
    var defaultResult = CommandResult(stdout: "", stderr: "", exitCode: 0)

    func run(_ launchPath: String, _ args: [String]) throws -> CommandResult {
        resultsByArgs[args] ?? defaultResult
    }
}

final class SpyCommandRunner: CommandRunning, @unchecked Sendable {
    var resultsByArgs: [[String]: CommandResult]
    var defaultResult = CommandResult(stdout: "", stderr: "", exitCode: 0)
    private(set) var callsInOrder: [[String]] = []

    init(resultsByArgs: [[String]: CommandResult] = [:]) {
        self.resultsByArgs = resultsByArgs
    }

    func run(_ launchPath: String, _ args: [String]) throws -> CommandResult {
        callsInOrder.append(args)
        return resultsByArgs[args] ?? defaultResult
    }
}

struct ThrowingCommandRunner: CommandRunning {
    struct Failure: Error {}

    func run(_ launchPath: String, _ args: [String]) throws -> CommandResult {
        throw Failure()
    }
}
