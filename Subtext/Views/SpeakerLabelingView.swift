//
//  SpeakerLabelingView.swift
//  Subtext
//
//  Created by Codegen
//  Phase 2: Conversation Management
//

import SwiftUI

// MARK: - Labeled Types

struct LabeledMessage {
    let text: String
    let sender: String
    let timestamp: Date?
    let isFromUser: Bool
}

struct LabeledConversation {
    let title: String
    let participants: [String]
    let messages: [LabeledMessage]
}

// MARK: - Speaker Labeling View

struct SpeakerLabelingView: View {
    @Environment(\.dismiss) private var dismiss

    let parsedConversation: ParsedConversation
    let onComplete: (LabeledConversation) -> Void

    @State private var speakerMapping: [String: String] = [:]
    @State private var conversationTitle = ""
    @State private var userSpeakerName = ""
    @State private var showingPreview = false

    private var allSpeakers: [String] {
        Array(parsedConversation.participants).sorted()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g., Chat with Sarah", text: $conversationTitle)
                } header: {
                    Text("Conversation Title")
                } footer: {
                    Text("Give this conversation a memorable name")
                }

                Section {
                    if allSpeakers.isEmpty {
                        Text("No speakers detected")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Select yourself", selection: $userSpeakerName) {
                            Text("Select...").tag("")
                            ForEach(allSpeakers, id: \.self) { speaker in
                                Text(speaker).tag(speaker)
                            }
                        }
                    }
                } header: {
                    Text("Who are you?")
                } footer: {
                    Text("Select which speaker is you in this conversation")
                }

                if !userSpeakerName.isEmpty {
                    Section {
                        ForEach(allSpeakers.filter { $0 != userSpeakerName }, id: \.self) { speaker in
                            HStack {
                                Text(speaker)
                                    .foregroundColor(.secondary)
                                Spacer()
                                TextField("Display name", text: binding(for: speaker))
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: 150)
                            }
                        }
                    } header: {
                        Text("Other Participants")
                    } footer: {
                        if allSpeakers.count > 1 {
                            Text("Optionally rename other participants")
                        }
                    }
                }

                Section {
                    Button {
                        showingPreview = true
                    } label: {
                        Label("Preview Messages", systemImage: "eye")
                    }
                    .disabled(!isValid)
                }

                Section {
                    Button {
                        saveLabels()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Save Conversation", systemImage: "checkmark.circle.fill")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("Label Speakers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                setupDefaults()
            }
            .sheet(isPresented: $showingPreview) {
                MessagePreviewView(
                    messages: createPreviewMessages(),
                    title: conversationTitle
                )
            }
        }
    }

    // MARK: - Computed Properties

    private var isValid: Bool {
        !conversationTitle.trimmingCharacters(in: .whitespaces).isEmpty &&
        !userSpeakerName.isEmpty
    }

    // MARK: - Binding Helper

    private func binding(for speaker: String) -> Binding<String> {
        Binding(
            get: { speakerMapping[speaker] ?? speaker },
            set: { speakerMapping[speaker] = $0 }
        )
    }

    // MARK: - Setup

    private func setupDefaults() {
        // Auto-generate conversation title
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        conversationTitle = "Conversation on \(dateFormatter.string(from: Date()))"

        // Pre-fill speaker mapping with original names
        for speaker in allSpeakers {
            speakerMapping[speaker] = speaker
        }
    }

    // MARK: - Preview Helper

    private func createPreviewMessages() -> [LabeledMessage] {
        parsedConversation.messages.prefix(10).map { msg in
            let originalSender = msg.sender ?? "Unknown"
            let displayName = originalSender == userSpeakerName ? "Me" : (speakerMapping[originalSender] ?? originalSender)
            let isUser = originalSender == userSpeakerName

            return LabeledMessage(
                text: msg.text,
                sender: displayName,
                timestamp: msg.timestamp,
                isFromUser: isUser
            )
        }
    }

    // MARK: - Save

    private func saveLabels() {
        let labeledMessages = parsedConversation.messages.map { msg in
            let originalSender = msg.sender ?? "Unknown"
            let isUser = originalSender == userSpeakerName
            let displayName = isUser ? "Me" : (speakerMapping[originalSender] ?? originalSender)

            return LabeledMessage(
                text: msg.text,
                sender: displayName,
                timestamp: msg.timestamp,
                isFromUser: isUser
            )
        }

        // Build participant list (excluding "Me")
        let otherParticipants = allSpeakers
            .filter { $0 != userSpeakerName }
            .map { speakerMapping[$0] ?? $0 }

        let labeled = LabeledConversation(
            title: conversationTitle.trimmingCharacters(in: .whitespaces),
            participants: ["Me"] + otherParticipants,
            messages: labeledMessages
        )

        onComplete(labeled)
        dismiss()
    }
}

// MARK: - Message Preview View

struct MessagePreviewView: View {
    @Environment(\.dismiss) private var dismiss

    let messages: [LabeledMessage]
    let title: String

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                        PreviewBubbleView(message: message)
                    }

                    if messages.count == 10 {
                        Text("Showing first 10 messages...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct PreviewBubbleView: View {
    let message: LabeledMessage

    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.sender)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isFromUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .cornerRadius(16)
            }
            .frame(maxWidth: 280, alignment: message.isFromUser ? .trailing : .leading)

            if !message.isFromUser {
                Spacer()
            }
        }
    }
}

#Preview {
    let sampleConversation = ParsedConversation(
        format: .manual,
        messages: [
            ParsedMessage(text: "Hey, how are you?", sender: "Sarah", timestamp: Date(), isFromUser: false),
            ParsedMessage(text: "I'm good, thanks!", sender: "John", timestamp: Date(), isFromUser: false),
            ParsedMessage(text: "Want to grab coffee?", sender: "Sarah", timestamp: Date(), isFromUser: false)
        ],
        participants: ["Sarah", "John"],
        detectedAt: Date()
    )

    return SpeakerLabelingView(parsedConversation: sampleConversation) { labeled in
        print("Saved: \(labeled.title)")
    }
}
