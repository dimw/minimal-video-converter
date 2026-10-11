import SwiftUI

@main
struct MinimalVideoConverterApp: App {

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

        appMenu.addItem(withTitle: "About MinimalVideoConverter", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit MinimalVideoConverter", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }
}
