//
//  Secrets.swift
//  LectureMateAI
//

import Foundation

/// Reads values from the bundled, gitignored `Secrets.plist`.
///
/// Copy `Secrets.example.plist` to `Secrets.plist` and fill in real values.
/// Missing file or key yields an empty string, so a fresh clone still builds.
enum Secrets {
    private static let values: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url) as? [String: Any] else { return [:] }
        return dict
    }()

    static func string(_ key: String) -> String {
        values[key] as? String ?? ""
    }
}
