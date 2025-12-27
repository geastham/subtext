//
//  ConversationDetailView.swift
//  Subtext
//
//  Created by Codegen
//  Phase 2: Conversation Management
//

import SwiftUI
import SwiftData

struct ConversationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var conversation: ConversationThread

    @State private var showingCoaching = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var messageToDelete: Message?

    private var sortedMessages: [Message] {
        conversation.messages.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Conversation info header
                    conversationHeader

                    // Messages
                    ForEach(sortedMessages) { message in
                        MessageBubbleView(
                            message: message,
                            onDelete: {
                                messageToDelete = message
                                showingDeleteAlert = true
                            }
                        )
                        .id(message.id)
                    }

                    // Bottom spacer
                    Color.clear.frame(height: 20)
                }
                .padding()
            }
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingCoaching = true
                    } label: {
                        Label("Get Coaching", systemImage: "sparkles")
                    }

                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Conversation", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingCoaching) {
            CoachingPlaceholderView(conversation: conversation)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditConversationView(conversation: conversation)
        }
        .alert("Delete Message?", isPresented: $showingDeleteAlert, presenting: messageToDelete) { message in
            Button("Cancel", role: .cancel) {
                messageToDelete = nil
            }
            Button("Delete", role: .destructive) {
                deleteMessage(message)
            }
        } message: { message in
            Text("This message will be permanently deleted.")
        }
    }

    // MARK: - Conversation Header

    private var conversationHeader: some View {
        VStack(spacing: 8) {
            if !conversation.participants.isEmpty {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.secondary)
                    Text(conversation.participants.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Image(systemName: "message.fill")
                    .foregroundColor(.secondary)
                Text("\(conversation.messageCount) messages")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(conversation.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()
                .padding(.top, 8)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Delete Message

    private func deleteMessage(_ message: Message) {
        withAnimation {
            conversation.messages.removeAll { $0.id == message.id }
            modelContext.delete(message)
            conversation.messageCount = conversation.messages.count
            conversation.updatedAt = Date()
            try? modelContext.save()
        }
        messageToDelete = nil
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let message: Message
    var onDelete: (() -> Void)?

    @State private var showingActions = false

    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.sender)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Text(message.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.isFromUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .cornerRadius(18)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 300, alignment: message.isFromUser ? .trailing : .leading)
            .contextMenu {
                Button {
                    copyMessage()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }

                if let onDelete = onDelete {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            if !message.isFromUser {
                Spacer(minLength: 60)
            }
        }
    }

    private func copyMessage() {
        #if os(iOS)
        UIPasteboard.general.string = message.text
        #endif
    }
}

// MARK: - Edit Conversation View

struct EditConversationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var conversation: ConversationThread

    @State private var editedTitle: String = ""
    @State private var editedParticipants: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Conversation title", text: $editedTitle)
                }

                Section {
                    TextField("Separate names with commas", text: $editedParticipants)
                } header: {
                    Text("Participants")
                } footer: {
                    Text("Enter participant names separated by commas")
                }

                Section {
                    HStack {
                        Text("Messages")
                        Spacer()
                        Text("\(conversation.messageCount)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Created")
                        Spacer()
                        Text(conversation.createdAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(editedTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                editedTitle = conversation.title
                editedParticipants = conversation.participants.joined(separator: ", ")
            }
        }
    }

    private func saveChanges() {
        conversation.title = editedTitle.trimmingCharacters(in: .whitespaces)
        conversation.participants = editedParticipants
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        conversation.updatedAt = Date()

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Coaching Placeholder View

struct CoachingPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    let conversation: ConversationThread

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 64))
                    .foregroundColor(.purple)

                Text("AI Coaching")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Get personalized coaching for this conversation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Coming in Phase 3:")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "text.bubble", text: "Generate reply suggestions")
                        FeatureRow(icon: "brain", text: "Interpret their messages")
                        FeatureRow(icon: "hand.raised", text: "Set healthy boundaries")
                        FeatureRow(icon: "heart", text: "Improve your flirting")
                        FeatureRow(icon: "figure.2.arms.open", text: "Resolve conflicts")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                Spacer()
            }
            .padding()
            .navigationTitle("Coaching")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ConversationThread.self, Message.self, configurations: config)

    let conversation = ConversationThread(title: "Chat with Sarah", participants: ["Me", "Sarah"])
    container.mainContext.insert(conversation)

    let messages = [
        Message(text: "Hey, how are you?", sender: "Sarah", timestamp: Date().addingTimeInterval(-3600), isFromUser: false),
        Message(text: "I'm doing great! Just finished work.", sender: "Me", timestamp: Date().addingTimeInterval(-3500), isFromUser: true),
        Message(text: "Nice! Want to grab dinner?", sender: "Sarah", timestamp: Date().addingTimeInterval(-3400), isFromUser: false)
    ]

    for message in messages {
        message.conversationThread = conversation
        conversation.messages.append(message)
        container.mainContext.insert(message)
    }
    conversation.messageCount = messages.count

    return NavigationStack {
        ConversationDetailView(conversation: conversation)
    }
    .modelContainer(container)
}
