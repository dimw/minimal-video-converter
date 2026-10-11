import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    var statusBarController: StatusBarController?

    func lockWindowSize() {
        guard let window = NSApplication.shared.windows.first(where: {
            $0.styleMask.contains(.titled) && !($0 is NSPanel)
        }) else { return }
        if window.delegate !== self { window.delegate = self }
        window.styleMask.remove(.resizable)
        window.standardWindowButton(.zoomButton)?.isEnabled = false
    }

    func windowShouldZoom(_ window: NSWindow, toFrame newFrame: NSRect) -> Bool {
        false
    }

    @objc func showAbout() {
        AboutWindowController.shared.show()
    }
}

@main
struct MinimalVideoConverterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private let model = ConverterModel()
    private let statusBarController: StatusBarController

    init() {
        let m = model
        statusBarController = StatusBarController(model: m)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .onAppear {
                    appDelegate.statusBarController = statusBarController
                    setupMainMenu()
                    DispatchQueue.main.async { appDelegate.lockWindowSize() }
                }
        }
        .windowResizability(.contentSize)
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        let aboutItem = NSMenuItem(title: "About MinimalVideoConverter", action: #selector(AppDelegate.showAbout), keyEquivalent: "")
        aboutItem.target = appDelegate
        appMenu.addItem(aboutItem)
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit MinimalVideoConverter", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }
}
