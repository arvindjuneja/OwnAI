import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Optional: Put any appDidFinishLaunching logic here
        print("App did finish launching.")
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Optional: Put any appWillTerminate logic here
        print("App will terminate.")
    }

    // Example: Allow app to open even if no windows are visible (useful for menu bar apps or if main window can be closed)
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // If you want to reopen the main window or create a new one:
            for window in sender.windows {
                if window.canBecomeMain {
                    window.makeKeyAndOrderFront(self)
                    return true
                }
            }
            // Or, if you have a specific way to recreate your main window:
            // Example: NSApp.sendAction(Selector(("reopenWindow:")), to: nil, from: nil)
        }
        return true
    }
} 