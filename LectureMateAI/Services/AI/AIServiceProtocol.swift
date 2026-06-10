//
//  AIServiceProtocol.swift
//  LectureMateAI
//
//  Created by Gemini CLI on 2026/6/8.
//

import Foundation

protocol AIService {
    func transcribeAudio(
        fileURL: URL,
        onProgress: ((String, Double) -> Void)?
    ) async throws -> String
    
    func generateMarkdownNote(
        lectureTitle: String,
        transcript: String,
        pdfText: String
    ) async throws -> String
}

enum AIBackendMode: String, CaseIterable, Identifiable {
    case cloud = "Cloud (OpenAI)"
    case local = "Local (LiteRT + Gemma 4)"

    var id: String { self.rawValue }

    var description: String {
        switch self {
        case .cloud:
            return "Uses OpenAI API for high-quality transcription and note generation. Requires an internet connection."
        case .local:
            return "Uses on-device Apple Speech framework and Gemma model. Private and works offline."
        }
    }
}
