import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    func lockWindowSize() {
        guard let window = NSApplication.shared.windows.first(where: {
            $0.styleMask.contains(.titled) && !($0 is NSPanel)
        }) else { return }
        if window.delegate !== self { window.delegate = self }
        window.styleMask.remove(.resizable)
        window.standardWindowButton(.zoomButton)?.isEnabled = false
    }

    // Block zoom even if AppKit re-enables the button after restore.
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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupMainMenu()
                    DispatchQueue.main.async { appDelegate.lockWindowSize() }
                }
                .onDisappear { NSApplication.shared.terminate(nil) }
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
