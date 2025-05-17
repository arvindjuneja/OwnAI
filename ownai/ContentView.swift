//
//  ContentView.swift
//  ownai
//
//  Created by Arvind Juneja on 12/05/2025.
//

import SwiftUI

// ChatSender, MessageContentType, and ChatMessage moved to Models/ChatMessage.swift

struct ContentView: View {
    @AppStorage("ollamaAddress") private var ollamaAddress: String = "localhost"
    @AppStorage("ollamaPort") private var ollamaPort: String = "11434"
    @AppStorage("selectedModelName") private var selectedModelName: String = ""
    @AppStorage("connectionStatus") private var connectionStatus: String = "Disconnected" // Added to read shared status
    @StateObject private var sessionManager = SessionManager()
    @State private var showSettings = false
    @State private var showSessions = false
    @State private var chatMessages: [ChatMessage] = []
    @State private var prompt: String = ""
    @FocusState private var isPromptFocused: Bool
    @Namespace private var chatAnimation
    
    @State private var stayOnTop: Bool = false
    @AppStorage("isSidebarModeActive") private var isSidebarModeActive: Bool = false
    
    // AppStorage for persisting the last window frame before sidebar mode
    @AppStorage("lastWindowX") private var lastWindowX: Double? // Using optional Double
    @AppStorage("lastWindowY") private var lastWindowY: Double?
    @AppStorage("lastWindowWidth") private var lastWindowWidth: Double?
    @AppStorage("lastWindowHeight") private var lastWindowHeight: Double?
    @AppStorage("preferredSidebarWidth") private var preferredSidebarWidth: Double? // Added for user's preferred sidebar width
    
    // For streaming
    @State private var streamingSession: URLSession?

