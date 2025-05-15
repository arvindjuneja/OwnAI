import SwiftUI

struct OnboardingScreen1View: View {
    var body: some View {
        VStack {
            Text("OwnAI")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 5)
            
            Text("Your local AI inference client")
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    OnboardingScreen1View()
} 