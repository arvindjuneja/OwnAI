//
//  ContentView.swift
//  ownai
//
//  Created by Arvind Juneja on 12/05/2025.
//

import SwiftUI

// MARK: - Chat Message Model
enum ChatSender {
    case user, model
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let sender: ChatSender
    var content: String
    let isCode: Bool
    let timestamp: Date
    var stats: String? = nil // For verbose/token stats
    var isStreaming: Bool = false // For animated border
}

struct ContentView: View {
    @AppStorage("ollamaAddress") private var ollamaAddress: String = "localhost"
    @AppStorage("ollamaPort") private var ollamaPort: String = "11434"
    @AppStorage("selectedModelName") private var selectedModelName: String = ""

    @State private var chatMessages: [ChatMessage] = [
        ChatMessage(sender: .model, content: "Hi! I'm OwnAI. How can I help you today?", isCode: false, timestamp: Date())
    ]
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
                    .onChange(of: chatMessages.count) {
                        if let last = chatMessages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                scrollProxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: chatMessages.last?.content) { _ in
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
        .onAppear { isPromptFocused = true }
    }
    
    // MARK: - Send Prompt
    func sendPrompt() {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !selectedModelName.isEmpty else { return }
        let userMsg = ChatMessage(sender: .user, content: trimmed, isCode: false, timestamp: Date())
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
        var streamingMsg = ChatMessage(sender: .model, content: "", isCode: false, timestamp: Date(), isStreaming: true)
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
                update(streamingMsgID, content, nil, false)
            }
        }
    }
}

// MARK: - CustomTextEditor for Enter/Shift+Enter
struct CustomTextEditor: NSViewRepresentable {
    @Binding var text: String
    var onCommit: () -> Void
    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.font = NSFont.systemFont(ofSize: 16)
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
        if nsView.string != text {
            nsView.string = text
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
struct ChatBubble: View {
    let message: ChatMessage
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.sender == .model {
                Image(systemName: "sparkles")
                    .foregroundColor(.accentColor)
                    .padding(.top, 2)
            }
            VStack(alignment: .leading, spacing: 4) {
                if message.isCode {
                    Text(message.content)
                        .font(.system(.body, design: .monospaced))
                        .padding(10)
                        .background(Color(NSColor.textBackgroundColor).opacity(0.93))
                        .cornerRadius(7)
                } else {
                    Text(message.content)
                        .font(.system(size: 16, weight: message.sender == .model ? .semibold : .regular))
                        .foregroundColor(message.sender == .user ? .primary : Color.primary.opacity(0.92))
                        .padding(10)
                        .background(message.sender == .user ? Color(NSColor.controlAccentColor).opacity(0.13) : Color(NSColor.textBackgroundColor).opacity(0.93))
                        .cornerRadius(9)
                        .overlay(
                            // Animated border if streaming
                            message.isStreaming && message.sender == .model ? AnyView(AnimatedGradientBorder(cornerRadius: 9)) : AnyView(EmptyView())
                        )
                }
                if let stats = message.stats, message.sender == .model {
                    Text(stats)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
            if message.sender == .user {
                Image(systemName: "person.crop.circle")
                    .foregroundColor(.gray)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 2)
    }
}

#Preview {
    ContentView()
} 