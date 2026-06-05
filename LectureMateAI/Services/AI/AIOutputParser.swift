//
//  AIOutputParser.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/5.
//

import Foundation

enum AIOutputParser {
    static func parseFlashcards(from markdown: String) -> [Flashcard] {
        let parsedFlashcards = parseFlashcardsSection(from: markdown)

        if !parsedFlashcards.isEmpty {
            return deduplicated(parsedFlashcards)
        }

        return deduplicated(parseTerminologyTable(from: markdown))
    }

    private static func parseFlashcardsSection(from markdown: String) -> [Flashcard] {
        guard let section = extractSection(
            from: markdown,
            matching: [
                "## 五 Flashcards",
                "## 5 Flashcards",
                "## 五 Flashcard",
                "## 5 Flashcard"
            ]
        ) else {
            return []
        }

        var flashcards: [Flashcard] = []
        var currentQuestion: String?
        var currentAnswer: String?
        var currentExample: String?

        func flushCard() {
            let question = currentQuestion?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let answer = currentAnswer?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let example = currentExample?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard !question.isEmpty, !answer.isEmpty else { return }

            flashcards.append(
                Flashcard(
                    term: question,
                    definitionText: answer,
                    example: example
                )
            )
        }

        for rawLine in section.components(separatedBy: .newlines) {
            let line = normalizedLine(rawLine)
            guard !line.isEmpty else { continue }

            if let value = value(in: line, for: ["Q:", "Q：", "Question:", "Question："]) {
                if currentQuestion != nil || currentAnswer != nil || currentExample != nil {
                    flushCard()
                    currentQuestion = nil
                    currentAnswer = nil
                    currentExample = nil
                }

                currentQuestion = value
                continue
            }

            if let value = value(in: line, for: ["A:", "A：", "Answer:", "Answer："]) {
                currentAnswer = appendedValue(currentAnswer, with: value)
                continue
            }

            if let value = value(in: line, for: ["Example:", "Example：", "例子:", "例子：", "範例:", "範例："]) {
                currentExample = appendedValue(currentExample, with: value)
                continue
            }

            if currentExample != nil {
                currentExample = appendedValue(currentExample, with: line)
            } else if currentAnswer != nil {
                currentAnswer = appendedValue(currentAnswer, with: line)
            } else if currentQuestion != nil {
                currentQuestion = appendedValue(currentQuestion, with: line)
            }
        }

        if currentQuestion != nil || currentAnswer != nil || currentExample != nil {
            flushCard()
        }

        return flashcards
    }

    private static func parseTerminologyTable(from markdown: String) -> [Flashcard] {
        guard let section = extractSection(
            from: markdown,
            matching: [
                "## 三 專有名詞整理",
                "## 3 專有名詞整理"
            ]
        ) else {
            return []
        }

        var flashcards: [Flashcard] = []

        for rawLine in section.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)

            guard line.contains("|"), !line.contains("---") else { continue }

            let columns = line
                .split(separator: "|")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            guard columns.count >= 3 else { continue }
            guard columns[0] != "名詞", columns[1] != "解釋" else { continue }

            flashcards.append(
                Flashcard(
                    term: columns[0],
                    definitionText: columns[1],
                    example: columns[2]
                )
            )
        }

        return flashcards
    }

    private static func extractSection(from markdown: String, matching headings: [String]) -> String? {
        let lines = markdown.components(separatedBy: .newlines)

        guard let startIndex = lines.firstIndex(where: { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            return headings.contains(trimmed)
        }) else {
            return nil
        }

        let remainingLines = lines[(startIndex + 1)...]
        let endIndex = remainingLines.firstIndex(where: {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("## ")
        }) ?? lines.endIndex

        return lines[(startIndex + 1)..<endIndex].joined(separator: "\n")
    }

    private static func normalizedLine(_ rawLine: String) -> String {
        var line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)

        while line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("• ") || line.hasPrefix("> ") {
            line = String(line.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        line = line.replacingOccurrences(of: "**", with: "")
        line = line.replacingOccurrences(of: "__", with: "")
        line = line.replacingOccurrences(of: "`", with: "")

        return line.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func value(in line: String, for prefixes: [String]) -> String? {
        for prefix in prefixes where line.hasPrefix(prefix) {
            let value = String(line.dropFirst(prefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !value.isEmpty {
                return value
            }
        }

        return nil
    }

    private static func appendedValue(_ existing: String?, with newValue: String) -> String {
        guard let existing, !existing.isEmpty else {
            return newValue
        }

        return "\(existing) \(newValue)"
    }

    private static func deduplicated(_ flashcards: [Flashcard]) -> [Flashcard] {
        var seenTerms: Set<String> = []
        var results: [Flashcard] = []

        for flashcard in flashcards {
            let normalizedTerm = flashcard.term
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            guard !normalizedTerm.isEmpty else { continue }
            guard !seenTerms.contains(normalizedTerm) else { continue }

            seenTerms.insert(normalizedTerm)
            results.append(flashcard)
        }

        return results
    }
}
