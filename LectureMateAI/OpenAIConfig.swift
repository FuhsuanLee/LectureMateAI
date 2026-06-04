//
//  OpenAIConfig.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import Foundation

enum OpenAIConfig {
    // Prototype only: paste your local key here for testing, but never commit a real API key to GitHub.
    static let apiKey = ""
    static let noteModel = "gpt-4o-mini"
    static let transcriptionModel = "gpt-4o-mini-transcribe"
    static let temperature = 0.7
    static let language = "繁體中文"
    static let transcriptionLanguageCode = "zh"
}
