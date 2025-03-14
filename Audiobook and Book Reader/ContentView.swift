//
//  ContentView.swift
//  Audiobook and Book Reader
//
//  Created by Alex4810 on 3/11/25.
//

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var audioPlayer: AVAudioPlayer?
    @State private var selectedFileURL: URL?
    @State private var showingFilePicker = false
    @State private var isPlaying = false

    var body: some View {
        VStack {
            Text("Audiobook Player")
                .font(.largeTitle)
                .bold()
                .padding()
            
            if let fileURL = selectedFileURL {
                Text("Selected: \(fileURL.lastPathComponent)")
                    .font(.headline)
                    .padding()
            } else {
                Text("No audiobook selected")
                    .foregroundStyle(.gray)
            }

            HStack {
                Button("Select Audiobook") {
                    showingFilePicker = true
                }
                .buttonStyle(.borderedProminent)
                
                Button(isPlaying ? "Pause" : "Play") {
                    togglePlayback()
                }
                .buttonStyle(.bordered)
                .disabled(selectedFileURL == nil)
            }
            .padding()
        }
        .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [UTType.audio]) { result in
            handleFileSelection(result)
        }
    }

    func handleFileSelection(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            requestAccessAndCopyFile(originalURL: url)
        case .failure(let error):
            print("File selection error: \(error.localizedDescription)")
        }
    }

    func requestAccessAndCopyFile(originalURL: URL) {
        let fileManager = FileManager.default
        let destinationURL = getAppSupportDirectory().appendingPathComponent(originalURL.lastPathComponent)

        // Start security-scoped access
        if originalURL.startAccessingSecurityScopedResource() {
            defer { originalURL.stopAccessingSecurityScopedResource() } // Stop access when done

            do {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL) // Remove existing file
                }
                try fileManager.copyItem(at: originalURL, to: destinationURL)
                selectedFileURL = destinationURL
                prepareAudioPlayer()
            } catch {
                print("Error copying file: \(error.localizedDescription)")
            }
        } else {
            print("Failed to get access to file at \(originalURL.path)")
        }
    }

    func prepareAudioPlayer() {
        guard let fileURL = selectedFileURL else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Error loading audio file: \(error.localizedDescription)")
        }
    }

    func togglePlayback() {
        guard let player = audioPlayer else { return }
        
        if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    /// Returns the correct app storage directory (macOS & iOS safe)
    func getAppSupportDirectory() -> URL {
        let fileManager = FileManager.default
        do {
            let cachesURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let appDirectory = cachesURL.appendingPathComponent("AudiobookPlayer", isDirectory: true)

            if !fileManager.fileExists(atPath: appDirectory.path) {
                try fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            
            return appDirectory
        } catch {
            fatalError("Could not access or create Caches subdirectory: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
}
