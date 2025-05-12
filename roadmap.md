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
    *   [ ] Add session naming and organization
    *   [ ] Implement session export/import
3.  **UI Polish:**
    *   [ ] Refine dark mode colors and contrast
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