//
//  MarkdownRenderer.swift
//  LectureMateAI
//
//  Block-level markdown renderer for AI-generated notes.
//  SwiftUI's AttributedString(markdown:) only parses inline syntax, so headings,
//  lists, and tables collapse into one paragraph. This renderer splits the raw
//  markdown into typed blocks and styles each with AppTheme tokens.
//

import SwiftUI

enum MarkdownBlock: Identifiable {
    case heading(level: Int, text: String)
    case bulleted([String])
    case numbered([(marker: String, text: String)])
    case table(header: [String], rows: [[String]])
    case code([String])
    case paragraph(String)

    var id: String {
        switch self {
        case let .heading(level, text):
            return "h\(level)-\(text)"
        case let .bulleted(items):
            return "ul-\(items.joined(separator: "|"))"
        case let .numbered(items):
            return "ol-\(items.map(\.text).joined(separator: "|"))"
        case let .table(header, rows):
            return "tb-\(header.joined(separator: "|"))-\(rows.count)"
        case let .code(lines):
            return "code-\(lines.joined(separator: "|"))"
        case let .paragraph(text):
            return "p-\(text)"
        }
    }
}

enum MarkdownParser {
    static func parse(_ markdown: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = markdown.components(separatedBy: .newlines)

        var paragraphBuffer: [String] = []
        var bulletBuffer: [String] = []
        var numberBuffer: [(marker: String, text: String)] = []

        func flushParagraph() {
            guard !paragraphBuffer.isEmpty else { return }
            blocks.append(.paragraph(paragraphBuffer.joined(separator: " ")))
            paragraphBuffer.removeAll()
        }

        func flushBullets() {
            guard !bulletBuffer.isEmpty else { return }
            blocks.append(.bulleted(bulletBuffer))
            bulletBuffer.removeAll()
        }

        func flushNumbers() {
            guard !numberBuffer.isEmpty else { return }
            blocks.append(.numbered(numberBuffer))
            numberBuffer.removeAll()
        }

        func flushAll() {
            flushParagraph()
            flushBullets()
            flushNumbers()
        }

        var index = 0
        while index < lines.count {
            let rawLine = lines[index]
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            // Blank line — flush everything that depends on adjacency.
            if line.isEmpty {
                flushAll()
                index += 1
                continue
            }

            // Fenced code block.
            if line.hasPrefix("```") {
                flushAll()
                var codeLines: [String] = []
                index += 1
                while index < lines.count,
                      !lines[index].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[index])
                    index += 1
                }
                blocks.append(.code(codeLines))
                index += 1 // skip closing fence
                continue
            }

            // Heading.
            if let heading = parseHeading(line) {
                flushAll()
                blocks.append(heading)
                index += 1
                continue
            }

            // Table — a pipe row immediately followed by a separator row.
            if isTableRow(line),
               index + 1 < lines.count,
               isTableSeparator(lines[index + 1].trimmingCharacters(in: .whitespaces)) {
                flushAll()
                let header = tableCells(line)
                var rows: [[String]] = []
                index += 2 // consume header + separator
                while index < lines.count {
                    let next = lines[index].trimmingCharacters(in: .whitespaces)
                    guard isTableRow(next) else { break }
                    rows.append(tableCells(next))
                    index += 1
                }
                blocks.append(.table(header: header, rows: rows))
                continue
            }

            // Bullet list item.
            if let bullet = parseBullet(line) {
                flushParagraph()
                flushNumbers()
                bulletBuffer.append(bullet)
                index += 1
                continue
            }

            // Numbered list item.
            if let numbered = parseNumbered(line) {
                flushParagraph()
                flushBullets()
                numberBuffer.append(numbered)
                index += 1
                continue
            }

