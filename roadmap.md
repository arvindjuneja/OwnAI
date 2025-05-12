# Ollama macOS Interface Project Roadmap

This document outlines the development plan for a macOS interface for local Ollama instances.

## Phase 1: Core Functionality & Basic UI

**Goal:** Establish a basic, functional application that can connect to Ollama, list models, and have a simple chat interaction.

**Steps:**

1.  **Project Setup & Technology Choice:**
    *   [x] Decide on the primary technology stack (e.g., SwiftUI, Electron, Python with a GUI library). Chosen: **SwiftUI**
    *   [x] Set up the initial project structure. Project created: `ownai` folder, named "OwnAI".
    *   *Learnings: SwiftUI is a strong choice for creating native macOS applications that can be easily shared as `.app` bundles, offering a good user experience and straightforward distribution options (direct sharing, Developer ID signing, or Mac App Store).
2.  **Ollama Connection Management:**
    *   [x] Implement logic to connect to a user-specified Ollama instance (IP address/port). (Implemented HTTP GET to /api/version, handles success/error, uses AppStorage for persistence).
    *   [x] Basic connection status indicator (connected/disconnected). (UI and dynamic status update implemented).
    *   *Learnings: Used URLSession for asynchronous network requests. Implemented basic error handling and status updates. Used @AppStorage for persisting connection settings. Required App Transport Security (ATS) configuration in Info.plist to allow HTTP connections for local Ollama instance. Needed to add network client entitlements to allow outgoing connections. Added a dedicated settings view with close button and keyboard shortcuts for better UX.*
3.  **Model Listing & Selection:**
    *   [ ] Fetch the list of available models from the connected Ollama instance.
    *   [ ] Allow the user to select a model to use for chat.
    *   *Learnings:*
4.  **Basic Chat Interface:**
    *   [ ] Create a simple input field for user prompts.
    *   [ ] Display Ollama's responses (plain text initially).
    *   [ ] Implement sending a prompt to the selected model and receiving the response.
    *   *Learnings:*
5.  **Stop Generation:**
    *   [ ] Add a button/mechanism to interrupt/stop Ollama's response generation.
    *   *Learnings:*
6.  **Copy Result:**
    *   [ ] Allow users to easily copy the model's response text.
    *   *Learnings:*

## Phase 2: Enhanced User Experience & Features

**Goal:** Improve the UI/UX, add richer text formatting, and session management.

**Steps:**

1.  **UI/UX Refinement:**
    *   [ ] Improve the visual design, potentially drawing inspiration from native macOS styling.
    *   [ ] Consider app structure (menu bar app vs. standard windowed app).
    *   *Learnings:*
2.  **Markdown & Code Snippet Rendering:**
    *   [ ] Implement Markdown rendering for model responses.
    *   [ ] Ensure proper formatting and syntax highlighting for code blocks.
    *   *Learnings:*
3.  **Verbose Mode (Ollama Stats):**
    *   [ ] Integrate the ability to toggle verbose mode for Ollama requests.
    *   [ ] Display statistics (tokens, generation speed) per request if verbose mode is active.
    *   *Learnings:*
4.  **Basic Session Management:**
    *   [ ] Implement functionality to clear the current chat session.
    *   [ ] Implement functionality to save the current chat session (e.g., to a local file or in-app storage).
    *   [ ] Implement functionality to load a saved chat session.
    *   *Learnings:*
5.  **Streaming Responses:**
    *   [ ] Ensure responses are streamed token-by-token for a more responsive feel.
    *   *Learnings:*

## Phase 3: Advanced Features & Polish

**Goal:** Add advanced functionalities, robust error handling, and overall polish.

**Steps:**

1.  **Local Network Scan for Ollama Instances (Optional):**
    *   [ ] Implement a feature to scan the local network for running Ollama instances.
    *   *Learnings:*
2.  **Conversation History:**
    *   [ ] Develop a more robust conversation history feature (list, search, switch between conversations).
    *   *Learnings:*
3.  **System Prompt Customization:**
    *   [ ] Allow users to set and manage custom system prompts for models.
    *   *Learnings:*
4.  **Settings/Preferences Panel:**
    *   [ ] Create a panel for managing settings (default Ollama IP, default model, etc.).
    *   *Learnings:*
5.  **Error Handling & Feedback:**
    *   [ ] Implement comprehensive error handling and provide clear user feedback for various scenarios (connection issues, API errors).
    *   *Learnings:*
6.  **Model Management (Advanced - Optional):**
    *   [ ] Explore options for pulling new models or deleting existing ones via the UI (if Ollama API supports).
    *   *Learnings:*
7.  **Global Keyboard Shortcut (If Menu Bar App):**
    *   [ ] Implement a global keyboard shortcut to quickly access the app.
    *   *Learnings:*
8.  **Accessibility Review:**
    *   [ ] Ensure the application adheres to accessibility best practices.
    *   *Learnings:*

## Phase 4: Packaging & Distribution (Placeholder)

**Goal:** Prepare the application for use.

**Steps:**

1.  [ ] Application icon design.
2.  [ ] Testing on different macOS versions.
3.  [ ] Build and package the application (e.g., .app bundle).
4.  [ ] Consider distribution methods (direct download, App Store - though App Store might have restrictions related to local network access).
    *   *Learnings:*

---

*This roadmap is a living document and will be updated as the project progresses. Learnings and decisions will be documented under each step.* 