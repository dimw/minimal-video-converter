import SwiftUI

@main
struct MinimalVideoConverterApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear { setupMainMenu() }
                .onDisappear { NSApplication.shared.terminate(nil) }
        }
        .windowResizability(.contentSize)
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
