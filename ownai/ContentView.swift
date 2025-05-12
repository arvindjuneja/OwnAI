//
//  ContentView.swift
//  ownai
//
//  Created by Arvind Juneja on 12/05/2025.
//

import SwiftUI

// MARK: - Chat Message Model
enum ChatSender: Equatable {
    case user, model
}

enum MessageContentType: Equatable {
    case text
    case code(language: String)
    case terminal
    case markdown
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let sender: ChatSender
    var content: String
    var contentType: MessageContentType
    let timestamp: Date
    var stats: String? = nil // For verbose/token stats
    var isStreaming: Bool = false // For animated border
    
    // Helper to detect content type from string
    static func detectContentType(_ content: String) -> MessageContentType {
        // Check for code blocks
        if content.contains("```") {
            let lines = content.components(separatedBy: .newlines)
            for line in lines {
                if line.hasPrefix("```") {
                    let language = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
                    return .code(language: language.isEmpty ? "text" : language)
                }
            }
        }
        
        // Check for terminal-like content
        if content.contains("$ ") || content.contains("> ") || content.contains("PS ") {
            return .terminal
        }
        
        // Check for markdown
        if content.contains("# ") || content.contains("* ") || content.contains("> ") {
            return .markdown
        }
        
        return .text
    }
    
    // Implement Equatable
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.sender == rhs.sender &&
        lhs.content == rhs.content &&
        lhs.contentType == rhs.contentType &&
        lhs.timestamp == rhs.timestamp &&
        lhs.stats == rhs.stats &&
        lhs.isStreaming == rhs.isStreaming
    }
}

struct ContentView: View {
    @AppStorage("ollamaAddress") private var ollamaAddress: String = "localhost"
    @AppStorage("ollamaPort") private var ollamaPort: String = "11434"
    @AppStorage("selectedModelName") private var selectedModelName: String = ""
    @StateObject private var sessionManager = SessionManager()
    @State private var showSettings = false
    @State private var showSessions = false
    @State private var chatMessages: [ChatMessage] = []
    @State private var prompt: String = ""
    @FocusState private var isPromptFocused: Bool
    @Namespace private var chatAnimation
    
    // For streaming
    @State private var streamingSession: URLSession?

