import SwiftUI

struct OnboardingScreen3View: View {
    @AppStorage("hideOnboarding") var hideOnboarding: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "network")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .padding(.bottom, 10)
            
            Text("Connecting to Your Server")
                .font(.title2)
                .fontWeight(.semibold)

            Text("You can connect to a local Ollama instance (e.g., using \"localhost\" or \"127.0.0.1\") or an instance on your local network (e.g., \"192.168.1.15\"). Check your Ollama server's address and port in its settings.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("If you are on a managed network or encounter issues, please ask your network administrator for assistance.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Toggle(isOn: $hideOnboarding) {
                Text("Don't show this again on startup")
            }
            .padding(.top)
            
        }
        .padding()
    }
}

#Preview {
    OnboardingScreen3View()
} 