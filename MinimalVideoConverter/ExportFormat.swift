import SwiftUI

enum ExportFormat: String, CaseIterable, Identifiable {
    case h264 = "H.264"
    case h265 = "H.265"
    case gif = "GIF"
    
    var id: String { self.rawValue }
    
    var fileExtension: String {
        switch self {
        case .h264, .h265: return "mp4"
        case .gif: return "gif"
        }
    }
}


enum PlaybackSpeed: String, CaseIterable, Identifiable {
    case x1 = "1x"
    case x1_2 = "1.2x"
    case x1_5 = "1.5x"
    case x2 = "2x"
    case x4 = "4x"

    var id: String { rawValue }

    var factor: Double {
        switch self {
        case .x1: return 1.0
        case .x1_2: return 1.2
        case .x1_5: return 1.5
        case .x2: return 2.0
        case .x4: return 4.0
        }
    }

    var videoFilter: String? {
        guard factor != 1.0 else { return nil }
        return "setpts=PTS/\(factor)"
    }

    // atempo is capped at 2.0, so 4x requires chaining
    var audioFilter: String? {
        guard factor != 1.0 else { return nil }
        if factor <= 2.0 {
            return "atempo=\(factor)"
        } else {
            return "atempo=2.0,atempo=\(factor / 2.0)"
        }
    }
}

enum ResolutionScale: String, CaseIterable, Identifiable {
    case full = "Full"
    case threeQuarters = "75%"
    case half = "50%"
    case quarter = "25%"

    var id: String { rawValue }

    var scaleFilter: String? {
        switch self {
        case .full: return nil
        case .threeQuarters: return "scale=trunc(iw*3/8)*2:trunc(ih*3/8)*2"
        case .half: return "scale=trunc(iw/4)*2:trunc(ih/4)*2"
        case .quarter: return "scale=trunc(iw/8)*2:trunc(ih/8)*2"
        }
    }

    var gifScaleFilter: String? {
        switch self {
        case .full: return nil
        case .threeQuarters: return "scale=trunc(iw*3/8)*2:trunc(ih*3/8)*2"
        case .half: return "scale=trunc(iw/4)*2:trunc(ih/4)*2"
        case .quarter: return "scale=trunc(iw/8)*2:trunc(ih/8)*2"
        }
    }
}

func ffmpegArguments(for inputURL: URL, outputURL: URL, format: ExportFormat, removeAudio: Bool = false, resolution: ResolutionScale = .full, speed: PlaybackSpeed = .x1) -> [String] {
    let audioArgs: [String]
    if removeAudio {
        audioArgs = ["-an"]
    } else if let af = speed.audioFilter {
        audioArgs = ["-filter:a", af]
    } else {
        audioArgs = []
    }

    func videoFilter(base: String?) -> [String] {
        let parts = [base, speed.videoFilter].compactMap { $0 }
        guard !parts.isEmpty else { return [] }
        return ["-filter:v", parts.joined(separator: ",")]
    }

    switch format {
    case .h264:
        return ["-y", "-i", inputURL.path, "-vcodec", "libx264", "-crf", "23"]
            + videoFilter(base: resolution.scaleFilter)
            + audioArgs
            + ["-progress", "-", "-nostats", outputURL.path]
    case .h265:
        return ["-y", "-i", inputURL.path, "-vcodec", "libx265", "-crf", "28"]
            + videoFilter(base: resolution.scaleFilter)
            + audioArgs
            + [outputURL.path]
    case .gif:
        // Handled separately via gifArguments(for:outputURL:resolution:speed:)
        return []
    }
}

// Returns (palettegenArgs, paletteuseArgs, paletteURL) for two-pass high-quality GIF export.
func gifArguments(for inputURL: URL, outputURL: URL, resolution: ResolutionScale, speed: PlaybackSpeed) -> ([String], [String], URL) {
    let paletteURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("png")

    let speedPrefix = speed.videoFilter.map { "\($0)," } ?? ""
    let scaleFilter = resolution.gifScaleFilter.map { "\($0)," } ?? ""
    // fps=15 gives smoother playback; lanczos is highest-quality downscale filter
    let baseFilters = speedPrefix + scaleFilter + "fps=15,scale=flags=lanczos"

    let palettegenArgs = [
        "-y", "-i", inputURL.path,
        "-vf", "\(baseFilters),palettegen=stats_mode=full",
        paletteURL.path
    ]

    let paletteuseArgs = [
        "-y",
        "-i", inputURL.path,
        "-i", paletteURL.path,
        "-an",
        "-lavfi", "\(baseFilters) [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle",
        "-progress", "-", "-nostats",
        outputURL.path
    ]

    return (palettegenArgs, paletteuseArgs, paletteURL)
}

func createOutputURL(for inputURL: URL, format: ExportFormat) -> URL {
    let filename = inputURL.deletingPathExtension().lastPathComponent
    let reducedFilename = "\(filename) (reduced)"
    
    let directory = inputURL.deletingLastPathComponent()
    return directory.appendingPathComponent(reducedFilename).appendingPathExtension(format.fileExtension)
}
