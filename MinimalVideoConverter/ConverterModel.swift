import SwiftUI
import AppKit

let knownFfmpegPaths = [
    "/opt/homebrew/bin/ffmpeg",
    "/usr/local/bin/ffmpeg",
    "/usr/bin/ffmpeg"
]

@MainActor
final class ConverterModel: ObservableObject {

    // MARK: - Persisted settings

    @AppStorage("selectedFormat") var selectedFormat: ExportFormat = .h264
    @AppStorage("removeAudio") var removeAudio: Bool = false
    @AppStorage("resolution") var resolution: ResolutionScale = .full
    @AppStorage("speed") var speed: PlaybackSpeed = .x1

    // MARK: - Watched folder (security-scoped bookmark)

    @Published var watchedFolderURL: URL? {
        didSet { saveWatchedFolderBookmark() }
    }

    // MARK: - Conversion state

    @Published var selectedFileURL: URL?
    @Published var isExporting: Bool = false
    @Published var exportProgress: Double = 0.0
    @Published var exportStatus: String = "No export yet"

    private var runningProcess: Process?

    // MARK: - Init

    init() {
        watchedFolderURL = loadWatchedFolderBookmark()
    }

    // MARK: - Watched folder bookmark persistence

    private func saveWatchedFolderBookmark() {
        guard let url = watchedFolderURL else {
            UserDefaults.standard.removeObject(forKey: "watchedFolderBookmark")
            return
        }
        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmark, forKey: "watchedFolderBookmark")
        } catch {
            print("Failed to save watched folder bookmark: \(error)")
        }
    }

    private func loadWatchedFolderBookmark() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: "watchedFolderBookmark") else { return nil }
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale { return nil }
            _ = url.startAccessingSecurityScopedResource()
            return url
        } catch {
            print("Failed to load watched folder bookmark: \(error)")
            return nil
        }
    }

    // MARK: - Conversion

    func stopConversion() {
        runningProcess?.terminate()
    }

    func convert(inputURL: URL) async {
        let outputURL = createOutputURL(for: inputURL, format: selectedFormat)

        let ffmpegPath = findFFmpegPath() ?? knownFfmpegPaths.first { FileManager.default.fileExists(atPath: $0) }
        guard let resolvedPath = ffmpegPath else {
            exportStatus = "Not able to find ffmpeg. Install it with brew!"
            return
        }

        isExporting = true
        defer { isExporting = false }

        if selectedFormat == .gif {
            let (pass1Args, pass2Args, paletteURL) = gifArguments(
                for: inputURL, outputURL: outputURL,
                resolution: resolution, speed: speed
            )
            defer { try? FileManager.default.removeItem(at: paletteURL) }

            guard await runFFmpeg(path: resolvedPath, args: pass1Args, trackProgress: false) else { return }
            guard await runFFmpeg(path: resolvedPath, args: pass2Args, trackProgress: true) else { return }
        } else {
            let args = ffmpegArguments(
                for: inputURL, outputURL: outputURL,
                format: selectedFormat, removeAudio: removeAudio,
                resolution: resolution, speed: speed
            )
            guard await runFFmpeg(path: resolvedPath, args: args, trackProgress: true) else { return }
        }

        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
    }

    private func runFFmpeg(path: String, args: [String], trackProgress: Bool) async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        if trackProgress {
            pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                guard let self else { return }
                if let line = String(data: handle.availableData, encoding: .utf8) {
                    parseFFmpegProgress(line: line) { progress in
                        DispatchQueue.main.async { self.exportProgress = progress }
                    }
                }
            }
        }

        runningProcess = process
        defer { runningProcess = nil }

        do {
            try process.run()
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                process.terminationHandler = { _ in
                    pipe.fileHandleForReading.readabilityHandler = nil
                    continuation.resume()
                }
            }
            if process.terminationStatus != 0 {
                print("FFmpeg failed with code: \(process.terminationStatus)")
                return false
            }
            return true
        } catch {
            print("Failed to run ffmpeg: \(error.localizedDescription)")
            return false
        }
    }

}

private func parseFFmpegProgress(line: String, progressHandler: (Double) -> Void) {
    let lines = line.split(separator: "\n")
    for l in lines {
        if l.starts(with: "frame=") || l.starts(with: "time=") {
            if let timeString = l.split(separator: "=").last {
                let parts = timeString.split(separator: ":").compactMap { Double($0) }
                if parts.count == 3 {
                    progressHandler(parts[0] * 3600 + parts[1] * 60 + parts[2])
                }
            }
        }
    }
}
