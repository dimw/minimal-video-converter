import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
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
                    DispatchQueue.main.async { Self.lockWindowSize() }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
                    DispatchQueue.main.async { Self.lockWindowSize() }
                }
                .onDisappear { NSApplication.shared.terminate(nil) }
        }
        .windowResizability(.contentSize)
    }

    private static func lockWindowSize() {
        guard let window = NSApplication.shared.windows.first else { return }
        window.styleMask.remove(.resizable)
        let size = window.frame.size
        window.minSize = size
        window.maxSize = size
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
