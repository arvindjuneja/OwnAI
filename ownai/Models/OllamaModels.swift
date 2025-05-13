import Foundation

// MARK: - Ollama API Response Models

// Codable structs for Ollama API responses
struct OllamaVersionResponse: Codable {
    let version: String
}

struct OllamaModel: Codable, Identifiable, Hashable {
    let name: String
    // Add other fields like modified_at, size, digest if needed later
    // For Identifiable, 'name' can serve as id if unique, or add a UUID if names can repeat (though model names are usually unique)
    var id: String { name }
}

struct OllamaTagsResponse: Codable {
    let models: [OllamaModel]
} 