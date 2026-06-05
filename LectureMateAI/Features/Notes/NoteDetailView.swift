//
//  NoteDetailView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI
import SwiftData

struct NoteDetailView: View {
    let note: LectureNote

    var body: some View {
        List {
            Section {
                headerRow
            }

            Section("Note") {
                MarkdownText(markdown: note.markdown)
                    .font(.body)
                    .lineSpacing(4)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !note.flashcards.isEmpty || !note.quizQuestions.isEmpty {
                Section("Review") {
                    if !note.flashcards.isEmpty {
                        NavigationLink {
                            FlashcardReviewView(
                                flashcards: note.flashcards,
                                deckTitle: note.title
                            )
                        } label: {
                            HStack(spacing: 12) {
                                AppIconBadge(
                                    icon: "rectangle.on.rectangle",
                                    tint: AppTheme.flashcards,
                                    size: 36
                                )

                                Text("Flashcards")
                                    .font(.body)

                                Spacer()

                                Text("\(note.flashcards.count)")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }

                    if !note.quizQuestions.isEmpty {
                        NavigationLink {
                            QuizView(questions: note.quizQuestions)
                        } label: {
                            HStack(spacing: 12) {
                                AppIconBadge(
                                    icon: "target",
                                    tint: AppTheme.quiz,
                                    size: 36
                                )

                                Text("Quiz")
                                    .font(.body)

                                Spacer()

                                Text("\(note.quizQuestions.count)")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(note.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerRow: some View {
        HStack(spacing: 12) {
            AppIconBadge(token: AppPalette.noteToken(for: note.title), size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(note.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(note.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// Renders markdown block by block so headings, bullets, and tables keep
// their structure. AttributedString(markdown:) alone collapses blocks into
// a single run of text.
struct MarkdownText: View {
    let markdown: String

    private enum MarkdownBlock: Identifiable {
        case heading(id: Int, level: Int, text: AttributedString)
        case bullet(id: Int, text: AttributedString)
        case paragraph(id: Int, text: AttributedString)
        case table(id: Int, header: [AttributedString], rows: [[AttributedString]])

        var id: Int {
            switch self {
            case .heading(let id, _, _), .bullet(let id, _), .paragraph(let id, _), .table(let id, _, _):
                return id
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(blocks) { block in
                blockView(for: block)
            }
        }
    }

    @ViewBuilder
    private func blockView(for block: MarkdownBlock) -> some View {
        switch block {
        case .heading(_, let level, let text):
            Text(text)
                .font(headingFont(for: level))
                .padding(.top, 4)

        case .bullet(_, let text):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("•")
                Text(text)
            }
            .font(.body)

        case .paragraph(_, let text):
            Text(text)
                .font(.body)
                .lineSpacing(4)

        case .table(_, let header, let rows):
            VStack(alignment: .leading, spacing: 8) {
                tableRow(cells: header, isHeader: true)

                ForEach(rows.indices, id: \.self) { index in
                    Divider()
                    tableRow(cells: rows[index], isHeader: false)
                }
            }
        }
    }

    private func tableRow(cells: [AttributedString], isHeader: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(cells.indices, id: \.self) { index in
                Text(cells[index])
                    .font(isHeader ? .footnote.weight(.semibold) : .footnote)
                    .foregroundStyle(isHeader ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func headingFont(for level: Int) -> Font {
        switch level {
        case 1:
            return .title2.weight(.bold)
        case 2:
            return .title3.weight(.semibold)
        default:
            return .headline
        }
    }

    private var blocks: [MarkdownBlock] {
        var result: [MarkdownBlock] = []
        var paragraphBuffer: [String] = []
        var tableBuffer: [[AttributedString]] = []

        func inline(_ text: String) -> AttributedString {
            let options = AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
            return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
        }

        func flushParagraph() {
            guard !paragraphBuffer.isEmpty else { return }
            result.append(.paragraph(id: result.count, text: inline(paragraphBuffer.joined(separator: " "))))
            paragraphBuffer = []
        }

        func flushTable() {
            guard !tableBuffer.isEmpty else { return }
            let header = tableBuffer[0]
            let rows = Array(tableBuffer.dropFirst())
            result.append(.table(id: result.count, header: header, rows: rows))
            tableBuffer = []
        }

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.isEmpty {
                flushParagraph()
                flushTable()
                continue
            }

            if line.hasPrefix("|") {
                flushParagraph()

                let cells = line
                    .trimmingCharacters(in: CharacterSet(charactersIn: "|"))
                    .components(separatedBy: "|")
                    .map { $0.trimmingCharacters(in: .whitespaces) }

                let isSeparatorRow = cells.allSatisfy { cell in
                    !cell.isEmpty && cell.allSatisfy { $0 == "-" || $0 == ":" }
                }

                if !isSeparatorRow {
                    tableBuffer.append(cells.map(inline))
                }
                continue
            }

            flushTable()

            if line.hasPrefix("#") {
                flushParagraph()
                let level = line.prefix(while: { $0 == "#" }).count
                let text = line.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces)
                result.append(.heading(id: result.count, level: level, text: inline(text)))
                continue
            }

            if line.hasPrefix("- ") || line.hasPrefix("* ") {
                flushParagraph()
                result.append(.bullet(id: result.count, text: inline(String(line.dropFirst(2)))))
                continue
            }

            paragraphBuffer.append(line)
        }

        flushParagraph()
        flushTable()

        return result
    }
}

#Preview {
    NavigationStack {
        NoteDetailView(note: previewLectureNote)
    }
    .modelContainer(for: [
        Course.self,
        LectureNote.self,
        Flashcard.self,
        QuizQuestion.self
    ], inMemory: true)
}

private var previewLectureNote: LectureNote {
    let note = LectureNote(
        title: "Chapter 4 - Sorting",
        markdown: """
        # Chapter 4 - Sorting

        ## 一 本堂課重點摘要
        - 比較 Bubble Sort、Insertion Sort、Merge Sort
        - 說明時間複雜度與空間複雜度

        ## 二 章節式筆記
        排序演算法可以分成穩定排序與不穩定排序，也可以依照是否採用分治法來分類。

        ## 三 專有名詞整理
        | 名詞 | 解釋 | 課堂中的例子 |
        | --- | --- | --- |
        | Time Complexity | 演算法執行時間成長趨勢 | O(n log n) |
        """
    )

    note.flashcards = [
        Flashcard(term: "Stable Sort", definitionText: "排序後相同元素的相對順序保持不變", example: "Merge Sort")
    ]

    note.quizQuestions = [
        QuizQuestion(
            question: "哪一個排序法平均時間複雜度是 O(n log n)？",
            options: ["Bubble Sort", "Selection Sort", "Merge Sort", "Insertion Sort"],
            correctIndex: 2,
            explanation: "Merge Sort 採用分治法，平均與最壞情況都能維持 O(n log n)。"
        )
    ]

    return note
}
