import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    // Ollama Connection Settings
    @AppStorage("ollamaAddress") private var ollamaAddress: String = "localhost"
    @AppStorage("ollamaPort") private var ollamaPort: String = "11434"
    @State private var connectionStatus: String = "Idle"
    @State private var ollamaVersion: String = ""
    @State private var availableModels: [String] = []
    @AppStorage("selectedModelName") private var selectedModelName: String = ""
    
    // Appearance Settings
    @AppStorage("chatFontSize") private var chatFontSize: Double = Double(NSFont.systemFontSize(for: .regular))
    @AppStorage("chatLineSpacing") private var chatLineSpacing: Double = 4.0
    @AppStorage("chatParagraphSpacing") private var chatParagraphSpacing: Double = 8.0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("OwnAI Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.ultraThinMaterial)
            
            Divider()

            // Form Content
            Form {
                // Connection Section
                Section("Ollama Connection") {
                    HStack {
                        TextField("Address", text: $ollamaAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Port", text: $ollamaPort)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 70)
                    }
                    
                    HStack {
                        Button("Test Connection", action: testConnection)
                        Spacer()
                        Text(connectionStatus)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    if !ollamaVersion.isEmpty {
                        Text("Ollama Version: \(ollamaVersion)")
                            .font(.callout)
                    }
                }
                
                // Model Selection Section
                Section("Model Selection") {
                    Picker("Selected Model", selection: $selectedModelName) {
                        Text("None Selected").tag("")
                        ForEach(availableModels, id: \.self) { modelName in
                            Text(modelName).tag(modelName)
                        }
                    }
                    Button("Refresh Models", action: fetchModels)
                }
                
                // Appearance Section
                Section("Appearance") {
                     Stepper("Font Size: \(chatFontSize, specifier: "%.0f") pt", 
                             value: $chatFontSize, 
                             in: 10...24, 
                             step: 1)
                    
                     Stepper("Line Spacing: \(chatLineSpacing, specifier: "%.1f")", 
                             value: $chatLineSpacing, 
                             in: 0...12, 
                             step: 0.5)
                    
                     Stepper("Paragraph Spacing: \(chatParagraphSpacing, specifier: "%.1f")", 
                             value: $chatParagraphSpacing, 
                             in: 0...20, 
                             step: 1.0)
                }

            }
            .padding()
            .frame(minWidth: 400, idealWidth: 450, minHeight: 350)
        }
        .onAppear {
            testConnection() // Test connection on appear
            fetchModels()
        }
    }
    
    // NOTE: You need to provide the actual implementation for these functions
    // if they were lost or are defined elsewhere.
    func testConnection() {
        // Placeholder - Add actual implementation
        connectionStatus = "Testing..."
        // Add network call logic here...
        // On success:
        // connectionStatus = "Connected"
        // ollamaVersion = "..."
        // On failure:
        // connectionStatus = "Connection Failed"
        // ollamaVersion = ""
    }
    
    func fetchModels() {
        // Placeholder - Add actual implementation
        // Add network call to /api/tags logic here...
        // On success:
        // self.availableModels = ["model1", "model2"] // Update with fetched models
        // On failure:
        // print("Failed to fetch models")
    }
}

// Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 