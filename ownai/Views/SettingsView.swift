import SwiftUI

// Ollama API response structs moved to Models/OllamaModels.swift

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("ollamaAddress") private var ollamaAddress: String = "localhost"
    @AppStorage("ollamaPort") private var ollamaPort: String = "11434"
    @AppStorage("selectedModelName") private var selectedModelName: String = ""
    
    @AppStorage("connectionStatus") private var connectionStatus: String = "Disconnected"
    @State private var isTestingConnection: Bool = false
    @State private var availableModels: [OllamaModel] = []
    @State private var isFetchingModels: Bool = false
    @State private var ollamaVersion: String?
    @State private var hasUnappliedChanges: Bool = false
    @State private var testConnectionTask: URLSessionDataTask? // Task for testConnection
    @State private var fetchModelsTask: URLSessionDataTask?    // Task for fetchModels

    // Font size settings
    @AppStorage("chatFontSize") private var chatFontSize: Double = Double(NSFont.systemFontSize(for: .regular))
    @AppStorage("codeFontSize") private var codeFontSize: Double = Double(NSFont.systemFontSize(for: .regular))
    @AppStorage("lineSpacing") private var lineSpacing: Double = 5.0

    // Appearance setting
    @AppStorage("preferredAppearance_v1") private var preferredAppearance: AppearanceMode = .dark

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
                    .onSubmit { connectToOllama() }
                    .onChange(of: ollamaAddress) { oldValue, newValue in handleAddressOrPortChange() }
                
                TextField("Port:", text: $ollamaPort, prompt: Text("e.g., 11434"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit { connectToOllama() }
                    .onChange(of: ollamaPort) { oldValue, newValue in handleAddressOrPortChange() }
                    // Optionally, constrain port field width if it becomes too wide by default
                    // .frame(maxWidth: 100) 

                HStack {
                    Button(action: {
                        if connectionStatus.starts(with: "Connected") {
                            disconnectOllama()
                        } else {
                            connectToOllama()
                        }
                    }) {
                        Text(primaryButtonLabel)
                            .foregroundColor( (primaryButtonLabel == "Connecting...") ? nil : .white )
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isTestingConnection || isFetchingModels)
                    
                    Spacer()
                    
                    // "Test Connection" button removed
                }
                
                HStack {
                    Text("Status:")
                        .fontWeight(.semibold)
                    Text(connectionStatus)
                        .foregroundColor(statusColor)
                        .lineLimit(nil)
                        .frame(minHeight: 30)
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
            Section(header: Text("Theme").font(.headline)) {
                Picker("Appearance:", selection: $preferredAppearance) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented) // Or .automatic / .menu
            }
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

    // Computed property for the primary button's label
    private var primaryButtonLabel: String {
        if isTestingConnection || isFetchingModels {
            return "Connecting..."
        } else if hasUnappliedChanges {
            return "Connect"
        } else if connectionStatus.starts(with: "Connected") {
            return "Disconnect"
        } else if connectionStatus.starts(with: "Error") {
            return "Try Again"
        } else { // Covers "Disconnected" and any other initial/unknown states
            return "Connect"
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
        testConnectionTask?.cancel() // Cancel any existing test connection task
        fetchModelsTask?.cancel()    // Also cancel model fetching if it was somehow active
        
        guard !isTestingConnection else { return } // Should be redundant if task logic is correct, but safe
        isTestingConnection = true
        hasUnappliedChanges = false // Attempting to apply changes now
        ollamaVersion = nil // Reset stored version
        
        let rawUserAddress = ollamaAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawUserPort = ollamaPort.trimmingCharacters(in: .whitespacesAndNewlines)

        var addressForConnection = rawUserAddress
        if addressForConnection.lowercased() == "localhost" {
            addressForConnection = "127.0.0.1" // Force IPv4 for localhost
        }

        connectionStatus = "Checking \(rawUserAddress):\(rawUserPort)..."
        availableModels = [] // Clear models on new test

        guard !rawUserAddress.isEmpty else {
            self.connectionStatus = "Error: Server address cannot be empty."
            isTestingConnection = false
            return
        }
        
        guard let portForConnection = Int(rawUserPort), portForConnection > 0 && portForConnection <= 65535 else {
            self.connectionStatus = "Error: Invalid port number."
            isTestingConnection = false
            return
        }
        
        var urlStringForComponents: String
        if addressForConnection.lowercased().hasPrefix("http://") || addressForConnection.lowercased().hasPrefix("https://") {
            urlStringForComponents = addressForConnection
        } else {
            urlStringForComponents = "http://" + addressForConnection // Default to http
        }
        
        guard var components = URLComponents(string: urlStringForComponents) else {
            self.connectionStatus = "Error: Invalid server address format. Ensure it's a valid hostname or IP, optionally prefixed with http:// or https://."
            isTestingConnection = false
            return
        }
        
        components.port = portForConnection // Always use the port from the dedicated field
        components.path = "/api/version"

        guard let url = components.url else {
            self.connectionStatus = "Error: Could not construct final URL."
            isTestingConnection = false
            return
        }

        // Status message updated just before the request
        let schemeString = components.scheme ?? "http"
        let hostString = components.host ?? rawUserAddress
        let portString = components.port.map { String($0) } ?? rawUserPort
        let attemptID = String(UUID().uuidString.prefix(4))
        connectionStatus = "Checking (#\(attemptID)) \(schemeString)://\(hostString):\(portString)..."

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5 // 5 seconds timeout

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.testConnectionTask = nil // Clear task reference in completion
                self.isTestingConnection = false // Ensure this is also set in completion
                if let error = error {
                    let nsError = error as NSError
                    self.connectionStatus = formatErrorMessage(nsError)
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
                    let version = decodedResponse.version
                    self.ollamaVersion = version
                    
                    if fetchModelsOnSuccess {
                        self.connectionStatus = "Connected to Ollama v\(version). Fetching models..."
                        fetchModels()
                    } else {
                        self.connectionStatus = "Connected to Ollama v\(version)."
                    }
                } catch {
                    self.connectionStatus = "Error: Could not decode server version response."
                }
            }
        }.resume()
    }

    func fetchModels() {
        fetchModelsTask?.cancel() // Cancel any existing fetch models task

        guard !isFetchingModels else { return } // Should be redundant, but safe
        isFetchingModels = true
        
        let rawUserAddress = ollamaAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawUserPort = ollamaPort.trimmingCharacters(in: .whitespacesAndNewlines)

        var addressForConnection = rawUserAddress
        if addressForConnection.lowercased() == "localhost" {
            addressForConnection = "127.0.0.1" // Force IPv4 for localhost
        }
        
        guard !rawUserAddress.isEmpty else {
            // This state should ideally be caught by testConnection first, but as a safeguard:
            connectionStatus = "Error: Server address cannot be empty for fetching models."
            isFetchingModels = false
            return
        }
        
        guard let portForConnection = Int(rawUserPort), portForConnection > 0 && portForConnection <= 65535 else {
            connectionStatus = "Error: Invalid port number for fetching models."
            isFetchingModels = false
            return
        }
        
        var urlStringForComponents: String
        if addressForConnection.lowercased().hasPrefix("http://") || addressForConnection.lowercased().hasPrefix("https://") {
            urlStringForComponents = addressForConnection
        } else {
            urlStringForComponents = "http://" + addressForConnection // Default to http
        }
        
        guard var components = URLComponents(string: urlStringForComponents) else {
            connectionStatus = "Error: Invalid server address format for fetching models."
            isFetchingModels = false
            return
        }
        
        components.port = portForConnection // Always use the port from the dedicated field
        components.path = "/api/tags"

        guard let url = components.url else {
            connectionStatus = "Error: Could not construct URL for fetching models."
            isFetchingModels = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10 // Longer timeout for model list

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.fetchModelsTask = nil // Clear task reference in completion
                self.isFetchingModels = false // Ensure this is also set in completion
                if let error = error {
                    let nsError = error as NSError
                    self.connectionStatus = formatErrorMessage(nsError, forModelFetching: true)
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
                    
                    if let version = self.ollamaVersion {
                        self.connectionStatus = "Connected to Ollama v\(version) - Models loaded."
                    } else {
                        self.connectionStatus = "Connected - Models loaded."
                    }
                } catch {
                    self.connectionStatus = "Error: Could not decode model list."
                }
            }
        }.resume()
    }

    // Helper function to reset state when address or port changes
    private func handleAddressOrPortChange() {
        // Only mark that changes are pending, don't change actual connectionStatus here
        hasUnappliedChanges = true
    }

    // Function to handle disconnecting
    private func disconnectOllama() {
        testConnectionTask?.cancel()
        testConnectionTask = nil
        fetchModelsTask?.cancel()
        fetchModelsTask = nil

        isTestingConnection = false
        isFetchingModels = false
        hasUnappliedChanges = false
        connectionStatus = "Disconnected"
        ollamaVersion = nil
        availableModels = []
        // We don't clear ollamaAddress or ollamaPort here, 
        // so user can easily reconnect or modify slightly.
    }

    // Helper function to format error messages for the user
    private func formatErrorMessage(_ error: NSError, forModelFetching: Bool = false) -> String {
        let prefix = forModelFetching ? "Error fetching models: " : "Error: "
        var message = ""

        if error.domain == NSURLErrorDomain {
            switch error.code {
            case NSURLErrorCannotConnectToHost: // -1004
                message = prefix + "Connection failed. Ensure Ollama is running at the address/port and check firewall settings."
            case NSURLErrorTimedOut: // -1001
                message = prefix + "Connection timed out. Check server responsiveness and network."
            case NSURLErrorCannotFindHost: // -1003
                message = prefix + "Cannot find the server. Verify the address."
            case NSURLErrorNotConnectedToInternet: // -1009
                message = prefix + "Not connected to the internet. Please check your network."
            default:
                message = prefix + "\\(error.localizedDescription) (Domain: \\(error.domain))"
            }
        } else if error.domain == NSPOSIXErrorDomain {
             switch error.code {
             case 61: // ECONNREFUSED
                 message = prefix + "Connection refused by server. Ensure Ollama is running and listening."
             default:
                message = prefix + "\\(error.localizedDescription) (Domain: \\(error.domain))"
             }
        } else {
            message = prefix + "\\(error.localizedDescription) (Domain: \\(error.domain))"
        }
        // Code part removed to avoid interpolation issues
        return message
    }
} 