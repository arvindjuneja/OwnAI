import Foundation

// MARK: - Chat Message Enums and Struct
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
        // More robust markdown checks can be added (e.g., for lists, bold, italic)
        if content.contains("# ") || content.contains("* ") || content.contains("> ") || 
           content.range(of: #"\[.*\](.*)"#, options: .regularExpression) != nil { // Basic link check
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