    var body: some View {
        ZStack {
            // Glassmorphism background for the whole window
            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                .ignoresSafeArea()
            // Main chat area with rounded corners and shadow
            VStack(spacing: 0) {
                // Top bar with settings and sessions buttons
                HStack {
                    Button(action: { showSessions = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            Text("Chats")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: { showSettings = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "gear")
                            Text("Configure Ollama")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
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
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                    }
                    .background(Color.clear)
                    .onChange(of: chatMessages.count) { oldCount, newCount in
                        if let last = chatMessages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                scrollProxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: chatMessages.last?.content) { oldContent, newContent in
                        if let last = chatMessages.last {
                            withAnimation(.linear(duration: 0.1)) {
                                scrollProxy.scrollTo(last.id, anchor: .bottom)
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
            }
            .frame(minWidth: 480, idealWidth: 600, minHeight: 540, idealHeight: 700)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.13), radius: 18, x: 0, y: 8)
            .padding(8)
        }
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
        }
        .onChange(of: sessionManager.currentSessionId) { oldId, newId in
            if let session = sessionManager.sessions.first(where: { $0.id == newId }) {
                chatMessages = session.messages
            }
        }
        .onChange(of: chatMessages) { oldMessages, newMessages in
            sessionManager.saveSession(newMessages)
        }
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
        let urlString = "http://\(ollamaAddress):\(ollamaPort)/api/chat"
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
        let session = URLSession(configuration: .default, delegate: StreamingDelegate(update: { id, content, stats, done in
            updateStreamingMessage(id: id, content: content, stats: stats, done: done)
        }, streamingMsgID: streamingMsgID), delegateQueue: nil)
        streamingSession = session
        let task = session.dataTask(with: request)
        task.resume()
    }

    // Helper to update streaming message from delegate
    func updateStreamingMessage(id: UUID, content: String?, stats: String?, done: Bool) {
        DispatchQueue.main.async {
            guard let idx = chatMessages.firstIndex(where: { $0.id == id }) else { return }
            if let content = content {
                chatMessages[idx].content += content
                // Update content type based on accumulated content
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
    let update: (UUID, String?, String?, Bool) -> Void
    let streamingMsgID: UUID
    private var buffer = Data()
    private var accumulatedContent = ""
    
    init(update: @escaping (UUID, String?, String?, Bool) -> Void, streamingMsgID: UUID) {
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
    
    func processOllamaStreamChunk(_ line: String) {
        guard let data = line.data(using: .utf8) else { return }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let done = json["done"] as? Bool, done {
                let stats = json["eval_count"].flatMap { "Tokens: \($0)" } ?? ""
                let speed = json["eval_duration"].flatMap { d in
                    if let d = d as? Double, let c = json["eval_count"] as? Double, c > 0 {
                        return String(format: "%.1f tok/s", c / (d / 1_000_000_000))
                    }
                    return nil
                } ?? ""
                let statsString = [stats, speed].filter { !$0.isEmpty }.joined(separator: " | ")
                update(streamingMsgID, nil, statsString, true)
            } else if let response = json["message"] as? [String: Any], let content = response["content"] as? String {
                accumulatedContent += content
                // Detect content type from accumulated content
                let contentType = ChatMessage.detectContentType(accumulatedContent)
                update(streamingMsgID, content, nil, false)
            }
        }
    }
}

// MARK: - CustomTextEditor for Enter/Shift+Enter
struct CustomTextEditor: NSViewRepresentable {
    @Binding var text: String
    var onCommit: () -> Void
    
    // Read font size setting
    @AppStorage("chatFontSize") private var chatFontSize: Double = Double(NSFont.systemFontSize(for: .regular))

    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        // Apply user font size
        textView.font = NSFont.systemFont(ofSize: CGFloat(chatFontSize))
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 6, height: 8)
        textView.delegate = context.coordinator
        textView.allowsUndo = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textContainer?.lineFragmentPadding = 0
        return textView
    }
    func updateNSView(_ nsView: NSTextView, context: Context) {
        let currentSize = nsView.font?.pointSize ?? NSFont.systemFontSize(for: .regular)
        let newSize = CGFloat(chatFontSize)
        
        // Update text if different
        if nsView.string != text {
            nsView.string = text
        }
        // Update font size if different
        if abs(currentSize - newSize) > 0.1 {
             nsView.font = NSFont.systemFont(ofSize: newSize)
        }
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CustomTextEditor
        init(_ parent: CustomTextEditor) { self.parent = parent }
        func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                parent.text = textView.string
            }
        }
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if NSEvent.modifierFlags.contains(.shift) {
                    textView.insertNewline(nil)
                } else {
                    parent.onCommit()
                }
                return true
            }
            return false
        }
    }
}

// MARK: - Animated Gradient Border
struct AnimatedGradientBorder: View {
    var cornerRadius: CGFloat
    @State private var animate = false
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [
                        .accentColor, .purple, .blue, .green, .yellow, .orange, .red, .accentColor
                    ]),
                    center: .center,
                    angle: .degrees(animate ? 360 : 0)
                ),
                lineWidth: 2.2
            )
            .opacity(0.7)
            .onAppear {
                withAnimation(Animation.linear(duration: 3.5).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
    }
}

// MARK: - VisualEffectBlur for glassmorphism
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Chat Bubble View

// Helper struct to represent parsed content segments
struct ContentSegment: Identifiable {
    let id = UUID()
    enum SegmentType { case text, code(language: String) }
    let type: SegmentType
    let text: String
}

