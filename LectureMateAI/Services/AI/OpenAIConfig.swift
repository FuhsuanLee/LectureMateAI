//
//  OpenAIConfig.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import Foundation

enum OpenAIConfig {
    // Read at runtime from a bundled, gitignored Secrets.plist
    // (see Secrets.example.plist). Never hardcode a real API key.
    static let apiKey = Secrets.string("OpenAIApiKey")
    static let noteModel = "gpt-4o-mini"
    static let transcriptionModel = "gpt-4o-mini-transcribe"
    static let temperature = 0.7
    static let language = "繁體中文"
    static let transcriptionLanguageCode = "zh"
}
