//
//  Tips.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI
import TipKit

struct GenerateNoteTip: Tip {
    var title: Text {
        Text("Generate AI Notes")
    }

    var message: Text? {
        Text("Paste your lecture transcript and slide content, then generate structured study notes.")
    }

    var image: Image? {
        Image(systemName: "sparkles")
    }
}

struct FlashcardTip: Tip {
    var title: Text {
        Text("Review with Flashcards")
    }

    var message: Text? {
        Text("Tap the card to flip it and check the definition.")
    }

    var image: Image? {
        Image(systemName: "rectangle.on.rectangle")
    }
}
