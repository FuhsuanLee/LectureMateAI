//
//  OpenAIResponseModels.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import Foundation

struct TranscriptionResponse: Codable {
    let text: String
}

struct ResponsesRequest: Codable {
    let model: String
    let instructions: String
    let temperature: Double
    let input: String
}

struct ResponsesResponse: Codable {
    let output: [ResponseOutput]?
    let outputTextValue: String?

    enum CodingKeys: String, CodingKey {
        case output
        case outputTextValue = "output_text"
    }

    var outputText: String? {
        if let outputTextValue,
           !outputTextValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return outputTextValue
        }

        let flattenedText = output?
            .flatMap { $0.content ?? [] }
            .compactMap { $0.text }
            .joined(separator: "\n")

        guard let flattenedText else {
            return nil
        }

        let trimmed = flattenedText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct ResponseOutput: Codable {
    let content: [ResponseOutputContent]?
}

struct ResponseOutputContent: Codable {
    let type: String?
    let text: String?
}

struct OpenAIAPIErrorResponse: Codable {
    let error: OpenAIAPIErrorBody
}

struct OpenAIAPIErrorBody: Codable {
    let message: String
}
