import SwiftUI

struct AboutView: View {
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    private let githubURL = URL(string: "https://github.com/dimw/minimal-video-converter")!
    private let iconCreditURL = URL(string: "https://www.flaticon.com/free-icons/generate")!

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 96, height: 96)

            Text("MinimalVideoConverter")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Version \(version)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Link("dimw", destination: githubURL)
                .font(.subheadline)

            Divider()
                .padding(.horizontal, 24)

            Text("Icon by")
                .font(.caption)
                .foregroundStyle(.secondary)
            Link("FACH – Flaticon", destination: iconCreditURL)
                .font(.caption)
        }
        .padding(28)
        .frame(width: 280)
    }
}

final class AboutWindowController: NSWindowController {
    static let shared = AboutWindowController()

    private init() {
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "About MinimalVideoConverter"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: AboutView())
        window.center()
        super.init(window: window)
    }

    required init?(coder: NSCoder) { nil }

    func show() {
        window?.center()
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

#Preview {
    AboutView()
}
