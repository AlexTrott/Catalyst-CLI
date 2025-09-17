import Foundation
import SwiftShell

public struct Shell {

    public enum ShellError: LocalizedError {
        case commandFailed(command: String, exitCode: Int32, output: String, error: String)
        case timeout(command: String)

        public var errorDescription: String? {
            switch self {
            case .commandFailed(let command, let exitCode, let output, let error):
                return """
                Command failed: \(command)
                Exit code: \(exitCode)
                Output: \(output)
                Error: \(error)
                """
            case .timeout(let command):
                return "Command timed out: \(command)"
            }
        }
    }

    @discardableResult
    public static func run(
        _ command: String,
        at path: String? = nil,
        timeout: TimeInterval? = nil,
        silent: Bool = false
    ) throws -> String {
        if !silent {
            Console.print("Running: \(command)", type: .detail)
        }

        var context = CustomContext(main)
        if let path = path {
            context.currentdirectory = path
        }

        let result = context.run(bash: command)

        if result.exitcode != 0 {
            throw ShellError.commandFailed(
                command: command,
                exitCode: Int32(result.exitcode),
                output: result.stdout,
                error: result.stderror
            )
        }

        return result.stdout
    }

    public static func runAsync(
        _ command: String,
        at path: String? = nil,
        onOutput: @escaping (String) -> Void,
        onError: @escaping (String) -> Void,
        onCompletion: @escaping (Bool) -> Void
    ) {
        var context = CustomContext(main)
        if let path = path {
            context.currentdirectory = path
        }

        let process = context.runAsync(bash: command)

        process.stdout.onStringOutput { output in
            onOutput(output)
        }

        process.stderror.onStringOutput { error in
            onError(error)
        }

        process.onCompletion { command in
            onCompletion(command.exitcode() == 0)
        }
    }

    public static func which(_ command: String) -> String? {
        do {
            let result = try run("which \(command)", silent: true)
            return result.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    public static func exists(_ command: String) -> Bool {
        return which(command) != nil
    }

    public static func checkDependency(_ command: String, installMessage: String) throws {
        if !exists(command) {
            throw ShellError.commandFailed(
                command: command,
                exitCode: 127,
                output: "",
                error: "Command '\(command)' not found. \(installMessage)"
            )
        }
    }

    @available(macOS 10.15, *)
    public static func runAsync(
        _ command: String,
        at path: String? = nil,
        timeout: TimeInterval? = nil,
        silent: Bool = true
    ) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result = try run(command, at: path, timeout: timeout, silent: silent)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}