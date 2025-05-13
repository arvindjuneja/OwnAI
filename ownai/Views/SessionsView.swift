import SwiftUI
import UniformTypeIdentifiers

struct SessionsView: View {
    @ObservedObject var sessionManager: SessionManager
    @Binding var showSessions: Bool
    @Environment(\.colorScheme) var colorScheme
    
    // State for managing which session is being edited and its temporary title
    @State private var editingSessionId: UUID? = nil
    @State private var editingTitle: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Chat Sessions")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Button(action: { showSessions = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Sessions list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(sessionManager.sessions) { session in
                        // Pass editing state to SessionRow
                        SessionRow(
                            session: session, 
                            isSelected: session.id == sessionManager.currentSessionId, 
                            isEditing: editingSessionId == session.id,
                            editingTitle: $editingTitle,
                            onBeginEditing: { // Closure to start editing
                                editingSessionId = session.id
                                editingTitle = session.title ?? "" // Or session.displayTitle if you prefer default as placeholder
                            },
                            onCommitEditing: { newTitle in // Closure to commit edit
                                sessionManager.renameSession(id: session.id, newTitle: newTitle)
                                editingSessionId = nil
                            }
                        )
                        .onTapGesture {
                            if editingSessionId == session.id {
                                // Already editing, do nothing on tap
                                return
                            }
                            sessionManager.loadSession(session.id)
                            showSessions = false
                        }
                        .contextMenu {
                            Button {
                                editingSessionId = session.id
                                editingTitle = session.title ?? ""
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            Button {
                                exportSession(session: session)
                            } label: {
                                Label("Export Session...", systemImage: "square.and.arrow.up")
                            }
                            Button(role: .destructive) {
                                sessionManager.deleteSession(session.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // Footer buttons
            HStack(spacing: 10) { // Use HStack for side-by-side buttons
                // New chat button
                Button(action: {
                    _ = sessionManager.createNewSession()
                    showSessions = false
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("New Chat")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity) // Let buttons share width
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                // ---> Add Import Session Button <--- 
                Button(action: {
                    importSession()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import Session")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity) // Let buttons share width
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                // ---> End Import Session Button <---
            }
            .padding()
        }
        .frame(width: 300)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func exportSession(session: ChatSession) {
        print("Attempting to export session: \(session.displayTitle)")
        sessionManager.exportSessionToFile(session: session)
    }
    
    private func importSession() {
        print("SessionsView: importSession action triggered")

        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [UTType.json] // Make sure UniformTypeIdentifiers is imported

        openPanel.begin { result in
            if result == .OK, let url = openPanel.url {
                do {
                    let jsonData = try Data(contentsOf: url)
                    // Call the SessionManager to process this data
                    sessionManager.processImportedSessionData(jsonData)
                    // Optionally, close the sheet after initiating processing
                    // showSessions = false 
                } catch {
                    print("SessionsView: Error reading file for import - \(error.localizedDescription)")
                    // TODO: Show an alert to the user from the View
                }
            }
        }
    }
}

struct SessionRow: View {
    let session: ChatSession
    let isSelected: Bool
    let isEditing: Bool
    @Binding var editingTitle: String
    let onBeginEditing: () -> Void
    let onCommitEditing: (String) -> Void

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if isEditing {
                    TextField("Session Name", text: $editingTitle, onCommit: {
                        onCommitEditing(editingTitle)
                    })
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .medium))
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        onCommitEditing(editingTitle) // Also commit on Enter key
                    }
                    .onChange(of: isEditing) { _, newValue in // Focus when editing starts
                        if newValue { isTextFieldFocused = true }
                    }
                } else {
                    Text(session.displayTitle) // Use displayTitle here
                        .font(.system(size: 15, weight: .medium))
                        .lineLimit(1)
                        .onTapGesture(count: 2) { // Double tap to edit
                            onBeginEditing()
                        }
                }
                Text(session.createdAt, style: .date)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.accentColor)
                    .font(.system(size: 16))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
} 