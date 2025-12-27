//
//  ConversationListView.swift
//  Subtext - Phase 2
//

import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Query(sort: \ConversationThread.updatedAt, order: .reverse)
    private var conversations: [ConversationThread]

    @Environment(\.modelContext) private var modelContext
    @State private var showingImportSheet = false
    @State private var searchText = ""

    private var filteredConversations: [ConversationThread] {
        if searchText.isEmpty {
            return conversations
        }
        return conversations.filter { conversation in
            conversation.title.localizedCaseInsensitiveContains(searchText) ||
            conversation.participants.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        Group {
            if conversations.isEmpty {
                EmptyStateView(onImport: { showingImportSheet = true })
            } else {
                List {
                    ForEach(filteredConversations) { conversation in
                        NavigationLink(value: conversation) {
                            ConversationRowView(conversation: conversation)
                        }
                    }
                    .onDelete(perform: deleteConversations)
                }
                .searchable(text: $searchText, prompt: "Search conversations")
            }
        }
        .navigationTitle("Conversations")
        .navigationDestination(for: ConversationThread.self) { conversation in
            ConversationDetailView(conversation: conversation)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingImportSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            ConversationImportView()
        }
    }

    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            let conversation = filteredConversations[index]
            modelContext.delete(conversation)
        }
        try? modelContext.save()
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    var onImport: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "message.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue.opacity(0.6))

            VStack(spacing: 8) {
                Text("No Conversations Yet")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Import a conversation to get started with AI-powered coaching")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if let onImport = onImport {
                Button {
                    onImport()
                } label: {
                    Label("Import Conversation", systemImage: "doc.on.clipboard")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            // Supported formats hint
            VStack(spacing: 8) {
                Text("Supported Formats")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                HStack(spacing: 16) {
                    FormatBadge(name: "iMessage")
                    FormatBadge(name: "WhatsApp")
                    FormatBadge(name: "Telegram")
                }
            }
            .padding(.top, 8)
        }
        .padding()
    }
}

struct FormatBadge: View {
    let name: String

    var body: some View {
        Text(name)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray5))
            .cornerRadius(6)
    }
}

// MARK: - Conversation Row View

struct ConversationRowView: View {
    let conversation: ConversationThread

    private var lastMessagePreview: String? {
        conversation.messages
            .sorted { $0.timestamp > $1.timestamp }
            .first?.text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(conversation.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text(conversation.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !conversation.participants.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(conversation.participants.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            if let preview = lastMessagePreview {
                Text(preview)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Label("\(conversation.messageCount)", systemImage: "message.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("With Conversations") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ConversationThread.self, Message.self, CoachingSession.self, configurations: config)

    let conversation = ConversationThread(title: "Chat with Sarah", participants: ["Me", "Sarah"])
    container.mainContext.insert(conversation)

    let message = Message(text: "Hey, want to grab coffee later?", sender: "Sarah", isFromUser: false)
    message.conversationThread = conversation
    conversation.messages.append(message)
    conversation.messageCount = 1
    container.mainContext.insert(message)

    return NavigationStack {
        ConversationListView()
    }
    .modelContainer(container)
}

#Preview("Empty State") {
    NavigationStack {
        ConversationListView()
    }
    .modelContainer(for: [ConversationThread.self, Message.self, CoachingSession.self], inMemory: true)
}
