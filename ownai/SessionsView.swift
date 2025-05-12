import SwiftUI

struct SessionsView: View {
    @ObservedObject var sessionManager: SessionManager
    @Binding var showSessions: Bool
    @Environment(\.colorScheme) var colorScheme
    
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
                        SessionRow(session: session, isSelected: session.id == sessionManager.currentSessionId)
                            .onTapGesture {
                                sessionManager.loadSession(session.id)
                                showSessions = false
                            }
                            .contextMenu {
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
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding()
        }
        .frame(width: 300)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SessionRow: View {
    let session: ChatSession
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
    }
} 