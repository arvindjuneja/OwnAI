import SwiftUI

// Define a simple Codable struct for the Ollama version response
struct OllamaVersionResponse: Codable {
    let version: String
}

struct SettingsView: View {
    // Add environment variable for presentation mode
    @Environment(\.dismiss) private var dismiss
    
    // Use AppStorage to persist settings
    @AppStorage("ollamaAddress") private var ollamaAddress: String = "localhost"
    @AppStorage("ollamaPort") private var ollamaPort: String = "11434"
    
    @State private var connectionStatus: String = "Disconnected"
    @State private var isTestingConnection: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title section with close button
            HStack {
                Text("Ollama Server Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
                .help("Close Settings")
            }

            GroupBox {
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
                            .onChange(of: ollamaPort) { newValue in
                                // Basic validation or formatting if desired
                            }
                    }
                }
            }

            HStack {
                Button(action: {
                    connectToOllama()
                }) {
                    Text("Save & Connect")
                        .padding(.horizontal)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isTestingConnection)
                
                Spacer()
                
                Button(action: {
                    testConnection()
                }) {
                    Text(isTestingConnection ? "Testing..." : "Test Connection")
                }
                .disabled(isTestingConnection)
            }

            Divider()

            HStack {
                Text("Status:")
                    .fontWeight(.semibold)
                Text(connectionStatus)
                    .foregroundColor(statusColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            if isTestingConnection {
                ProgressView()
                    .scaleEffect(0.8)
            }
            
            Spacer() // Pushes content to the top
            
            // Add close button at bottom too
            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.return, modifiers: [.command])
            }
        }
        .padding()
        .frame(minWidth: 400, idealWidth: 450, maxWidth: .infinity, minHeight: 250, idealHeight: 300, maxHeight: .infinity, alignment: .top)
        .onAppear {
            // Test connection when the view appears using stored settings
            testConnection()
        }
    }

    var statusColor: Color {
        if connectionStatus.starts(with: "Connected") {
            return .green
        } else if connectionStatus.starts(with: "Error") || connectionStatus == "Disconnected" {
            return .red
        } else {
            return .primary // For "Connecting..." or other intermediate states like "Checking..."
        }
    }

    func connectToOllama() {
        // Settings are already bound with @AppStorage, so they are saved as they are typed.
        // This function will now primarily trigger a connection test.
        testConnection()
    }

    func testConnection() {
        guard !isTestingConnection else { return }
        isTestingConnection = true
        connectionStatus = "Checking http://\(ollamaAddress):\(ollamaPort)..."

        // Ensure the port is a valid integer
        guard let portInt = Int(ollamaPort), portInt > 0 && portInt <= 65535 else {
            self.connectionStatus = "Error: Invalid port number."
            isTestingConnection = false
            return
        }

        // Construct the URL for the /api/version endpoint
        // Ollama typically runs on http. If https is needed, this needs adjustment.
        guard var components = URLComponents(string: "http://\(ollamaAddress)") else {
            self.connectionStatus = "Error: Invalid server address format."
            isTestingConnection = false
            return
        }
        components.port = portInt
        components.path = "/api/version" // Standard Ollama API endpoint for version

        guard let url = components.url else {
            self.connectionStatus = "Error: Could not construct URL."
            isTestingConnection = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5 // Set a timeout for the request (e.g., 5 seconds)

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
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    self.connectionStatus = "Error: Server returned status \(httpResponse.statusCode)"
                    return
                }
                
                guard let mimeType = httpResponse.mimeType, mimeType == "application/json", let data = data else {
                    self.connectionStatus = "Error: No data or incorrect data format received."
                    return
                }

                do {
                    let decodedResponse = try JSONDecoder().decode(OllamaVersionResponse.self, from: data)
                    self.connectionStatus = "Connected to Ollama v\(decodedResponse.version)"
                } catch {
                    self.connectionStatus = "Error: Could not decode version from response. \(error.localizedDescription)"
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