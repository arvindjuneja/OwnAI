import SwiftUI

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

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("ollamaAddress") private var ollamaAddress: String = "localhost"
    @AppStorage("ollamaPort") private var ollamaPort: String = "11434"
    @AppStorage("selectedModelName") private var selectedModelName: String = ""
    
    @State private var connectionStatus: String = "Disconnected"
    @State private var isTestingConnection: Bool = false
    @State private var availableModels: [OllamaModel] = []
    @State private var isFetchingModels: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Ollama Server Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray).opacity(0.8)
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
                .help("Close Settings")
            }

            GroupBox("Connection Details") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Server Address:")
                        TextField("e.g., localhost or 192.168.1.10", text: $ollamaAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    HStack {
                        Text("Port:")
                        TextField("e.g., 11434", text: $ollamaPort)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: 100)
                    }
                    HStack {
                        Button(action: {
                            connectToOllama()
                        }) {
                            Text("Save & Connect")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isTestingConnection || isFetchingModels)
                        
                        Spacer()
                        
                        Button(action: {
                            testConnection(fetchModelsOnSuccess: true)
                        }) {
                            Text(isTestingConnection ? "Testing..." : "Test Connection")
                        }
                        .disabled(isTestingConnection || isFetchingModels)
                    }
                    
                    HStack {
                        Text("Status:")
                            .fontWeight(.semibold)
                        Text(connectionStatus)
                            .foregroundColor(statusColor)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        if isTestingConnection || isFetchingModels {
                            ProgressView().scaleEffect(0.7).padding(.leading, 5)
                        }
                    }
                }
                .padding(.vertical, 5)
            }
            
            GroupBox("Model Selection") {
                VStack(alignment: .leading, spacing: 8) {
                    if availableModels.isEmpty && !isFetchingModels && !connectionStatus.starts(with: "Connected") {
                        Text("Connect to Ollama server to see available models.")
                            .foregroundColor(.secondary)
                            .padding(.vertical)
                    } else if isFetchingModels {
                        HStack {
                            ProgressView().scaleEffect(0.7)
                            Text("Fetching models...").padding(.leading, 5)
                        }.padding(.vertical)
                    } else if availableModels.isEmpty && connectionStatus.starts(with: "Connected") {
                         Text("No models found on the server. Install models using Ollama CLI.")
                            .foregroundColor(.secondary)
                            .padding(.vertical)
                    } else {
                        HStack {
                            Text("Selected Model:")
                            Picker("", selection: $selectedModelName) {
                                ForEach(availableModels) { model in
                                    Text(model.name).tag(model.name)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .disabled(isFetchingModels)
                        
                        Text("Chat will use: \(selectedModelName.isEmpty ? "None selected" : selectedModelName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .padding(.vertical, 5)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding()
        .frame(minWidth: 450, idealWidth: 500, maxWidth: .infinity, minHeight: 420, idealHeight: 480, maxHeight: .infinity, alignment: .top)
        .onAppear {
            testConnection(fetchModelsOnSuccess: true)
        }
    }

    var statusColor: Color {
        if connectionStatus.starts(with: "Connected") { return .green }
        if connectionStatus.starts(with: "Error") || connectionStatus == "Disconnected" { return .red }
        return .primary
    }

    func connectToOllama() {
        testConnection(fetchModelsOnSuccess: true)
    }

    func testConnection(fetchModelsOnSuccess: Bool = false) {
        guard !isTestingConnection else { return }
        isTestingConnection = true
        connectionStatus = "Checking http://\(ollamaAddress):\(ollamaPort)..."
        availableModels = [] // Clear models on new test

        guard let portInt = Int(ollamaPort), portInt > 0 && portInt <= 65535 else {
            self.connectionStatus = "Error: Invalid port number."
            isTestingConnection = false
            return
        }
        guard var components = URLComponents(string: "http://\(ollamaAddress)") else {
            self.connectionStatus = "Error: Invalid server address format."
            isTestingConnection = false
            return
        }
        components.port = portInt
        components.path = "/api/version"

        guard let url = components.url else {
            self.connectionStatus = "Error: Could not construct URL."
            isTestingConnection = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isTestingConnection = false
                if let error = error { self.connectionStatus = "Error: \(error.localizedDescription)"; return }
                guard let httpResponse = response as? HTTPURLResponse else { self.connectionStatus = "Error: Invalid response from server."; return }
                guard (200...299).contains(httpResponse.statusCode) else { self.connectionStatus = "Error: Server returned status \(httpResponse.statusCode)"; return }
                guard let mimeType = httpResponse.mimeType, mimeType == "application/json", let data = data else { self.connectionStatus = "Error: No data or incorrect data format."; return }

                do {
                    let decodedResponse = try JSONDecoder().decode(OllamaVersionResponse.self, from: data)
                    self.connectionStatus = "Connected to Ollama v\(decodedResponse.version)"
                    if fetchModelsOnSuccess {
                        fetchModels()
                    }
                } catch {
                    self.connectionStatus = "Error: Could not decode version. \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func fetchModels() {
        guard !isFetchingModels else { return }
        isFetchingModels = true
        
        guard let portInt = Int(ollamaPort), portInt > 0 && portInt <= 65535 else {
            self.connectionStatus = "Error: Invalid port for fetching models."; isFetchingModels = false; return
        }
        guard var components = URLComponents(string: "http://\(ollamaAddress)") else {
            self.connectionStatus = "Error: Invalid server address for fetching models."; isFetchingModels = false; return
        }
        components.port = portInt
        components.path = "/api/tags" // Endpoint to get model tags

        guard let url = components.url else {
            self.connectionStatus = "Error: Could not construct URL for models."; isFetchingModels = false; return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10 // Longer timeout for potentially larger response

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isFetchingModels = false
                if let error = error { self.connectionStatus = "Error fetching models: \(error.localizedDescription)"; return }
                guard let httpResponse = response as? HTTPURLResponse else { self.connectionStatus = "Error: Invalid model response."; return }
                guard (200...299).contains(httpResponse.statusCode) else { self.connectionStatus = "Error: Model server status \(httpResponse.statusCode)"; return }
                guard let mimeType = httpResponse.mimeType, mimeType == "application/json", let data = data else { self.connectionStatus = "Error: No model data or format."; return }

                do {
                    let decodedResponse = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
                    self.availableModels = decodedResponse.models.sorted(by: { $0.name < $1.name })
                    if !selectedModelName.isEmpty && !self.availableModels.contains(where: { $0.name == selectedModelName }) {
                        // If previously selected model is not in the new list, clear selection or select first
                        selectedModelName = self.availableModels.first?.name ?? ""
                    } else if selectedModelName.isEmpty && !self.availableModels.isEmpty {
                        selectedModelName = self.availableModels.first?.name ?? ""
                    }
                    // connectionStatus doesn't need to change here unless there's an error specific to fetching models while already connected.
                } catch {
                    self.connectionStatus = "Error: Could not decode models. \(error.localizedDescription)"
                    self.availableModels = []
                }
            }
        }.resume()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 