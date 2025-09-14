import Foundation
import Rainbow

public enum Console {

    public enum MessageType {
        case success
        case info
        case warning
        case error
        case progress
        case detail
    }

    public static func print(_ message: String, type: MessageType = .info) {
        let output: String

        switch type {
        case .success:
            output = "✅ " + message.green
        case .info:
            output = "ℹ️  " + message.cyan
        case .warning:
            output = "⚠️  " + message.yellow
        case .error:
            output = "❌ " + message.red
        case .progress:
            output = "🔄 " + message.blue
        case .detail:
            output = "   " + message.lightBlack
        }

        Swift.print(output)
    }

    public static func printHeader(_ message: String) {
        let separator = String(repeating: "=", count: message.count + 4)
        Swift.print(separator.cyan)
        Swift.print("  \(message)  ".cyan.bold)
        Swift.print(separator.cyan)
    }

    public static func printStep(_ step: Int, total: Int, message: String) {
        let stepInfo = "[\(step)/\(total)]".lightBlack
        Swift.print("\(stepInfo) \(message)")
    }

    public static func printEmoji(_ emoji: String, message: String) {
        Swift.print("\(emoji) \(message)")
    }

    public static func printList(_ items: [String], indent: Int = 2) {
        let indentation = String(repeating: " ", count: indent)
        for item in items {
            Swift.print("\(indentation)• \(item)")
        }
    }

    public static func printCodeBlock(_ code: String) {
        Swift.print("```".lightBlack)
        Swift.print(code)
        Swift.print("```".lightBlack)
    }

    public static func printDryRun(_ action: String) {
        Swift.print("[DRY RUN] ".yellow.bold + action.yellow)
    }

    public static func clear() {
        Swift.print("\u{001B}[2J\u{001B}[H")
    }

    public static func newLine(_ count: Int = 1) {
        for _ in 0..<count {
            Swift.print("")
        }
    }
}