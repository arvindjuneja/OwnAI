import Foundation
import SwiftUI

class SessionManager: ObservableObject {
    @Published var sessions: [ChatSession] = []
    @Published var currentSessionId: UUID?
    
    private let sessionsKey = "chat_sessions"
    private let currentSessionKey = "current_session"
    
    init() {
        loadSessions()
    }
    
    func createNewSession() -> UUID {
        let session = ChatSession(id: UUID(), messages: [], createdAt: Date())
        sessions.append(session)
        currentSessionId = session.id
        saveSessions()
        return session.id
    }
    
    func saveSession(_ messages: [ChatMessage]) {
        guard let sessionId = currentSessionId,
              let index = sessions.firstIndex(where: { $0.id == sessionId }) else {
            return
        }
        sessions[index].messages = messages
        saveSessions()
    }
    
    func loadSession(_ id: UUID) {
        currentSessionId = id
        UserDefaults.standard.set(id.uuidString, forKey: currentSessionKey)
    }
    
    func deleteSession(_ id: UUID) {
        sessions.removeAll { $0.id == id }
        if currentSessionId == id {
            currentSessionId = sessions.first?.id
        }
        saveSessions()
    }
    
    func renameSession(id: UUID, newTitle: String) {
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            sessions[index].title = trimmedTitle.isEmpty ? nil : trimmedTitle
            saveSessions()
        }
    }
    
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
        if let currentId = currentSessionId {
            UserDefaults.standard.set(currentId.uuidString, forKey: currentSessionKey)
        }
    }
    
    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([ChatSession].self, from: data) {
            sessions = decoded
        }
        if let currentIdString = UserDefaults.standard.string(forKey: currentSessionKey),
           let currentId = UUID(uuidString: currentIdString) {
            currentSessionId = currentId
        } else if let firstSession = sessions.first {
            currentSessionId = firstSession.id
        }
    }
}

struct ChatSession: Codable, Identifiable {
    let id: UUID
    var messages: [ChatMessage]
    let createdAt: Date
    var title: String?

    var displayTitle: String {
        title ?? (messages.first.map { String($0.content.prefix(30)) } ?? "New Chat")
    }
    
    enum CodingKeys: String, CodingKey {
        case id, messages, createdAt, title
    }

    init(id: UUID, messages: [ChatMessage], createdAt: Date, title: String? = nil) {
        self.id = id
        self.messages = messages
        self.createdAt = createdAt
        self.title = title
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        messages = try container.decode([ChatMessage].self, forKey: .messages)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        title = try container.decodeIfPresent(String.self, forKey: .title)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(messages, forKey: .messages)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(title, forKey: .title)
    }
}

// Make ChatMessage Codable
extension ChatMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case id, sender, content, contentType, timestamp, stats, isStreaming
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let _ = try container.decode(UUID.self, forKey: .id)
        let sender = try container.decode(ChatSender.self, forKey: .sender)
        let content = try container.decode(String.self, forKey: .content)
        let contentType = try container.decode(MessageContentType.self, forKey: .contentType)
        let timestamp = try container.decode(Date.self, forKey: .timestamp)
        let stats = try container.decodeIfPresent(String.self, forKey: .stats)
        let isStreaming = try container.decode(Bool.self, forKey: .isStreaming)
        self.init(sender: sender, content: content, contentType: contentType, timestamp: timestamp, stats: stats, isStreaming: isStreaming)
        // id is auto-generated in struct, so we can't set it directly
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(sender, forKey: .sender)
        try container.encode(content, forKey: .content)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(stats, forKey: .stats)
        try container.encode(isStreaming, forKey: .isStreaming)
    }
}

// Make ChatSender Codable
extension ChatSender: Codable {
    enum CodingKeys: String, CodingKey {
        case type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "user": self = .user
        case "model": self = .model
        default: throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid sender type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .user: try container.encode("user", forKey: .type)
        case .model: try container.encode("model", forKey: .type)
        }
    }
}

// Make MessageContentType Codable
extension MessageContentType: Codable {
    enum CodingKeys: String, CodingKey {
        case type, language
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "text": self = .text
        case "code":
            let language = try container.decode(String.self, forKey: .language)
            self = .code(language: language)
        case "terminal": self = .terminal
        case "markdown": self = .markdown
        default: throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid content type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text:
            try container.encode("text", forKey: .type)
        case .code(let language):
            try container.encode("code", forKey: .type)
            try container.encode(language, forKey: .language)
        case .terminal:
            try container.encode("terminal", forKey: .type)
        case .markdown:
            try container.encode("markdown", forKey: .type)
        }
    }
} 