# Ollama macOS Interface Project Roadmap

This document outlines the development plan for a macOS interface for local Ollama instances.

## Phase 1: Core Functionality & Basic UI ✅

**Goal:** Establish a basic, functional application that can connect to Ollama, list models, and have a simple chat interaction.

**Steps:**

1.  **Project Setup & Technology Choice:**
    *   [x] Decide on the primary technology stack (e.g., SwiftUI, Electron, Python with a GUI library). Chosen: **SwiftUI**
    *   [x] Set up the initial project structure. Project created: `ownai` folder, named "OwnAI".
    *   *Learnings: SwiftUI is a strong choice for creating native macOS applications that can be easily shared as `.app` bundles, offering a good user experience and straightforward distribution options (direct sharing, Developer ID signing, or Mac App Store).*
2.  **Ollama Connection Management:**
    *   [x] Implement logic to connect to a user-specified Ollama instance (IP address/port). (Implemented HTTP GET to /api/version, handles success/error, uses AppStorage for persistence).
    *   [x] Basic connection status indicator (connected/disconnected). (UI and dynamic status update implemented).
    *   *Learnings: Used URLSession for asynchronous network requests. Implemented basic error handling and status updates. Used @AppStorage for persisting connection settings. Required App Transport Security (ATS) configuration in Info.plist to allow HTTP connections for local Ollama instance. Needed to add network client entitlements to allow outgoing connections. Added a dedicated settings view with close button and keyboard shortcuts for better UX.*
3.  **Model Listing & Selection:**
    *   [x] Fetch the list of available models from the connected Ollama instance. (Implemented /api/tags call, UI picker, and persistence)
    *   [x] Allow the user to select a model to use for chat. (Picker UI, @AppStorage persistence)
    *   *Learnings: Used Codable for API parsing, Picker for model selection, and ensured UI fits well on macOS. Will revisit for further polish in the final design phase.*

## Phase 2: Chat Interface & Experience ✅

**Goal:** Build a beautiful, animated, and highly usable chat interface for macOS, with attention to detail and a widget-like feel.

**Steps:**

1.  **Chat Data Structures:**
    *   [x] Define message types (user, model, code, etc.)
    *   [x] Implement content type detection (text, code, terminal, markdown)
2.  **Chat UI:**
    *   [x] Implement a modern, animated chat history view
    *   [x] Add smooth transitions and macOS-native styling
    *   [x] Ensure the chat area is visually distinct and "widget-like"
    *   [x] Add glassmorphism and gradient effects
3.  **Prompt Input & Sending:**
    *   [x] Add a prompt input field and send button
    *   [x] Support keyboard shortcuts for sending (Enter to send, Shift+Enter for newline)
    *   [x] Add animated gradient border and glassmorphism to input area
    *   [x] Add proper padding and clarity to input and chat bubbles
4.  **Stats & Verbose Mode:**
    *   [x] Show token count, speed, and other stats placeholder below model responses
5.  **API Integration & Streaming:**
    *   [x] Send user prompts to the selected model via /api/chat
    *   [x] Parse and display real model responses
    *   [x] Display streaming responses in real time
    *   [x] Show animated gradient border on model bubble while generating, then fade out
    *   [x] Auto-scroll to the latest message as it streams
    *   *Learnings: Used URLSession with a custom delegate for streaming, handled chunked JSON, and ensured smooth UI updates and auto-scroll during streaming.*

## Phase 3: Formatting, Copy, and Session Management (Current)

**Goal:** Add code/terminal formatting, copy features, and session management to enhance usability.

**Steps:**

1.  **Formatting & Copy:**
    *   [x] Basic content type detection and rendering
    *   [x] Add syntax highlighting for code blocks (using Splash)
    *   [x] Improve markdown rendering with proper formatting (using Down)
    *   [x] Add copy buttons for code/terminal content types
    *   [x] Add hover effects and visual feedback for copy actions
    *   [x] Add configurable font size and spacing settings
    *   [x] Refined chat bubble rendering to correctly handle mixed text/code
    *   [x] Fixed various font rendering and layout issues
2.  **Session Management:**
    *   [x] Save and load chat sessions (using SessionManager and UserDefaults)
    *   [x] Add session list view with selection and deletion (via context menu)
    *   [x] Add session naming and organization
    *   [x] Implement session export/import
3.  **Codebase Refactoring for Clarity and Maintainability:**
    *   **Goal:** Improve overall code structure by breaking down large files and organizing them into logical directories.
    *   **Motivation:** The main `ownai/ownai/ContentView.swift` file had grown significantly. Other view and model definitions were also co-located. Separating distinct UI components, views, view helpers, and data models into their own files and organizing them into dedicated folders (e.g., `Views/`, `Models/`) enhances readability, maintainability, reusability, and makes the codebase easier to navigate. This also optimizes the context buffer when working with LLM-based coding assistants.
    *   **Steps:**
        1.  [x] Extracted `ContentSegment` and `ChatBubble` from `ContentView.swift` into `ownai/ownai/ChatBubble.swift`.
        2.  [x] Extracted `CustomTextEditor`, `AnimatedGradientBorder`, and `VisualEffectBlur` from `ContentView.swift` into `ownai/ownai/ViewHelpers.swift`.
        3.  [x] Created `ownai/ownai/Views/` directory.
        4.  [x] Moved `ChatBubble.swift` to `ownai/ownai/Views/ChatBubble.swift`.
        5.  [x] Moved `ViewHelpers.swift` to `ownai/ownai/Views/ViewHelpers.swift`.
        6.  [x] Moved `SessionsView.swift` to `ownai/ownai/Views/SessionsView.swift`.
        7.  [x] Moved `SettingsView.swift` to `ownai/ownai/Views/SettingsView.swift`.
        8.  [x] Extract `ChatMessage`, `ChatSender`, `MessageContentType` (and Ollama API response structs from `SettingsView.swift`) into a new `Models/` directory with appropriate file(s) like `ChatMessage.swift` and `OllamaModels.swift`.
        9.  [x] Verify project compilation and functionality post-refactoring.
    *   [x] Complete the refactoring of `ContentView.swift` components and model definitions.
