import Foundation
import Rainbow

extension Console {

    public enum TableAlignment {
        case left
        case center
        case right
    }

    public struct TableColumn {
        let header: String
        let width: Int?
        let alignment: TableAlignment
        let color: Color?

        public init(header: String, width: Int? = nil, alignment: TableAlignment = .left, color: Color? = nil) {
            self.header = header
            self.width = width
            self.alignment = alignment
            self.color = color
        }
    }

    public struct TableRow {
        let cells: [String]
        let style: RowStyle?
        let isSelected: Bool

        public init(cells: [String], style: RowStyle? = nil, isSelected: Bool = false) {
            self.cells = cells
            self.style = style
            self.isSelected = isSelected
        }
    }

    public enum RowStyle {
        case normal
        case highlight
        case warning
        case success
        case separator
        case header
    }

    private struct TableChars {
        // Box drawing characters for tables
        static let topLeft = "╔"
        static let topRight = "╗"
        static let bottomLeft = "╚"
        static let bottomRight = "╝"
        static let horizontal = "═"
        static let vertical = "║"
        static let cross = "╬"
        static let topT = "╦"
        static let bottomT = "╩"
        static let leftT = "╠"
        static let rightT = "╣"

        // Light variants for separators
        static let lightHorizontal = "─"
        static let lightVertical = "│"
        static let lightCross = "┼"
        static let lightLeftT = "├"
        static let lightRightT = "┤"
    }

    public static func printTable(
        columns: [TableColumn],
        rows: [TableRow],
        title: String? = nil,
        showIndex: Bool = true
    ) {
        // Calculate column widths
        var columnWidths = calculateColumnWidths(columns: columns, rows: rows, showIndex: showIndex)

        // Adjust for title if needed
        if let title = title {
            let totalWidth = columnWidths.reduce(0, +) + (columnWidths.count - 1) * 3 + (showIndex ? 4 : 0)
            let titleLength = visualLength(title) + 4 // Adding padding
            if titleLength > totalWidth {
                let extraWidth = titleLength - totalWidth
                let perColumn = extraWidth / columnWidths.count
                columnWidths = columnWidths.map { $0 + perColumn }
            }
        }

        // Print top border with title
        if let title = title {
            printTableTitle(title: title, columnWidths: columnWidths, showIndex: showIndex)
        } else {
            printTableTopBorder(columnWidths: columnWidths, showIndex: showIndex)
        }

        // Print headers
        printTableHeaders(columns: columns, columnWidths: columnWidths, showIndex: showIndex)

        // Print separator after headers
        printTableSeparator(columnWidths: columnWidths, showIndex: showIndex, style: .header)

        // Group rows by style for visual separation
        var previousStyle: RowStyle? = nil

        for (index, row) in rows.enumerated() {
            // Add separator between different row styles
            if let prevStyle = previousStyle,
               let currentStyle = row.style,
               prevStyle != currentStyle && currentStyle != .normal {
                printTableSeparator(columnWidths: columnWidths, showIndex: showIndex, style: .light)
            }

            printTableRow(
                row: row,
                columns: columns,
                columnWidths: columnWidths,
                showIndex: showIndex,
                index: index + 1
            )

            previousStyle = row.style
        }

        // Print bottom border
        printTableBottomBorder(columnWidths: columnWidths, showIndex: showIndex)
    }

    private static func calculateColumnWidths(
        columns: [TableColumn],
        rows: [TableRow],
        showIndex: Bool
    ) -> [Int] {
        var widths: [Int] = []

        for (i, column) in columns.enumerated() {
            // Start with header width or specified width
            var maxWidth = column.width ?? visualLength(column.header)

            // Check all row cells for this column
            for row in rows {
                if i < row.cells.count {
                    let cellWidth = visualLength(row.cells[i])
                    maxWidth = max(maxWidth, cellWidth)
                }
            }

            // Add some padding
            widths.append(min(maxWidth + 2, 40)) // Cap at 40 chars per column
        }

        return widths
    }

    private static func printTableTitle(title: String, columnWidths: [Int], showIndex: Bool) {
        let totalWidth = columnWidths.reduce(0, +) + (columnWidths.count - 1) * 3 + (showIndex ? 7 : 2)

        var line = TableChars.topLeft
        line += String(repeating: TableChars.horizontal, count: totalWidth - 2)
        line += TableChars.topRight
        Swift.print(line.cyan)

        // Print title line
        let paddedTitle = " \(title) "
        let titleLength = visualLength(paddedTitle)
        let leftPadding = (totalWidth - 2 - titleLength) / 2
        let rightPadding = totalWidth - 2 - titleLength - leftPadding

        var titleLine = TableChars.vertical
        titleLine += String(repeating: " ", count: leftPadding)
        titleLine += paddedTitle
        titleLine += String(repeating: " ", count: rightPadding)
        titleLine += TableChars.vertical
        Swift.print(titleLine.cyan.bold)
    }

