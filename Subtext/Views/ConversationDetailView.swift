//
//  ConversationDetailView.swift
//  Subtext
//
//  Created by Codegen
//  Phase 2: Conversation Management
//  Updated: Phase 3 - AI Integration & Coaching
//

import SwiftUI
import SwiftData

struct ConversationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var conversation: ConversationThread

    @State private var showingCoaching = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingHistory = false
    @State private var messageToDelete: Message?

    private var sortedMessages: [Message] {
        conversation.messages.sorted { $0.timestamp < $1.timestamp }
    }

    private var sortedSessions: [CoachingSession] {
        conversation.coachingSessions.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Conversation info header
                    conversationHeader

                    // Quick coaching button
                    if !sortedMessages.isEmpty {
                        quickCoachingButton
                    }

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

                    if !sortedSessions.isEmpty {
                        Button {
                            showingHistory = true
                        } label: {
                            Label("Coaching History", systemImage: "clock.arrow.circlepath")
                        }
                    }

                    Divider()

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
            CoachingFlowView(conversation: conversation)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditConversationView(conversation: conversation)
        }
        .sheet(isPresented: $showingHistory) {
            CoachingHistoryView(sessions: sortedSessions)
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

    // MARK: - Quick Coaching Button

    private var quickCoachingButton: some View {
        Button {
            showingCoaching = true
        } label: {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Get AI Coaching")
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 8)
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

// MARK: - Coaching History View

struct CoachingHistoryView: View {
    @Environment(\.dismiss) private var dismiss

    let sessions: [CoachingSession]

    var body: some View {
        NavigationStack {
            List {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No Coaching History",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Your coaching sessions will appear here")
                    )
                } else {
                    ForEach(sessions) { session in
                        CoachingSessionRow(session: session)
                    }
                }
            }
            .navigationTitle("Coaching History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct CoachingSessionRow: View {
    let session: CoachingSession

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: session.intent.icon)
                        .foregroundColor(.purple)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.intent.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(session.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    if !session.summary.isEmpty {
                        Text(session.summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if !session.replies.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggestions:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            ForEach(session.replies) { reply in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 6))
                                        .foregroundColor(.purple)
                                        .padding(.top, 6)

                                    Text(reply.text)
                                        .font(.subheadline)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                }
                .padding(.leading, 32)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConversationThread.self, Message.self, CoachingSession.self,
        configurations: config
    )

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