4.  **UI Polish:**
    *   [ ] Refine dark mode colors and contrast
    *   [ ] Refine Top Bar: Ensure clear display of connection status light, connected Ollama IP/address, and currently selected model.
    *   [ ] Dynamic Connection Status Light: Ensure the status light in the top bar accurately reflects the connection state (e.g., green for connected, red for error, yellow for trying).
    *   [ ] Add subtle animations for state changes
    *   [ ] Improve accessibility
    *   [ ] Add keyboard shortcuts for common actions
    *   [ ] Add tooltips and help text

## Phase 4: Advanced Features

**Goal:** Add advanced features and polish the user experience.

**Steps:**

1.  **Model Management:**
    *   [ ] Add model download progress indicator
    *   [ ] Show model details (size, last used, etc.)
    *   [ ] Add model search/filtering
2.  **System Prompt Management:**
    *   [ ] Add system prompt editor
    *   [ ] Save and load custom system prompts
    *   [ ] Add prompt templates
3.  **Advanced Settings:**
    *   [ ] Add temperature and other model parameters
    *   [ ] Add context window size control
    *   [ ] Add streaming speed control
4.  **Export & Sharing:**
    *   [ ] Export chats as Markdown
    *   [ ] Export chats as HTML
    *   [ ] Share chat links (if Ollama API supports)
5.  **Window Management Enhancements:**
    *   [x] Implement "Stay on Top" functionality.
        *   *Learnings: Added `isFloating` to `WindowAccessor` and a `Toggle` in `SettingsView` to control `NSWindow.level`. Straightforward to implement for basic always-on-top behavior.*
    *   [ ] Explore feasibility of "Sidebar Docking" behavior for seamless desktop integration (experimental).
        *   **Goal:** Allow the app to be optionally docked to the side of the screen, acting like a persistent sidebar.
        *   **Steps:**
            1.  **State Management for Sidebar Mode:**
                *   [ ] Add a state variable (e.g., `@State private var isSidebarModeActive: Bool = false`) in `ContentView.swift`.
                *   [ ] Consider `AppStorage` to persist sidebar mode state across launches.
            2.  **UI Control for Toggling Sidebar Mode:**
                *   [ ] Add a `Toggle` or `Button` in `SettingsView` (e.g., under "Window Behavior") or a dedicated button in the main UI to activate/deactivate sidebar mode.
            3.  **Window Positioning and Resizing Logic:**
                *   [x] Investigate and implement methods to get primary screen dimensions (width, height, available area excluding menu bar/Dock) using `NSScreen`.
                *   [x] In `WindowAccessor` or a dedicated window management utility, add logic to:
                    *   [x] Calculate the target frame (position and size) for the window when sidebar mode is activated (configurable width, edge snapping for left/right).
                    *   [x] Apply the new frame and ensure "Stay on Top" (`.floating` level, respecting main toggle) when entering sidebar mode.
                    *   [x] Restore the previous window frame (or a default) and window level when exiting sidebar mode.
            4.  **Persisting/Restoring Window Frame:**
                *   [x] Save the window's last non-sidebar frame when entering sidebar mode to restore it upon exit (using `@AppStorage` for `CGRect` components).
                *   [x] Persist user-defined sidebar width: If the user resizes the sidebar, store this preferred width in `@AppStorage` and use it for subsequent sidebar sessions.
            5.  **(Optional/Future) Compact UI for Sidebar Mode:**
                *   [ ] Explore conditional UI changes in `ContentView.swift` for a more compact layout in sidebar mode.
        *   *Learnings: (To be filled as implemented)*
            *   *Initial thoughts: True automatic resizing of other apps is complex. This approach focuses on self-resizing, positioning, and "always on top" behavior. Users will manually arrange other windows alongside the sidebar.*
            *   *`minWidth` constraint in SwiftUI's `.frame()` modifier on `ContentView` was critical to resolve content cropping when programmatically resizing the window to a narrow sidebar width.*
            *   *Handling live window resizes (`window.inLiveResize`) and distinguishing between entering/exiting sidebar mode versus active sidebar resizing required careful state logic in `WindowAccessor` to prevent update loops and correctly persist user preferences for both normal window frame and sidebar width. Ensured `@AppStorage` updates occur on the main thread.*
            *   *Relocated "Stay on Top" and "Sidebar Mode" toggles from Settings to main UI as icon buttons for better UX.*

## Phase 5: Distribution & Polish

**Goal:** Prepare the application for distribution and add final polish.

**Steps:**

1.  **Packaging:**
    *   [ ] Create app icon and assets
    *   [ ] Set up proper app signing
    *   [ ] Create DMG installer
2.  **Documentation:**
    *   [ ] Create user guide
    *   [ ] Add in-app help
    *   [ ] Create website
3.  **Final Polish:**
    *   [ ] Performance optimization
    *   [ ] Memory usage optimization
    *   [ ] Final UI/UX review
    *   [ ] Cross-version testing

---

*This roadmap is a living document and will be updated as the project progresses. Learnings and decisions will be documented under each step.* 