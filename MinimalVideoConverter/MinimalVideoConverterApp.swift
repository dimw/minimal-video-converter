import SwiftUI

@main
struct MinimalVideoConverterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView().onDisappear {
                NSApplication.shared.terminate(nil)
            }
        }
        
        .commands {
//            CommandGroup(replacing: .appInfo) {
//                // Empty implementation to remove all items
//            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
//    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
//        // Prevent reopening or creating new windows
//        return false
//    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Remove all default menus
        let mainMenu = NSMenu()

        // Application menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        // Add "About" and other default app menu items
        appMenu.addItem(withTitle: "About MinimalVideoConverter", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit MinimalVideoConverter", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }
}