    var body: some View {
        ZStack {
            // Add WindowAccessor here as a background element
            WindowAccessor(callback: { _ in }, 
                           isFloating: stayOnTop, 
                           isSidebarModeActive: isSidebarModeActive,
                           lastWindowX: $lastWindowX,
                           lastWindowY: $lastWindowY,
                           lastWindowWidth: $lastWindowWidth,
                           lastWindowHeight: $lastWindowHeight,
                           preferredSidebarWidth: $preferredSidebarWidth)
                .frame(width: 0, height: 0) // Make it invisible and non-interactive
            
            // Glassmorphism background for the whole window
            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                .ignoresSafeArea()

            // Parent VStack to push footer to bottom
            VStack(spacing: 0) {
                // Main chat area VStack (copied from previous structure)
                VStack(spacing: 0) {
                    // Top bar with settings and sessions buttons
                    HStack {
                        // Connection status and model info
                        Image(systemName: "circle.fill") // Placeholder for status light
                            .foregroundColor(currentStatusColor) // Changed to dynamic color
                            .font(.caption)
                        Text("\(ollamaAddress) / \(selectedModelName.isEmpty ? "---" : selectedModelName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .help("Connected to: \(ollamaAddress) | Model: \(selectedModelName.isEmpty ? "Not selected" : selectedModelName)")

                        Spacer()
                        
                        // Sessions Button (Icon only)
                        Button(action: { showSessions = true }) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 16, weight: .medium)) // Adjusted size for icon-only
                        }
                        .buttonStyle(.plain)
                        .padding(4) // Adjust padding for icon-only
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .help("View Chat Sessions")
                        
                        // Settings Button (Icon only)
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gear")
                                .font(.system(size: 16, weight: .medium)) // Adjusted size for icon-only
                        }
                        .buttonStyle(.plain)
                        .padding(4) // Adjust padding for icon-only
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .help("Configure Ollama")

                        // Stay on Top Button
                        Button(action: { stayOnTop.toggle() }) {
                            Image(systemName: stayOnTop ? "pin.fill" : "pin.slash.fill")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .buttonStyle(.plain)
                        .padding(4)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .help(stayOnTop ? "Disable Stay on Top" : "Enable Stay on Top")

                        // Sidebar Mode Button
                        Button(action: { isSidebarModeActive.toggle() }) {
                            Image(systemName: isSidebarModeActive ? "sidebar.leading" : "sidebar.right") // Simplified icons
                                .font(.system(size: 16, weight: .medium))
                        }
                        .buttonStyle(.plain)
                        .padding(4)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .help(isSidebarModeActive ? "Exit Sidebar Mode" : "Enter Sidebar Mode")

                    }
                    .padding(.horizontal, 12) // Reduced horizontal padding for a tighter look
                    .padding(.top, 12)
                    .padding(.bottom, 6) // Added a little bottom padding for the bar
                    
                    // Chat history
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(chatMessages) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                        .transition(.move(edge: message.sender == .user ? .trailing : .leading).combined(with: .opacity))
                                        .animation(.easeInOut(duration: 0.25), value: chatMessages)
                                }
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(Color.clear)
                        .onChange(of: chatMessages.count) { oldCount, newCount in
                            if newCount > oldCount, let last = chatMessages.last {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    scrollProxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: chatMessages.last?.content) { oldContent, newContent in
                            if let last = chatMessages.last, last.isStreaming, oldContent != newContent {
                                withAnimation(.linear(duration: 0.1)) {
                                    scrollProxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: sessionManager.currentSessionId) { oldId, newId in
                            if let session = sessionManager.sessions.first(where: { $0.id == newId }) {
                                chatMessages = session.messages
                                if let lastMessage = chatMessages.last {
                                    DispatchQueue.main.async {
                                        withAnimation(.easeOut(duration: 0.1)) {
                                            scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Divider()
                // Input area with glass, gradient border, and padding
                HStack(alignment: .bottom, spacing: 12) {
                    ZStack(alignment: .topLeading) {
                        if prompt.isEmpty {
                            Text("Type your message...")
                                .foregroundColor(.secondary)
                                .padding(.top, 14)
                                .padding(.leading, 14)
                        }
                        CustomTextEditor(text: $prompt, onCommit: sendPrompt)
                            .font(.system(size: 16))
                            .frame(minHeight: 48, maxHeight: 110)
                            .focused($isPromptFocused)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                AnimatedGradientBorder(cornerRadius: 14)
                            )
                    }
                    Button(action: sendPrompt) {
                        Image(systemName: "paperplane.fill")
                            .rotationEffect(.degrees(45))
                            .foregroundColor(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .accentColor)
                            .font(.system(size: 20, weight: .bold))
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)

                Spacer() // Pushes footer down within this VStack
            
                // Footer Text
                Text("Made with ❤️ (and some GenAI) by Arvind Juneja")
                    .font(.footnote)
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.bottom, 8)

            } // End Parent VStack
            .frame(minWidth: 300, idealWidth: 600, minHeight: 540, idealHeight: 700)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.13), radius: 18, x: 0, y: 8)
            .padding([.top, .horizontal], 8)

        } // End ZStack
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showSessions) {
            SessionsView(sessionManager: sessionManager, showSessions: $showSessions)
        }
        .onAppear {
            isPromptFocused = true
            if sessionManager.currentSessionId == nil {
                _ = sessionManager.createNewSession()
            }
            if let session = sessionManager.sessions.first(where: { $0.id == sessionManager.currentSessionId }) {
                chatMessages = session.messages
            }
            // Ensure connectionStatus is re-evaluated on appear if needed, or rely on SettingsView to update it.
            // If SettingsView is not shown on first launch, connectionStatus might be stale from a previous session.
            // For now, we assume SettingsView will update it on its onAppear.
        }
        .onChange(of: chatMessages) { oldMessages, newMessages in
            sessionManager.saveSession(newMessages)
        }
    }
    
    // Computed property for status color based on shared connectionStatus
    private var currentStatusColor: Color {
        if connectionStatus.starts(with: "Connected") {
            return .green
        } else if connectionStatus.starts(with: "Error") || connectionStatus == "Disconnected" {
            return .red
        } else if connectionStatus.starts(with: "Checking") || connectionStatus.contains("Fetching models") {
            return .yellow // Or .orange
        }
        return .gray // Default for unknown states
    }
    
    // MARK: - Send Prompt
    func sendPrompt() {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !selectedModelName.isEmpty else { return }
        
        // Create user message with detected content type
        let userContentType = ChatMessage.detectContentType(trimmed)
        let userMsg = ChatMessage(sender: .user, content: trimmed, contentType: userContentType, timestamp: Date())
        
        withAnimation {
            chatMessages.append(userMsg)
        }
        prompt = ""
        sendToOllama(prompt: trimmed)
    }

    // MARK: - Ollama API Integration & Streaming
    func sendToOllama(prompt: String) {
        var effectiveAddress = ollamaAddress
        if effectiveAddress.lowercased() == "localhost" {
            effectiveAddress = "127.0.0.1"
        }
        let urlString = "http://\(effectiveAddress):\(ollamaPort)/api/chat"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        let messages = chatMessages.filter { !$0.isStreaming }.map { ["role": $0.sender == .user ? "user" : "assistant", "content": $0.content] }
        let body: [String: Any] = [
            "model": selectedModelName,
            "messages": messages + [["role": "user", "content": prompt]],
            "stream": true,
            "options": ["num_ctx": 4096, "verbose": true]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        // Add a streaming placeholder message
        var streamingMsg = ChatMessage(sender: .model, content: "", contentType: .text, timestamp: Date(), isStreaming: true)
        withAnimation {
            chatMessages.append(streamingMsg)
        }
        let streamingMsgID = streamingMsg.id

        // Use a custom URLSession with delegate for streaming
        let session = URLSession(configuration: .default, delegate: StreamingDelegate(update: { id, content, stats, done, errorText in
            updateStreamingMessage(id: id, content: content, stats: stats, done: done, errorText: errorText)
        }, streamingMsgID: streamingMsgID), delegateQueue: nil)
        streamingSession = session
        let task = session.dataTask(with: request)
        task.resume()
    }

    // Helper to update streaming message from delegate
    func updateStreamingMessage(id: UUID, content: String?, stats: String?, done: Bool, errorText: String? = nil) {
        DispatchQueue.main.async {
            guard let idx = chatMessages.firstIndex(where: { $0.id == id }) else { return }

            if let errorText = errorText {
                chatMessages[idx].content = "Error: \(errorText)"
                chatMessages[idx].contentType = .text
                chatMessages[idx].isStreaming = false
                chatMessages[idx].stats = nil
                return
            }

            if let content = content {
                chatMessages[idx].content += content
                chatMessages[idx].contentType = ChatMessage.detectContentType(chatMessages[idx].content)
            }
            if let stats = stats {
                chatMessages[idx].stats = stats
            }
            if done {
                chatMessages[idx].isStreaming = false
            }
        }
    }
}

// MARK: - Streaming Delegate
class StreamingDelegate: NSObject, URLSessionDataDelegate {
    let update: (UUID, String?, String?, Bool, String?) -> Void
    let streamingMsgID: UUID
    private var buffer = Data()
    private var accumulatedContent = ""
    
    init(update: @escaping (UUID, String?, String?, Bool, String?) -> Void, streamingMsgID: UUID) {
        self.update = update
        self.streamingMsgID = streamingMsgID
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        while let range = buffer.range(of: "\n".data(using: .utf8)!) {
            let lineData = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
            buffer.removeSubrange(buffer.startIndex...range.lowerBound)
            if let line = String(data: lineData, encoding: .utf8) {
                processOllamaStreamChunk(line)
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            update(streamingMsgID, nil, nil, true, error.localizedDescription)
        }
    }
    
    func processOllamaStreamChunk(_ line: String) {
        guard let data = line.data(using: .utf8) else { return }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let errorMessage = json["error"] as? String {
                update(streamingMsgID, nil, nil, true, errorMessage)
                return
            }

            if let done = json["done"] as? Bool, done {
                let stats = json["eval_count"].flatMap { "Tokens: \($0)" } ?? ""
                let speed = json["eval_duration"].flatMap { d in
                    if let d = d as? Double, let c = json["eval_count"] as? Double, c > 0 {
                        return String(format: "%.1f tok/s", c / (d / 1_000_000_000))
                    }
                    return nil
                } ?? ""
                let statsString = [stats, speed].filter { !$0.isEmpty }.joined(separator: " | ")
                update(streamingMsgID, nil, statsString, true, nil)
            } else if let response = json["message"] as? [String: Any], let content = response["content"] as? String {
                accumulatedContent += content
                let contentType = ChatMessage.detectContentType(accumulatedContent)
                update(streamingMsgID, content, nil, false, nil)
            }
        }
    }
}

// CustomTextEditor, AnimatedGradientBorder, and VisualEffectBlur were moved to ViewHelpers.swift

// ChatBubble and ContentSegment were moved to ChatBubble.swift

// #Preview {
//     ContentView()
// } 