struct ChatBubble: View {
    let message: ChatMessage
    @State private var showCopyButton = false
    @State private var parsedSegments: [ContentSegment] = []

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.sender == .model {
                Image(systemName: "brain")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .top) // Align icon to top
            }

            VStack(alignment: .leading, spacing: 4) {
                // Render parsed segments instead of just switching on contentType
                ForEach(parsedSegments) { segment in
                    renderSegment(segment)
                }

                if let stats = message.stats {
                    Text(stats)
                        // Use .subheadline size
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2) // Add padding if stats exist
                }
            }
            .padding(12)
            .background(
                message.sender == .user
                    ? AnyView(RoundedRectangle(cornerRadius: 16).fill(Color.accentColor.opacity(0.1)))
                    : AnyView(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                message.isStreaming ?
                AnimatedGradientBorder(cornerRadius: 16)
                : nil
            )

            if message.sender == .user {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .top) // Align icon to top
            }
        }
        .padding(.horizontal, 4)
        .onAppear {
            parseContent()
        }
        .onChange(of: message.content) { _, _ in // Re-parse if content changes (streaming)
            parseContent()
        }
    }

    // Helper view builder to render different segments
    @ViewBuilder
    private func renderSegment(_ segment: ContentSegment) -> some View {
        switch segment.type {
        case .text:
            // Use MarkdownText for text segments to handle potential markdown outside code blocks
            // Ensure text is not empty before rendering
            if !segment.text.isEmpty {
                MarkdownText(content: segment.text)
                     .textSelection(.enabled)
                     .padding(.bottom, parsedSegments.count > 1 ? 4 : 0) // Add spacing between segments
            }
        case .code(let language):
            // Ensure code is not empty before rendering
             if !segment.text.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(language.isEmpty ? "code" : language) // Display language
                            // Use .subheadline size
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if showCopyButton {
                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(segment.text, forType: .string) // Copy only the code
                            }) {
                                Image(systemName: "doc.on.doc")
                                    // Use .subheadline size
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 8)

                    // Pass font size explicitly (though CodeBlock reads AppStorage now,
                    // this ensures consistency if that changes)
                    CodeBlock(content: segment.text, language: language)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 8)
                }
                .background(Color(NSColor.textBackgroundColor).opacity(0.8)) // Slightly different background for code
                .clipShape(RoundedRectangle(cornerRadius: 8)) // Inner rounding for code block
                .onHover { hovering in
                     showCopyButton = hovering
                }
                 .padding(.bottom, parsedSegments.count > 1 ? 4 : 0) // Add spacing between segments
             }
        }
    }


    // Function to parse message content into segments
    private func parseContent() {
        var segments: [ContentSegment] = []
        let content = message.content
        let codeBlockRegex = try! NSRegularExpression(pattern: #"```(?:([\w-]+)\n)?(.*?)```"#, options: [.dotMatchesLineSeparators]) // Regex to find code blocks with optional language

        var lastIndex = content.startIndex
        codeBlockRegex.enumerateMatches(in: content, options: [], range: NSRange(content.startIndex..., in: content)) { match, _, _ in
            guard let match = match, let matchRange = Range(match.range, in: content) else { return }

            // 1. Add text segment before the code block
            if matchRange.lowerBound > lastIndex {
                let textSegment = String(content[lastIndex..<matchRange.lowerBound])
                 if !textSegment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    segments.append(ContentSegment(type: .text, text: textSegment))
                 }
            }

            // 2. Add the code segment
            let languageRange = match.range(at: 1)
            let codeRange = match.range(at: 2)

            let language = (languageRange.location != NSNotFound) ? (content as NSString).substring(with: languageRange) : ""
            let code = (codeRange.location != NSNotFound) ? (content as NSString).substring(with: codeRange) : ""
            
            // Trim leading/trailing newlines from code often added by LLMs
            let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
            segments.append(ContentSegment(type: .code(language: language.lowercased()), text: trimmedCode))


            lastIndex = matchRange.upperBound
        }

        // 3. Add any remaining text segment after the last code block
        if lastIndex < content.endIndex {
            let textSegment = String(content[lastIndex...])
            if !textSegment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                segments.append(ContentSegment(type: .text, text: textSegment))
            }
        }

        // If no code blocks were found, treat the whole content as one segment
        if segments.isEmpty {
             // Determine type based on original message type (fallback)
             switch message.contentType {
                 case .code(let lang): // Should not happen if regex fails, but handle defensively
                     segments.append(ContentSegment(type: .code(language: lang), text: content))
                 case .terminal: // Treat terminal as pre-formatted text (could refine later)
                      segments.append(ContentSegment(type: .code(language: "bash"), text: content)) // Render terminal as bash code
                 case .markdown, .text:
                      segments.append(ContentSegment(type: .text, text: content))
             }
        }


        self.parsedSegments = segments
    }
}

#Preview {
    ContentView()
} 
