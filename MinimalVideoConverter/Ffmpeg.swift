import SwiftUI

func findFFmpegPath() -> String? {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["ffmpeg"]
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let path = String(decoding: data, as: UTF8.self).trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                return path.isEmpty ? nil : path
            }
        } catch {
            print("Error finding ffmpeg: \(error.localizedDescription)")
        }

        return nil
    }