    private static func printTableTopBorder(columnWidths: [Int], showIndex: Bool) {
        var line = TableChars.topLeft

        if showIndex {
            line += String(repeating: TableChars.horizontal, count: 3)
            line += TableChars.topT
        }

        for (i, width) in columnWidths.enumerated() {
            line += String(repeating: TableChars.horizontal, count: width)
            if i < columnWidths.count - 1 {
                line += TableChars.topT
            }
        }

        line += TableChars.topRight
        Swift.print(line.cyan)
    }

    private static func printTableHeaders(
        columns: [TableColumn],
        columnWidths: [Int],
        showIndex: Bool
    ) {
        var line = TableChars.vertical

        if showIndex {
            line += " # "
            line += TableChars.vertical
        }

        for (i, column) in columns.enumerated() {
            let width = columnWidths[i]
            let paddedHeader = alignText(column.header, width: width, alignment: column.alignment)
            line += paddedHeader.bold

            if i < columns.count - 1 {
                line += TableChars.vertical
            }
        }

        line += TableChars.vertical
        Swift.print(line.cyan)
    }

    private static func printTableSeparator(
        columnWidths: [Int],
        showIndex: Bool,
        style: SeparatorStyle = .normal
    ) {
        let (left, mid, right, horizontal) = style == .header
            ? (TableChars.leftT, TableChars.cross, TableChars.rightT, TableChars.horizontal)
            : (TableChars.lightLeftT, TableChars.lightCross, TableChars.lightRightT, TableChars.lightHorizontal)

        var line = left

        if showIndex {
            line += String(repeating: horizontal, count: 3)
            line += mid
        }

        for (i, width) in columnWidths.enumerated() {
            line += String(repeating: horizontal, count: width)
            if i < columnWidths.count - 1 {
                line += mid
            }
        }

        line += right
        Swift.print(line.cyan)
    }

    private static func printTableRow(
        row: TableRow,
        columns: [TableColumn],
        columnWidths: [Int],
        showIndex: Bool,
        index: Int
    ) {
        var line = TableChars.vertical

        if showIndex {
            let indexStr = row.isSelected ? "[✓]" : String(format: "%2d ", index)
            line += indexStr
            line += TableChars.vertical
        }

        for (i, cell) in row.cells.enumerated() {
            if i < columns.count {
                let width = columnWidths[i]
                let column = columns[i]
                let alignedText = alignText(cell, width: width, alignment: column.alignment)

                // Apply styling based on row style
                let styledText = applyRowStyle(alignedText, style: row.style, columnColor: column.color)
                line += styledText

                if i < columns.count - 1 {
                    line += TableChars.vertical
                }
            }
        }

        line += TableChars.vertical
        Swift.print(line.cyan)
    }

    private static func printTableBottomBorder(columnWidths: [Int], showIndex: Bool) {
        var line = TableChars.bottomLeft

        if showIndex {
            line += String(repeating: TableChars.horizontal, count: 3)
            line += TableChars.bottomT
        }

        for (i, width) in columnWidths.enumerated() {
            line += String(repeating: TableChars.horizontal, count: width)
            if i < columnWidths.count - 1 {
                line += TableChars.bottomT
            }
        }

        line += TableChars.bottomRight
        Swift.print(line.cyan)
    }

    private static func alignText(_ text: String, width: Int, alignment: TableAlignment) -> String {
        let textLength = visualLength(text)

        if textLength >= width {
            // Truncate with ellipsis if too long
            if width > 3 && textLength > width {
                let truncated = String(text.prefix(width - 3))
                return truncated + "..."
            }
            return String(text.prefix(width))
        }

        let padding = width - textLength

        switch alignment {
        case .left:
            return text + String(repeating: " ", count: padding)
        case .right:
            return String(repeating: " ", count: padding) + text
        case .center:
            let leftPad = padding / 2
            let rightPad = padding - leftPad
            return String(repeating: " ", count: leftPad) + text + String(repeating: " ", count: rightPad)
        }
    }

    private static func applyRowStyle(_ text: String, style: RowStyle?, columnColor: Color?) -> String {
        if let color = columnColor {
            return text.applyingColor(color)
        }

        guard let style = style else { return text }

        switch style {
        case .normal:
            return text
        case .highlight:
            return text.cyan.bold
        case .warning:
            return text.yellow
        case .success:
            return text.green
        case .separator, .header:
            return text.bold
        }
    }

    private enum SeparatorStyle {
        case normal
        case light
        case header
    }
}

private extension String {
    func applyingColor(_ color: Color) -> String {
        switch color {
        case .black: return self.black
        case .red: return self.red
        case .green: return self.green
        case .yellow: return self.yellow
        case .blue: return self.blue
        case .magenta: return self.magenta
        case .cyan: return self.cyan
        case .white: return self.white
        case .lightBlack: return self.lightBlack
        case .lightRed: return self.lightRed
        case .lightGreen: return self.lightGreen
        case .lightYellow: return self.lightYellow
        case .lightBlue: return self.lightBlue
        case .lightMagenta: return self.lightMagenta
        case .lightCyan: return self.lightCyan
        case .lightWhite: return self.lightWhite
        default: return self
        }
    }
}