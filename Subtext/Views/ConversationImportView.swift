//
//  ConversationImportView.swift
//  Subtext
//
//  Created by Codegen
//  Phase 2: Conversation Management
//

import SwiftUI
import SwiftData

struct ConversationImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var pastedText = ""
    @State private var parsedConversation: ParsedConversation?
    @State private var isParsing = false
    @State private var parseError: Error?
    @State private var showingSpeakerLabeling = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if parsedConversation == nil {
                    pasteView
                } else {
                    parseSuccessView
                }
            }
            .padding()
            .navigationTitle("Import Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingSpeakerLabeling) {
                if let parsed = parsedConversation {
                    SpeakerLabelingView(
                        parsedConversation: parsed,
                        onComplete: { labeled in
                            saveConversation(labeled)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Paste View

    private var pasteView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Paste Your Conversation")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Copy messages from iMessage, WhatsApp, Telegram, or any text app")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            ZStack(alignment: .topLeading) {
                if pastedText.isEmpty {
                    Text("Paste your conversation here...")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                }

                TextEditor(text: $pastedText)
                    .frame(height: 200)
                    .scrollContentBackground(.hidden)
                    .padding(8)
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )

            if let error = parseError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }

            HStack(spacing: 16) {
                Button {
                    pasteFromClipboard()
                } label: {
                    Label("Paste", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.bordered)

                Button {
                    parseConversation()
                } label: {
                    if isParsing {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Text("Parse Conversation")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isParsing)
            }

            Spacer()
        }
    }

    // MARK: - Parse Success View

    private var parseSuccessView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Conversation Parsed!")
                .font(.title2)
                .fontWeight(.semibold)

            if let parsed = parsedConversation {
                VStack(spacing: 12) {
                    InfoRow(label: "Format Detected", value: parsed.format.rawValue)
                    InfoRow(label: "Messages Found", value: "\(parsed.messages.count)")
                    InfoRow(label: "Participants", value: "\(parsed.participants.count)")

                    if !parsed.participants.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Detected speakers:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(parsed.participants.sorted().joined(separator: ", "))
                                .font(.callout)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            Button {
                showingSpeakerLabeling = true
            } label: {
                Label("Label Speakers", systemImage: "person.2.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("Start Over") {
                parsedConversation = nil
                pastedText = ""
                parseError = nil
            }
            .buttonStyle(.bordered)

            Spacer()
        }
    }

    // MARK: - Actions

    private func pasteFromClipboard() {
        #if os(iOS)
        if let clipboardText = UIPasteboard.general.string {
            pastedText = clipboardText
        }
        #endif
    }

    private func parseConversation() {
        isParsing = true
        parseError = nil

        Task {
            do {
                let parsed = try await ConversationParser.shared.parse(pastedText)
                await MainActor.run {
                    parsedConversation = parsed
                    isParsing = false
                }
            } catch {
                await MainActor.run {
                    parseError = error
                    isParsing = false
                }
            }
        }
    }

    private func saveConversation(_ labeled: LabeledConversation) {
        // Create ConversationThread
        let thread = ConversationThread(
            title: labeled.title,
            participants: labeled.participants,
            messageCount: labeled.messages.count
        )

        modelContext.insert(thread)

        // Create Messages
        for (index, msg) in labeled.messages.enumerated() {
            let message = Message(
                text: msg.text,
                sender: msg.sender,
                timestamp: msg.timestamp ?? Date().addingTimeInterval(TimeInterval(index)),
                isFromUser: msg.isFromUser
            )
            message.conversationThread = thread
            thread.messages.append(message)
            modelContext.insert(message)
        }

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Info Row Component

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    ConversationImportView()
        .modelContainer(for: [ConversationThread.self, Message.self, CoachingSession.self])
}
