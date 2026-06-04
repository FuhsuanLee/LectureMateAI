//
//  MockAIService.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import Foundation

struct AIGeneratedResult {
    let markdown: String
    let flashcards: [Flashcard]
    let quizQuestions: [QuizQuestion]
}

struct MockAIService {
    static func generateNote(
        lectureTitle: String,
        transcript: String,
        slideText: String
    ) -> AIGeneratedResult {

        let markdown = """
        # \(lectureTitle)

        ## 1. Lecture Summary
        This lecture introduces important concepts from the transcript and slide content.

        ## 2. Key Points
        - AI can help students transform lecture recordings into structured notes.
        - Markdown notes are useful for future review.
        - Flashcards help students memorize important terminology.
        - Quizzes help students check their understanding.
        - A dashboard can track learning progress over time.

        ## 3. Important Terms
        - Markdown Note
        - Flashcard
        - Quiz
        - Learning Dashboard
        - AI Study Assistant

        ## 4. Exam Review
        Students should focus on understanding how AI-generated notes can support learning and review.
        """

        let flashcards = [
            Flashcard(
                term: "Markdown Note",
                definitionText: "A structured note format that uses simple symbols to organize headings, lists, and content.",
                example: "# Title, ## Section, - Bullet point"
            ),
            Flashcard(
                term: "Flashcard",
                definitionText: "A learning card that shows a term on one side and its explanation on the other side.",
                example: "Term: Page Fault. Back: An event when a page is not in memory."
            ),
            Flashcard(
                term: "Quiz",
                definitionText: "A short test used to check whether the learner understands the study material.",
                example: "Multiple choice questions generated from lecture notes."
            )
        ]

        let quizQuestions = [
            QuizQuestion(
                question: "What is the main purpose of this app?",
                options: [
                    "To edit photos",
                    "To generate AI lecture notes and review materials",
                    "To play music",
                    "To manage shopping lists"
                ],
                correctIndex: 1,
                explanation: "The app helps students generate notes, flashcards, and quizzes from lecture content."
            ),
            QuizQuestion(
                question: "Which feature helps users memorize important terms?",
                options: [
                    "Dashboard",
                    "Flashcards",
                    "Login page",
                    "Settings page"
                ],
                correctIndex: 1,
                explanation: "Flashcards are designed for memorizing terms and definitions."
            )
        ]

        return AIGeneratedResult(
            markdown: markdown,
            flashcards: flashcards,
            quizQuestions: quizQuestions
        )
    }
}