            // Plain paragraph text — flush adjacent lists, accumulate.
            flushBullets()
            flushNumbers()
            paragraphBuffer.append(line)
            index += 1
        }

        flushAll()
        return blocks
    }

    private static func parseHeading(_ line: String) -> MarkdownBlock? {
        guard line.hasPrefix("#") else { return nil }
        var level = 0
        var remainder = Substring(line)
        while remainder.first == "#" {
            level += 1
            remainder = remainder.dropFirst()
        }
        guard level <= 6, remainder.first == " " else { return nil }
        let text = remainder.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }
        return .heading(level: level, text: text)
    }

    private static func parseBullet(_ line: String) -> String? {
        for marker in ["- ", "* ", "• ", "> "] where line.hasPrefix(marker) {
            return String(line.dropFirst(marker.count)).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    private static func parseNumbered(_ line: String) -> (marker: String, text: String)? {
        // Match a leading run of digits followed by "." or ")".
        var digits = ""
        var rest = Substring(line)
        while let first = rest.first, first.isNumber {
            digits.append(first)
            rest = rest.dropFirst()
        }
        guard !digits.isEmpty, let sep = rest.first, sep == "." || sep == ")" else { return nil }
        rest = rest.dropFirst()
        guard rest.first == " " else { return nil }
        return (marker: digits, text: rest.trimmingCharacters(in: .whitespaces))
    }

    private static func isTableRow(_ line: String) -> Bool {
        line.hasPrefix("|") && line.dropFirst().contains("|")
    }

    private static func isTableSeparator(_ line: String) -> Bool {
        guard isTableRow(line) else { return false }
        let cells = tableCells(line)
        guard !cells.isEmpty else { return false }
        return cells.allSatisfy { cell in
            !cell.isEmpty && cell.allSatisfy { $0 == "-" || $0 == ":" || $0 == " " }
        }
    }

    private static func tableCells(_ line: String) -> [String] {
        var trimmed = Substring(line)
        if trimmed.hasPrefix("|") { trimmed = trimmed.dropFirst() }
        if trimmed.hasSuffix("|") { trimmed = trimmed.dropLast() }
        return trimmed
            .components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }
}

struct MarkdownContent: View {
    let markdown: String

    private var blocks: [MarkdownBlock] {
        MarkdownParser.parse(markdown)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(blocks) { block in
                view(for: block)
            }
        }
    }

    @ViewBuilder
    private func view(for block: MarkdownBlock) -> some View {
        switch block {
        case let .heading(level, text):
            headingView(level: level, text: text)
        case let .bulleted(items):
            bulletedView(items)
        case let .numbered(items):
            numberedView(items)
        case let .table(header, rows):
            MarkdownTableView(header: header, rows: rows)
        case let .code(lines):
            codeView(lines)
        case let .paragraph(text):
            Text(inlineAttributed(text))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func headingView(level: Int, text: String) -> some View {
        let attributed = inlineAttributed(text)
        switch level {
        case 1:
            Text(attributed)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .padding(.top, 2)
        case 2:
            VStack(alignment: .leading, spacing: 10) {
                Rectangle()
                    .fill(AppTheme.cardBorder)
                    .frame(height: 1)
                Text(attributed)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
            }
            .padding(.top, 4)
        default:
            Text(attributed)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private func bulletedView(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Circle()
                        .fill(AppTheme.blue)
                        .frame(width: 5, height: 5)
                        .offset(y: -3)
                    Text(inlineAttributed(item))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func numberedView(_ items: [(marker: String, text: String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(item.marker).")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.blue)
                    Text(inlineAttributed(item.text))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func codeView(_ lines: [String]) -> some View {
        Text(lines.joined(separator: "\n"))
            .font(.system(size: 14, weight: .regular, design: .monospaced))
            .foregroundStyle(AppTheme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.86))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppTheme.cardBorder, lineWidth: 1)
                    )
            )
    }
}

private struct MarkdownTableView: View {
    let header: [String]
    let rows: [[String]]

    private var columnCount: Int {
        max(header.count, rows.map(\.count).max() ?? 0)
    }

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                ForEach(0..<columnCount, id: \.self) { column in
                    cell(text: value(header, column), isHeader: true)
                }
            }
            .background(AppTheme.blue.opacity(0.12))

            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                Divider().overlay(AppTheme.cardBorder)
                GridRow {
                    ForEach(0..<columnCount, id: \.self) { column in
                        cell(text: value(row, column), isHeader: false)
                    }
                }
                .background(rowIndex.isMultiple(of: 2) ? Color.clear : AppTheme.cardFill.opacity(0.5))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }

    private func value(_ cells: [String], _ column: Int) -> String {
        column < cells.count ? cells[column] : ""
    }

    private func cell(text: String, isHeader: Bool) -> some View {
        Text(text)
            .font(.system(size: 14, weight: isHeader ? .bold : .medium, design: .rounded))
            .foregroundStyle(isHeader ? AppTheme.ink : AppTheme.ink.opacity(0.9))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
    }
}

/// Renders inline markdown (`**bold**`, `*italic*`, `` `code` ``) within a single
/// block without interpreting block-level syntax. Falls back to raw text on failure.
private func inlineAttributed(_ text: String) -> AttributedString {
    let options = AttributedString.MarkdownParsingOptions(
        interpretedSyntax: .inlineOnlyPreservingWhitespace
    )
    if let attributed = try? AttributedString(markdown: text, options: options) {
        return attributed
    }
    return AttributedString(text)
}

#Preview {
    ScrollView {
        MarkdownContent(markdown: """
        # Chapter 4 - Sorting

        ## 一 本堂課重點摘要
        - 比較 **Bubble Sort**、Insertion Sort、Merge Sort
        - 說明時間複雜度與空間複雜度

        ## 二 章節式筆記
        排序演算法可以分成穩定排序與不穩定排序。

        1. 第一步說明 `compare`
        2. 第二步說明 swap

        ## 三 專有名詞整理
        | 名詞 | 解釋 | 課堂中的例子 |
        | --- | --- | --- |
        | Time Complexity | 演算法執行時間成長趨勢 | O(n log n) |
        | Stable Sort | 相同元素相對順序不變 | Merge Sort |
        """)
        .padding(20)
        .appCard(cornerRadius: 30)
        .padding(20)
    }
    .background(AppTheme.pageGradient)
}
