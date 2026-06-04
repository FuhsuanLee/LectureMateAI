//
//  Models.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import Foundation
import SwiftData

@Model
class Course {
    var title: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var notes: [LectureNote]

    init(title: String) {
        self.title = title
        self.createdAt = Date()
        self.notes = []
    }
}

@Model
class LectureNote {
    var title: String
    var markdown: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var flashcards: [Flashcard]

    @Relationship(deleteRule: .cascade)
    var quizQuestions: [QuizQuestion]

    init(title: String, markdown: String) {
        self.title = title
        self.markdown = markdown
        self.createdAt = Date()
        self.flashcards = []
        self.quizQuestions = []
    }
}

@Model
class Flashcard {
    var term: String
    var definitionText: String
    var example: String

    init(term: String, definitionText: String, example: String) {
        self.term = term
        self.definitionText = definitionText
        self.example = example
    }
}

@Model
class QuizQuestion {
    var question: String
    var options: [String]
    var correctIndex: Int
    var explanation: String
    var selectedIndex: Int?

    init(question: String, options: [String], correctIndex: Int, explanation: String) {
        self.question = question
        self.options = options
        self.correctIndex = correctIndex
        self.explanation = explanation
        self.selectedIndex = nil
    }

    var isAnswered: Bool {
        selectedIndex != nil
    }

    var isCorrect: Bool {
        selectedIndex == correctIndex
    }
}
