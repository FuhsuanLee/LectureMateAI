//
//  CourseDetailView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI

struct CourseDetailView: View {
    let course: Course

    var body: some View {
        List {
            Section("Notes") {
                ForEach(course.notes.sorted(by: { $0.createdAt > $1.createdAt })) { note in
                    NavigationLink {
                        NoteDetailView(note: note)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(note.title)
                                .font(.headline)

                            Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(course.title)
        .toolbar {
            NavigationLink {
                FileImportGenerateView(course: course)
            } label: {
                Image(systemName: "sparkles")
            }
        }
    }
}
