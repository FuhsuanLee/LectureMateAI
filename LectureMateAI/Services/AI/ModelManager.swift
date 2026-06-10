//
//  ModelManager.swift
//  LectureMateAI
//
//  Created by Gemini CLI on 2026/6/8.
//

import Foundation
import SwiftUI
import Combine

enum ModelState: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case error(String)
}

@MainActor
class ModelManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    static let shared = ModelManager()
    
    @Published var gemmaState: ModelState = .notDownloaded
    
    private let modelName = "Gemma 4 E2B (Mobile Optimized)"
    private let modelURL = URL(string: "https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm")!
    
    private var downloadTask: URLSessionDownloadTask?
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    override private init() {
        super.init()
        checkIfModelExists()
    }
    
    func checkIfModelExists() {
        let path = getModelPath()
        if FileManager.default.fileExists(atPath: path.path) {
            gemmaState = .downloaded
        } else {
            gemmaState = .notDownloaded
        }
    }
    
    func downloadModel() {
        guard downloadTask == nil else { return }
        
        gemmaState = .downloading(progress: 0.0)
        
        // We use a URLRequest to potentially add headers if needed by Kaggle/HuggingFace
        var request = URLRequest(url: modelURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        downloadTask = urlSession.downloadTask(with: request)
        downloadTask?.resume()
    }
    
    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        gemmaState = .notDownloaded
    }
    
    func deleteModel() {
        let path = getModelPath()
        try? FileManager.default.removeItem(at: path)
        gemmaState = .notDownloaded
    }
    
    var modelPath: URL {
        getModelPath()
    }
    
    private func getModelPath() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("gemma-2b-it-gpu-int4.bin")
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let destinationURL = getModelPath()
        
        try? FileManager.default.removeItem(at: destinationURL)
        
        do {
            try FileManager.default.moveItem(at: location, to: destinationURL)
            Task { @MainActor in
                self.gemmaState = .downloaded
                self.downloadTask = nil
            }
        } catch {
            Task { @MainActor in
                self.gemmaState = .error("Failed to save model: \(error.localizedDescription)")
                self.downloadTask = nil
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        Task { @MainActor in
            self.gemmaState = .downloading(progress: progress)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            Task { @MainActor in
                if (error as NSError).code != NSURLErrorCancelled {
                    self.gemmaState = .error(error.localizedDescription)
                }
                self.downloadTask = nil
            }
        }
    }
}

extension ModelState {
    static func == (lhs: ModelState, rhs: ModelState) -> Bool {
        switch (lhs, rhs) {
        case (.notDownloaded, .notDownloaded): return true
        case (.downloaded, .downloaded): return true
        case (.downloading(let p1), .downloading(let p2)): return p1 == p2
        case (.error(let e1), .error(let e2)): return e1 == e2
        default: return false
        }
    }
}
