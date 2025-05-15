import SwiftUI

struct OnboardingFlowManagerView: View {
    @State private var currentTab = 0
    // Environment variable to dismiss the sheet/presentation
    @Environment(\.presentationMode) var presentationMode 

    var body: some View {
        VStack {
            TabView(selection: $currentTab) {
                OnboardingScreen1View()
                    .tag(0)
                
                OnboardingScreen2View()
                    .tag(1)
                
                OnboardingScreen3View()
                    .tag(2)
            }
            
            HStack {
                if currentTab > 0 {
                    Button("Back") {
                        withAnimation {
                            currentTab -= 1
                        }
                    }
                }
                
                Spacer()
                
                if currentTab < 2 {
                    Button("Next") {
                        withAnimation {
                            currentTab += 1
                        }
                    }
                } else {
                    Button("Done") {
                        // Action to close the onboarding view
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .padding()
        }
        .frame(minWidth: 400, idealWidth: 500, maxWidth: 600, minHeight: 300, idealHeight: 400, maxHeight: 500)
    }
}

#Preview {
    OnboardingFlowManagerView()
} 