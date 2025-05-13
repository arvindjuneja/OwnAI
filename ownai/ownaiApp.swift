//
//  ownaiApp.swift
//  ownai
//
//  Created by Arvind Juneja on 12/05/2025.
//

import SwiftUI

@main
struct ownaiApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow?) -> Void
    var isFloating: Bool
    var isSidebarModeActive: Bool

    // Bindings to AppStorage for window frame persistence
    @Binding var lastWindowX: Double?
    @Binding var lastWindowY: Double?
    @Binding var lastWindowWidth: Double?
    @Binding var lastWindowHeight: Double?
    @Binding var preferredSidebarWidth: Double? // Binding for preferred sidebar width

    private func update(window: NSWindow?) {
        guard let window = window else { return }
        let defaultSidebarWidth: CGFloat = 320.0
        let currentActualFrame = window.frame

        // If user is actively resizing the window
        if window.inLiveResize {
            if isSidebarModeActive {
                // User is resizing the sidebar. Capture and store this width if it's a valid sidebar width.
                if currentActualFrame.width > 100 && currentActualFrame.width < (NSScreen.main?.frame.width ?? 1000) * 0.8 {
                    if abs(currentActualFrame.width - CGFloat(preferredSidebarWidth ?? 0.0)) > 1.0 {
                        print("[WindowAccessor] Live resize of sidebar. New width: \(currentActualFrame.width). Storing as preferredSidebarWidth.")
                        DispatchQueue.main.async {
                            self.preferredSidebarWidth = currentActualFrame.width
                        }
                    }
                }
            }
            // Prevent programmatic frame changes during live resize to avoid fighting the user.
            // print("[WindowAccessor] Window in live resize. Deferring programmatic frame changes.")
            return
        }

        // If not in live resize, proceed with state-based frame setting:
        if isSidebarModeActive {
            // --- We want to BE IN SIDEBAR MODE --- 
            let targetSidebarWidth = CGFloat(self.preferredSidebarWidth ?? defaultSidebarWidth)

            // Heuristic: Is the window *not currently* looking like our target sidebar?
            let notCurrentlyTargetSidebar = 
                abs(currentActualFrame.width - targetSidebarWidth) > 1.0 ||
                abs(currentActualFrame.origin.x - ((NSScreen.main?.visibleFrame.maxX ?? 0) - targetSidebarWidth)) > 1.0 ||
                abs(currentActualFrame.height - (NSScreen.main?.visibleFrame.height ?? 0)) > 1.0

            if notCurrentlyTargetSidebar {
                // It seems we are transitioning TO sidebar mode OR adjusting to a new preferredSidebarWidth.
                // Save the current frame as "lastNormalFrame" ONLY IF it doesn't look like any sidebar.
                let looksLikeAnySidebar = currentActualFrame.width < (NSScreen.main?.frame.width ?? 800) * 0.6 && currentActualFrame.width > 100
                if !looksLikeAnySidebar {
                     // And ensure it's not the same as what we already have as last normal frame (to avoid overwriting on quick toggles after restoration)
                    let lastNormalFrameRect = (lastWindowX != nil && lastWindowY != nil && lastWindowWidth != nil && lastWindowHeight != nil) ? NSRect(x: lastWindowX!, y: lastWindowY!, width: lastWindowWidth!, height: lastWindowHeight!) : nil
                    if lastNormalFrameRect == nil || currentActualFrame != lastNormalFrameRect {
                        print("[WindowAccessor] Entering sidebar: Saving current frame as last normal: \(currentActualFrame)")
                        self.lastWindowX = currentActualFrame.origin.x
                        self.lastWindowY = currentActualFrame.origin.y
                        self.lastWindowWidth = currentActualFrame.size.width
                        self.lastWindowHeight = currentActualFrame.size.height
                    }
                }
                
                // Apply the target sidebar frame
                if let screen = NSScreen.main {
                    let visibleFrame = screen.visibleFrame
                    let targetFrame = NSRect(
                        x: visibleFrame.maxX - targetSidebarWidth,
                        y: visibleFrame.origin.y,
                        width: targetSidebarWidth,
                        height: visibleFrame.size.height
                    )
                    if currentActualFrame != targetFrame {
                        print("[WindowAccessor] Applying sidebar frame: \(targetFrame)")
                        window.setFrame(targetFrame, display: true, animate: false)
                    }
                }
            }
            
            let targetSidebarLevel = isFloating ? NSWindow.Level.floating : NSWindow.Level.normal
            if window.level != targetSidebarLevel { window.level = targetSidebarLevel }

        } else {
            // --- We want to BE IN NORMAL MODE (exiting sidebar) ---
            
            // If the current frame looks like a sidebar, its width is our best candidate for preferredSidebarWidth.
            let looksLikeAnySidebar = currentActualFrame.width < (NSScreen.main?.frame.width ?? 800) * 0.6 && currentActualFrame.width > 100
            if looksLikeAnySidebar {
                if abs(currentActualFrame.width - CGFloat(self.preferredSidebarWidth ?? 0.0)) > 1.0 {
                    print("[WindowAccessor] Exiting sidebar. Current width \(currentActualFrame.width) saved as preferredSidebarWidth.")
                    DispatchQueue.main.async {
                        self.preferredSidebarWidth = currentActualFrame.width
                    }
                }
            }

            // Restore normal frame
            if let x = self.lastWindowX, let y = self.lastWindowY, let w = self.lastWindowWidth, let h = self.lastWindowHeight {
                let restoredFrame = NSRect(x: x, y: y, width: w, height: h)
                if currentActualFrame != restoredFrame && w > 0 && h > 0 {
                    print("[WindowAccessor] Restoring normal frame to: \(restoredFrame)")
                    window.setFrame(restoredFrame, display: true, animate: false)
                }
            } else {
                // If no last frame, maybe let it be? Or set to a default good size?
                // For now, we do nothing if no frame to restore, which means it keeps current frame.
                print("[WindowAccessor] No saved normal frame to restore.")
            }

            let targetLevel = isFloating ? NSWindow.Level.floating : NSWindow.Level.normal
            if window.level != targetLevel { window.level = targetLevel }
            // print("[WindowAccessor] Exited sidebar mode logic completed.")
        }
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.callback(view.window)
            self.update(window: view.window) // Apply initial state
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            self.callback(nsView.window)
            self.update(window: nsView.window) // Apply state changes
        }
    }
}

