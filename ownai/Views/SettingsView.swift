import SwiftUI

// Ollama API response structs moved to Models/OllamaModels.swift

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("ollamaAddress") private var ollamaAddress: String = "localhost"
    @AppStorage("ollamaPort") private var ollamaPort: String = "11434"
    @AppStorage("selectedModelName") private var selectedModelName: String = ""
    
    @State private var connectionStatus: String = "Disconnected"
    @State private var isTestingConnection: Bool = false
    @State private var availableModels: [OllamaModel] = []
    @State private var isFetchingModels: Bool = false

    // Font size settings
    @AppStorage("chatFontSize") private var chatFontSize: Double = Double(NSFont.systemFontSize(for: .regular))
    @AppStorage("codeFontSize") private var codeFontSize: Double = Double(NSFont.systemFontSize(for: .regular))
    @AppStorage("lineSpacing") private var lineSpacing: Double = 5.0

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

            TabView {
                connectionSettingsTab
                    .tabItem {
                        Label("Connection", systemImage: "network")
                    }
                
                appearanceSettingsTab
                    .tabItem {
                        Label("Appearance", systemImage: "paintbrush")
                    }
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
        .frame(minWidth: 450, idealWidth: 480, maxWidth: .infinity, minHeight: 480, idealHeight: 520, maxHeight: .infinity, alignment: .top)
        .onAppear {
            testConnection(fetchModelsOnSuccess: true)
        }
    }

    var connectionSettingsTab: some View {
        Form {
            Section(header: Text("Connection Details").font(.headline)) {
                TextField("Server Address:", text: $ollamaAddress, prompt: Text("e.g., localhost or 192.168.1.10"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Port:", text: $ollamaPort, prompt: Text("e.g., 11434"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    // Optionally, constrain port field width if it becomes too wide by default
                    // .frame(maxWidth: 100) 

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
                    // Removed fixed width from Status label to let HStack manage alignment
                    Text(connectionStatus)
                        .foregroundColor(statusColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if isTestingConnection || isFetchingModels {
                        ProgressView().scaleEffect(0.7).padding(.leading, 5)
                    }
                }
            }
            
            Section(header: Text("Model Selection").font(.headline)) {
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
                    Picker("Selected Model:", selection: $selectedModelName) {
                        ForEach(availableModels) { model in
                            Text(model.name).tag(model.name)
                        }
                    }
                    // .labelsHidden() // Re-evaluate if this is needed after Form relayout
                    // Removed frame modifiers to let Picker and Form manage width
                    .disabled(isFetchingModels)
                    
                    Text("Chat will use: \(selectedModelName.isEmpty ? "None selected" : selectedModelName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        }
        .padding()
    }
    
    var appearanceSettingsTab: some View {
        Form {
            Section(header: Text("Font Sizes").font(.headline)) {
                Slider(value: $chatFontSize, in: 10...24, step: 1) {
                    Text("Chat Text Font Size: \(Int(chatFontSize))pt")
                }
                Slider(value: $codeFontSize, in: 8...20, step: 1) {
                    Text("Code Block Font Size: \(Int(codeFontSize))pt")
                }
            }
            Section(header: Text("Spacing").font(.headline)) {
                Slider(value: $lineSpacing, in: 0...15, step: 1) {
                    Text("Line Spacing: \(Int(lineSpacing))pt")
                }
            }
        }
        .padding()
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
        connectionStatus = "Checking http://\(ollamaAddress.trimmingCharacters(in: .whitespacesAndNewlines)):\(ollamaPort.trimmingCharacters(in: .whitespacesAndNewlines))..."
        availableModels = [] // Clear models on new test

        let trimmedAddress = ollamaAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPort = ollamaPort.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedAddress.isEmpty else {
            self.connectionStatus = "Error: Server address cannot be empty."
            isTestingConnection = false
            return
        }
        guard let portInt = Int(trimmedPort), portInt > 0 && portInt <= 65535 else {
            self.connectionStatus = "Error: Invalid port number."
            isTestingConnection = false
            return
        }
        
        guard var components = URLComponents(string: "http://\(trimmedAddress)") else {
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
        request.timeoutInterval = 5 // 5 seconds timeout

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isTestingConnection = false
                if let error = error {
                    self.connectionStatus = "Error: \(error.localizedDescription)"
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.connectionStatus = "Error: Invalid response from server."
                    return
                }
                guard httpResponse.statusCode == 200 else {
                    self.connectionStatus = "Error: Server returned status \(httpResponse.statusCode)"
                    if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                        print("Error response body: \(responseBody)")
                    }
                    return
                }
                guard let data = data else {
                    self.connectionStatus = "Error: No data received from server."
                    return
                }
                do {
                    let decodedResponse = try JSONDecoder().decode(OllamaVersionResponse.self, from: data)
                    self.connectionStatus = "Connected to Ollama v\(decodedResponse.version)"
                    if fetchModelsOnSuccess {
                        fetchModels()
                    }
                } catch {
                    self.connectionStatus = "Error: Could not decode server version response."
                }
            }
        }.resume()
    }

    func fetchModels() {
        guard !isFetchingModels else { return }
        isFetchingModels = true
        
        let trimmedAddress = ollamaAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPort = ollamaPort.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedAddress.isEmpty, let portInt = Int(trimmedPort) else {
            connectionStatus = "Error: Invalid server address or port for fetching models."
            isFetchingModels = false
            return
        }
        
        guard var components = URLComponents(string: "http://\(trimmedAddress)") else {
             connectionStatus = "Error: Invalid server address format for fetching models."
            isFetchingModels = false
            return
        }
        components.port = portInt
        components.path = "/api/tags"

        guard let url = components.url else {
            connectionStatus = "Error: Could not construct URL for fetching models."
            isFetchingModels = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10 // Longer timeout for model list

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isFetchingModels = false
                if let error = error {
                    self.connectionStatus = "Error fetching models: \(error.localizedDescription)"
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    self.connectionStatus = "Error: Could not fetch models (status: \((response as? HTTPURLResponse)?.statusCode ?? 0))."
                    return
                }
                guard let data = data else {
                    self.connectionStatus = "Error: No data received when fetching models."
                    return
                }
                do {
                    let decodedResponse = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
                    self.availableModels = decodedResponse.models.sorted(by: { $0.name < $1.name })
                    if !availableModels.isEmpty && (selectedModelName.isEmpty || !availableModels.contains(where: { $0.name == selectedModelName })) {
                        selectedModelName = availableModels.first?.name ?? ""
                    }
                    // Update connection status if it was just a generic connected message
                    if self.connectionStatus.starts(with: "Connected to Ollama") {
                         self.connectionStatus += " - Models loaded."
                    }
                } catch {
                    self.connectionStatus = "Error: Could not decode model list."
                }
            }
        }.resume()
    }
} 