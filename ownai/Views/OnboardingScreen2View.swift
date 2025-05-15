import SwiftUI

struct OnboardingScreen2View: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "externaldrive.connected.to.line.below")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .padding(.bottom, 10)
            
            Text("Server Setup Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("To use OwnAI, you need to have an LLM server, such as Ollama, running and accessible. Without a configured server, you will encounter connection errors when trying to chat.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("You can download Ollama from:")
                .font(.caption)
            
            Link("https://ollama.com/download", destination: URL(string: "https://ollama.com/download")!)
                 .font(.caption)
                 .onHover { inside in
                     if inside {
                         NSCursor.pointingHand.push()
                     } else {
                         NSCursor.pop()
                     }
                 }

        }
        .padding()
    }
}

#Preview {
    OnboardingScreen2View()
} 