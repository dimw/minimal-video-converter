import SwiftUI
import UniformTypeIdentifiers
import AVFoundation
import AppKit

let knownFfmpegPaths = [
    "/opt/homebrew/bin/ffmpeg", // Apple Silicon (brew)
    "/usr/local/bin/ffmpeg",    // Intel (brew)
    "/usr/bin/ffmpeg"           // System (rare)
]

struct ContentView: View {
    
    @State private var isImporterPresented = false
    @State private var selectedFileURL: URL?
    @State private var exportStatus: String = "No export yet"
    @State private var selectedFormat: ExportFormat = .h264
    @State private var removeAudio: Bool = false
    @State private var resolution: ResolutionScale = .full
    @State private var speed: PlaybackSpeed = .x1
    @State var isDraggingOver = false
    @State var isExporting: Bool = false
    @State private var exportProgress: Double = 0.0
    @State private var runningProcess: Process?
    
    var body: some View {
        ZStack {
            
            Color.clear
                    .contentShape(Rectangle()) // makes the whole area hittable
                    .onDrop(of: [.fileURL], isTargeted: $isDraggingOver) { providers in
                        handleDrop(providers: providers)
                    }
            
            VStack {
                
                Button(action: {
                    isImporterPresented = true
                }) {
                    VStack {
                        Image(systemName: "folder")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                        Text("Select a video file...")
                    }
                    .padding()
                }
                
                Text(selectedFileURL?.lastPathComponent ?? "No file selected")
                    .foregroundStyle(selectedFileURL == nil ? .secondary : .primary)
                    .padding()
                    .fileImporter(
                        isPresented: $isImporterPresented,
                        allowedContentTypes: [.movie], // Only allow video files
                        allowsMultipleSelection: false
                    ) { result in
                        switch result {
                        case .success(let urls):
                            if let url = urls.first {
                                selectedFileURL = url
                            }
                            print(
                                "Selected file: \(selectedFileURL?.absoluteString ?? "None")"
                            )
                        case .failure(let error):
                            print(
                                "Failed to import file: \(error.localizedDescription)"
                            )
                        }
                    }
                
                Picker("Export Format", selection: $selectedFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                            .padding(.horizontal, 8)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, 8)

                Picker("Resolution", selection: $resolution) {
                    ForEach(ResolutionScale.allCases) { scale in
                        Text(scale.rawValue).tag(scale)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, 8)

                Picker("Speed", selection: $speed) {
                    ForEach(PlaybackSpeed.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, 8)

                Toggle("Remove audio", isOn: $removeAudio)
                    .toggleStyle(.checkbox)
                    .padding(.bottom, 12)

                Button(action: {
                    if isExporting {
                        runningProcess?.terminate()
                    } else if let url = selectedFileURL {
                        Task {
                            await convertVideoWithFFmpeg(for: url, exportFormat: selectedFormat, removeAudio: removeAudio, resolution: resolution, speed: speed)
                        }
                    }
                }) {
                    ZStack {
                        Text("Convert")
                            .font(.headline)
                            .opacity(isExporting ? 0 : 1)
                        if isExporting {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                    .padding(.trailing, 4)
                                Text("Stop")
                                    .font(.headline)
                            }
                        }
                    }
                }
                .buttonStyle(CTAButtonStyle(isEnabled: selectedFileURL != nil))
                
            }.padding()
            
            
        
            if isDraggingOver {
                RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.accentColor, lineWidth: 3)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.windowBackgroundColor))
                                    .opacity(0.95)
                            )
                            .padding()
                            .frame(width: .infinity, height: .infinity)
                            .overlay(
                                Text("Drop video here")
                                    .font(.headline)
                            )
                            .transition(.opacity)
                            .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isDraggingOver)
        
        .frame(width: 400)

    }
    
    func convertVideoWithFFmpeg(
        for inputURL: URL,
        exportFormat: ExportFormat,
        removeAudio: Bool = false,
        resolution: ResolutionScale = .full,
        speed: PlaybackSpeed = .x1
    ) async {
        let outputURL = createOutputURL(for: inputURL, format: exportFormat)

        // Find FFmpeg
        let ffmpegPath = findFFmpegPath() ?? knownFfmpegPaths.first { FileManager.default.fileExists(atPath: $0) }
        if (ffmpegPath == nil) {
            exportStatus = "Not able to find ffmpeg. Install it with brew!"
            return
        }
        
        let resolveFfmpegPath = ffmpegPath!
        print("FFmpeg found: \(resolveFfmpegPath)")

        
        if FileManager.default.isExecutableFile(atPath: resolveFfmpegPath) {
            print("✅ FFmpeg is executable")
        } else {
            print("❌ FFmpeg is not executable or not found")
        }
        
        // Prepare process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: resolveFfmpegPath)

        // Convert FFmpeg arguments
        process.arguments = ffmpegArguments(for: inputURL, outputURL: outputURL, format: exportFormat, removeAudio: removeAudio, resolution: resolution, speed: speed)

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { handle in
            if let line = String(data: handle.availableData, encoding: .utf8) {
                
                parseProgress(line: line, progressHandler: { progress in
                    DispatchQueue.main.async {
                        exportProgress = progress
                        print("Progress: \(progress)")
                    }})
                }
        }
        
        do {
            isExporting = true
            runningProcess = process
            defer {
                isExporting = false
                runningProcess = nil
            }

            try process.run()

            // Wait on a background thread so the main thread (and UI) stays responsive.
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                process.terminationHandler = { _ in
                    pipe.fileHandleForReading.readabilityHandler = nil
                    continuation.resume()
                }
            }

            if process.terminationStatus == 0 {
                print("✅ Conversion succeeded: \(outputURL.path)")
#if os(macOS)
                NSWorkspace.shared.activateFileViewerSelecting([outputURL])
#endif
            } else {
                print("❌ FFmpeg failed with code: \(process.terminationStatus)")
            }
        } catch {
            print("🚨 Failed to run ffmpeg: \(error.localizedDescription)")
        }
    }
    
    func parseProgress(line: String, progressHandler: (Double) -> Void) {
        let lines = line.split(separator: "\n")
        for line in lines {
            if line.starts(with: "frame=") || line.starts(with: "time=") {
                if let timeString = line.split(separator: "=").last {
                    let timeComponents = timeString.split(separator: ":").compactMap { Double($0) }
                    if timeComponents.count == 3 {
                        let seconds = timeComponents[0] * 3600 + timeComponents[1] * 60 + timeComponents[2]
                        progressHandler(seconds)
                        print("Progress: \(seconds)")
                    }
                }
            }
        }
    }
    
    func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    DispatchQueue.main.async {
                        if let data = item as? Data,
                           let url = URL(dataRepresentation: data, relativeTo: nil) {
                            // Optionally check for video types
                            if url.pathExtension.lowercased().matchesAny(of: ["mp4", "mov", "m4v"]) {
                                // self.droppedFileURL = url
                                selectedFileURL = url
                                print("✅ Dropped video: \(url)")
                                // Trigger your processing logic here
                            }
                        }
                    }
                }
                return true
            }
        }
        return false
    }
    
}

extension String {
    func matchesAny(of extensions: [String]) -> Bool {
        extensions.contains { self.lowercased() == $0.lowercased() }
    }
}

#Preview {
    ContentView()
}

#Preview {
    ContentView(isExporting: true)
        .preferredColorScheme(.light)
        .frame(width: 400, height: 300)
        .padding()
}

#Preview {
    ContentView(isDraggingOver: true)
}

