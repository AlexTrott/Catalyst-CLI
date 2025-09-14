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

    public static func printBanner(withVersion version: String = "1.0.0") {
        let banner = """
        ╔══════════════════════════════════════════════════════════════════════════════╗
        ║                                                                              ║
        ║   ██████╗ █████╗ ████████╗ █████╗ ██╗     ██╗   ██╗███████╗████████╗        ║
        ║  ██╔════╝██╔══██╗╚══██╔══╝██╔══██╗██║     ╚██╗ ██╔╝██╔════╝╚══██╔══╝        ║
        ║  ██║     ███████║   ██║   ███████║██║      ╚████╔╝ ███████╗   ██║           ║
        ║  ██║     ██╔══██║   ██║   ██╔══██║██║       ╚██╔╝  ╚════██║   ██║           ║
        ║  ╚██████╗██║  ██║   ██║   ██║  ██║███████╗   ██║   ███████║   ██║           ║
        ║   ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝   ╚═╝           ║
        ║                                                                              ║
        ║                   🚀 Swift CLI for iOS Module Generation                    ║
        ║                            Version \(version.padding(toLength: 6, withPad: " ", startingAt: 0))                               ║
        ║                                                                              ║
        ╚══════════════════════════════════════════════════════════════════════════════╝
        """

        Swift.print(banner.cyan.bold)
        newLine()
    }

    public static func printMiniBanner() {
        let miniBanner = """
        ⚡ Catalyst ⚡
        """
        Swift.print(miniBanner.cyan.bold)
    }

    public static func printGradientText(_ text: String, colors: [Color] = [.cyan, .blue, .magenta]) {
        let chars = Array(text)
        guard chars.count > 0 else { return }

        var output = ""
        for (index, char) in chars.enumerated() {
            let colorIndex = index % colors.count
            switch colors[colorIndex] {
            case .cyan:
                output += String(char).cyan
            case .blue:
                output += String(char).blue
            case .magenta:
                output += String(char).magenta
            case .green:
                output += String(char).green
            case .yellow:
                output += String(char).yellow
            case .red:
                output += String(char).red
            default:
                output += String(char)
            }
        }
        Swift.print(output)
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

    public static func printHeader(_ message: String, style: HeaderStyle = .modern) {
        switch style {
        case .classic:
            let separator = String(repeating: "=", count: message.count + 4)
            Swift.print(separator.cyan)
            Swift.print("  \(message)  ".cyan.bold)
            Swift.print(separator.cyan)

        case .modern:
            printBoxed(message, style: .double)

        case .minimal:
            Swift.print("▶ \(message)".cyan.bold)
            Swift.print(String(repeating: "─", count: message.count + 2).cyan)
        }
    }

    public enum HeaderStyle {
        case classic
        case modern
        case minimal
    }

    public static func printStep(_ step: Int, total: Int, message: String, style: StepStyle = .modern) {
        switch style {
        case .classic:
            let stepInfo = "[\(step)/\(total)]".lightBlack
            Swift.print("\(stepInfo) \(message)")

        case .modern:
            let progress = "█".repeat(step).green + "░".repeat(total - step).lightBlack
            let percentage = String(format: "%.0f%%", (Double(step) / Double(total)) * 100)
            Swift.print("[\(progress)] \(percentage.cyan) \(message)")

        case .dots:
            let dots = "●".repeat(step).cyan + "○".repeat(total - step).lightBlack
            Swift.print("\(dots) \(message)")

        case .arrows:
            let arrow = step == total ? "✅" : "➤"
            Swift.print("\(arrow.cyan) \(step)/\(total) \(message)")
        }
    }

    public enum StepStyle {
        case classic
        case modern
        case dots
        case arrows
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

    public static func printSpinner(message: String, duration: TimeInterval = 2.0) {
        let spinnerChars = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < duration {
            for char in spinnerChars {
                Swift.print("\r\(char.cyan.bold) \(message)", terminator: "")
                fflush(stdout)
                Thread.sleep(forTimeInterval: 0.1)

                if Date().timeIntervalSince(startTime) >= duration {
                    break
                }
            }
        }
        Swift.print("\r✅ \(message)".green.bold)
    }

    public static func printProgressBar(current: Int, total: Int, message: String = "", width: Int = 40) {
        let percentage = Double(current) / Double(total)
        let filled = Int(percentage * Double(width))
        let empty = width - filled

        let filledBar = String(repeating: "█", count: filled).green
        let emptyBar = String(repeating: "░", count: empty).lightBlack

        let percentageText = String(format: "%.1f%%", percentage * 100)
        Swift.print("\r[\(filledBar)\(emptyBar)] \(percentageText) \(message)", terminator: "")
        fflush(stdout)

        if current == total {
            Swift.print()
        }
    }

    public static func printBoxed(_ message: String, style: BoxStyle = .rounded) {
        let lines = message.components(separatedBy: .newlines)
        let maxLength = lines.map { visualLength($0) }.max() ?? 0
        let padding = 2

        let (topLeft, topRight, bottomLeft, bottomRight, horizontal, vertical) = style.characters

        // Top border
        Swift.print("\(topLeft)\(String(repeating: horizontal, count: maxLength + padding * 2))\(topRight)".cyan)

        // Content lines
        for line in lines {
            let visualLen = visualLength(line)
            let spacesToAdd = maxLength - visualLen
            let paddedLine = line + String(repeating: " ", count: max(0, spacesToAdd))
            Swift.print("\(vertical)\(String(repeating: " ", count: padding))\(paddedLine)\(String(repeating: " ", count: padding))\(vertical)".cyan)
        }

        // Bottom border
        Swift.print("\(bottomLeft)\(String(repeating: horizontal, count: maxLength + padding * 2))\(bottomRight)".cyan)
    }

    private static func visualLength(_ text: String) -> Int {
        // Calculate the visual length of text, accounting for emojis
        // Emojis typically take 2 character widths in terminal
        var length = 0
        for char in text {
            if char.unicodeScalars.contains(where: { $0.properties.isEmoji }) {
                length += 2
            } else {
                length += 1
            }
        }
        return length
    }

    public static func printRainbow(_ text: String) {
        let colors: [Color] = [.red, .yellow, .green, .cyan, .blue, .magenta]
        let chars = Array(text)

        var output = ""
        for (index, char) in chars.enumerated() {
            let colorIndex = index % colors.count
            switch colors[colorIndex] {
            case .red:
                output += String(char).red
            case .yellow:
                output += String(char).yellow
            case .green:
                output += String(char).green
            case .cyan:
                output += String(char).cyan
            case .blue:
                output += String(char).blue
            case .magenta:
                output += String(char).magenta
            default:
                output += String(char)
            }
        }
        Swift.print(output.bold)
    }

    public static func typewrite(_ text: String, delay: TimeInterval = 0.05) {
        for char in text {
            Swift.print(String(char), terminator: "")
            fflush(stdout)
            Thread.sleep(forTimeInterval: delay)
        }
        Swift.print()
    }

    public enum BoxStyle {
        case sharp
        case rounded
        case double
        case thick

        var characters: (String, String, String, String, String, String) {
            switch self {
            case .sharp:
                return ("┌", "┐", "└", "┘", "─", "│")
            case .rounded:
                return ("╭", "╮", "╰", "╯", "─", "│")
            case .double:
                return ("╔", "╗", "╚", "╝", "═", "║")
            case .thick:
                return ("┏", "┓", "┗", "┛", "━", "┃")
            }
        }
    }
}

// MARK: - String Extensions for Visual Effects

extension String {
    func `repeat`(_ count: Int) -> String {
        return String(repeating: self, count: count)
    }
}