//
//  ContentView.swift
//  ownai
//
//  Created by Arvind Juneja on 12/05/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var showingSettingsSheet = false

    var body: some View {
        // Using a simple VStack as the root for a single-window utility can be cleaner on macOS
        // If you need a title bar for the button, NavigationStack (or NavigationView) is okay.
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, OwnAI!") // Updated placeholder text
            
            // Spacer to push content and button if needed, or direct placement
            Spacer()

        }
        .frame(minWidth: 300, idealWidth: 400, minHeight: 200, idealHeight: 300) // Give some default size
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .automatic) { // More macOS-friendly placement
                Button {
                    showingSettingsSheet.toggle()
                } label: {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .help("Open Settings") // Tooltip for the button
            }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView()
                .frame(minWidth: 400, idealWidth: 450, minHeight: 300, idealHeight: 350) // Give the sheet a decent size
        }
    }
}

#Preview {
    ContentView()
} 