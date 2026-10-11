import AppKit

@MainActor
final class StatusBarController {

    private var statusItem: NSStatusItem?
    private let model: ConverterModel

    private var convertItem: NSMenuItem?
    private var watchedFolderItem: NSMenuItem?

    init(model: ConverterModel) {
        self.model = model
        setup()
    }

    private func setup() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "film", accessibilityDescription: "MinimalVideoConverter")
        item.button?.image?.isTemplate = true

        let menu = NSMenu()

        let convertItem = NSMenuItem(title: "Convert latest file", action: #selector(convertLatest), keyEquivalent: "")
        convertItem.target = self
        menu.addItem(convertItem)
        self.convertItem = convertItem

        let watchedFolderItem = NSMenuItem(title: watchedFolderTitle(), action: #selector(chooseWatchedFolder), keyEquivalent: "")
        watchedFolderItem.target = self
        menu.addItem(watchedFolderItem)
        self.watchedFolderItem = watchedFolderItem

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Open settings", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        item.menu = menu
        statusItem = item

        updateConvertItem()
    }

    private func watchedFolderTitle() -> String {
        if let url = model.watchedFolderURL {
            return "Watching: \(url.lastPathComponent)"
        }
        return "Choose watched folder…"
    }

    func updateConvertItem() {
        let latestURL = latestVideoInWatchedFolder()
        if let url = latestURL {
            convertItem?.title = "Convert \"\(url.lastPathComponent)\""
            convertItem?.isEnabled = !model.isExporting
        } else {
            convertItem?.title = "Convert latest file"
            convertItem?.isEnabled = false
        }
        watchedFolderItem?.title = watchedFolderTitle()
    }

    private func latestVideoInWatchedFolder() -> URL? {
        guard let folder = model.watchedFolderURL else { return nil }
        let videoExtensions = ["mp4", "mov", "m4v"]
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        return contents
            .filter { videoExtensions.contains($0.pathExtension.lowercased()) }
            .filter { !$0.deletingPathExtension().lastPathComponent.contains("(reduced)") }
            .sorted {
                let d1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let d2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return d1 > d2
            }
            .first
    }

    // MARK: - Actions

    @objc private func convertLatest() {
        guard let url = latestVideoInWatchedFolder() else { return }
        Task { await model.convert(inputURL: url) }
    }

    @objc private func chooseWatchedFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        panel.message = "Choose a folder to watch for new videos"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        model.watchedFolderURL = url
        updateConvertItem()
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first(where: { $0.styleMask.contains(.titled) && !($0 is NSPanel) })?.makeKeyAndOrderFront(nil)
    }
}
