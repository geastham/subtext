//
//  ConversationListView.swift
//  Subtext - Phase 1
//

import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Query(sort: \ConversationThread.updatedAt, order: .reverse)
    private var conversations: [ConversationThread]
    
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddConversation = false
    
    var body: some View {
        Group {
            if conversations.isEmpty {
                EmptyStateView()
            } else {
                List {
                    ForEach(conversations) { conversation in
                        NavigationLink(value: conversation) {
                            ConversationRowView(conversation: conversation)
                        }
                    }
                    .onDelete(perform: deleteConversations)
                }
            }
        }
        .navigationTitle("Conversations")
        .navigationDestination(for: ConversationThread.self) { conversation in
            ConversationDetailPlaceholderView(conversation: conversation)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddConversation = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Add Conversation", isPresented: $showingAddConversation) {
            Button("Cancel", role: .cancel) { }
            Button("OK") {
                addSampleConversation()
            }
        } message: {
            Text("This will add a sample conversation. Full import coming in Phase 2.")
        }
    }
    
    private func addSampleConversation() {
        let conversation = ConversationThread(
            title: "Sample Conversation",
            participants: ["Me", "Friend"]
        )
        modelContext.insert(conversation)
        
        let message = Message(
            text: "Hey, how are you?",
            sender: "Friend",
            isFromUser: false
        )
        message.conversationThread = conversation
        conversation.messages.append(message)
        conversation.messageCount = 1
        modelContext.insert(message)
        
        try? modelContext.save()
    }
    
    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(conversations[index])
        }
        try? modelContext.save()
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.fill")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No Conversations Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap + to create your first conversation")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct ConversationRowView: View {
    let conversation: ConversationThread
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.headline)
            
            if !conversation.participants.isEmpty {
                Text(conversation.participants.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("\(conversation.messageCount) messages")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(conversation.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ConversationDetailPlaceholderView: View {
    let conversation: ConversationThread
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text("Conversation Detail")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Full conversation view coming in Phase 2")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Conversation: \(conversation.title)")
                Text("Messages: \(conversation.messageCount)")
                Text("Participants: \(conversation.participants.joined(separator: ", "))")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
        .navigationTitle(conversation.title)
    }
}
