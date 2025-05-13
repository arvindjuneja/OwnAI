import SwiftUI

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

    // Accessing AppStorage for font size. Ensure this is the desired behavior.
    // If ChatFontSize is specific to chat bubbles, it's fine here.
    // If it's global, it should be passed in or accessed from an environment object.
    // For now, assuming it's okay as it was in ContentView.
    // @AppStorage("chatFontSize") private var chatFontSize: Double = Double(NSFont.systemFontSize(for: .regular))


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
                AnimatedGradientBorder(cornerRadius: 16) // Depends on AnimatedGradientBorder
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
                MarkdownText(content: segment.text) // Depends on Down library
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
                    CodeBlock(content: segment.text, language: language) // Depends on CodeBlock from Formatting.swift
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
        let codeBlockRegex = try! NSRegularExpression(pattern: #"```(?:([\w-]+)\\n)?(.*?)```"#, options: [.dotMatchesLineSeparators]) // Regex to find code blocks with optional language

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
    
    // ChatMessage is defined in ContentView.swift. For ChatBubble.swift to compile independently
    // or be more modular, ChatMessage might also need to be in its own file or passed differently.
    // For now, this will work as it's part of the same target.
} 