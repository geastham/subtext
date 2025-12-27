//
//  CoachingFlowView.swift
//  Subtext
//
//  Created by Codegen
//  Phase 3: AI Integration & Coaching
//

import SwiftUI
import SwiftData

// MARK: - Coaching Flow View

/// Main view that orchestrates the coaching experience
struct CoachingFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let conversation: ConversationThread

    @State private var currentStep: CoachingStep = .selectIntent
    @State private var selectedIntent: CoachingIntent?
    @State private var parameters: CoachingParameters = .default
    @State private var coachingResponse: CoachingResponse?
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showingError = false

    enum CoachingStep {
        case selectIntent
        case generating
        case results
    }

    var body: some View {
        Group {
            switch currentStep {
            case .selectIntent:
                IntentSelectionView(conversation: conversation) { intent, params in
                    selectedIntent = intent
                    parameters = params
                    startGeneration()
                }

            case .generating:
                loadingView

            case .results:
                if let response = coachingResponse, let intent = selectedIntent {
                    CoachingResultsView(
                        coaching: response,
                        intent: intent,
                        onRegenerate: {
                            startGeneration()
                        }
                    )
                }
            }
        }
        .alert("Coaching Error", isPresented: $showingError, presenting: error) { _ in
            Button("Try Again") {
                startGeneration()
            }
            Button("Cancel", role: .cancel) {
                currentStep = .selectIntent
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Animated sparkles
                AnimatedSparklesView()
                    .frame(width: 80, height: 80)

                VStack(spacing: 8) {
                    Text("Analyzing conversation...")
                        .font(.title3)
                        .fontWeight(.semibold)

                    if let intent = selectedIntent {
                        Text("Getting \(intent.rawValue.lowercased()) suggestions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // Progress indicator
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.2)

                // Tips while loading
                loadingTips

                Spacer()
            }
            .padding()
            .navigationTitle("Generating")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Task {
                            // Cancel would go here if we had cancellation support
                            currentStep = .selectIntent
                        }
                    }
                }
            }
        }
    }

    private var loadingTips: some View {
        VStack(spacing: 12) {
            Text("Did you know?")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Text(randomTip)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 40)
    }

    private var randomTip: String {
        let tips = [
            "All your conversations are processed entirely on your device. Your privacy is our priority.",
            "Different tones work for different situations. Experiment to find what feels authentic to you.",
            "Setting boundaries is a sign of self-respect, not rudeness.",
            "The best responses are ones that feel true to who you are.",
            "It's okay to take time before responding. Thoughtful communication builds stronger connections."
        ]
        return tips.randomElement() ?? tips[0]
    }

    // MARK: - Generation

    private func startGeneration() {
        guard let intent = selectedIntent else { return }

        currentStep = .generating
        isLoading = true
        error = nil

        Task {
            do {
                let messages = conversation.messages.sorted { $0.timestamp < $1.timestamp }
                let response = try await LLMClient.shared.generateCoaching(
                    conversation: messages,
                    intent: intent,
                    parameters: parameters
                )

                await MainActor.run {
                    coachingResponse = response
                    currentStep = .results
                    isLoading = false

                    // Save session to conversation
                    saveCoachingSession(intent: intent, response: response)
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.showingError = true
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - Save Session

    private func saveCoachingSession(intent: CoachingIntent, response: CoachingResponse) {
        let session = CoachingSession(
            intent: intent,
            contextMessages: conversation.messages.map { $0.id.uuidString },
            summary: response.summary,
            replies: response.replies,
            riskFlags: response.riskFlags,
            followUpQuestions: response.followUpQuestions,
            parameters: parameters
        )

        session.conversationThread = conversation
        conversation.coachingSessions.append(session)

        modelContext.insert(session)
        try? modelContext.save()
    }
}

// MARK: - Animated Sparkles View

struct AnimatedSparklesView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(Color.purple.opacity(0.2))
                .scaleEffect(isAnimating ? 1.2 : 0.8)

            // Main sparkles icon
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.purple)
                .scaleEffect(isAnimating ? 1.1 : 0.9)
                .rotationEffect(.degrees(isAnimating ? 5 : -5))

            // Orbiting sparkle 1
            Image(systemName: "sparkle")
                .font(.system(size: 12))
                .foregroundColor(.purple.opacity(0.7))
                .offset(x: isAnimating ? 30 : -30, y: isAnimating ? -20 : 20)

            // Orbiting sparkle 2
            Image(systemName: "sparkle")
                .font(.system(size: 10))
                .foregroundColor(.purple.opacity(0.5))
                .offset(x: isAnimating ? -25 : 25, y: isAnimating ? 25 : -25)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConversationThread.self, Message.self, CoachingSession.self,
        configurations: config
    )

    let conversation = ConversationThread(
        title: "Chat with Sarah",
        participants: ["Me", "Sarah"]
    )
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

    return CoachingFlowView(conversation: conversation)
        .modelContainer(container)
}
