//
//  CoachingFlowView.swift
//  Subtext
//
//  Created by Codegen
//  Phase 3: AI Integration & Coaching
//  Updated: Phase 4 - Safety & Polish
//

import SwiftUI
import SwiftData

// MARK: - Coaching Flow View

/// Main view that orchestrates the coaching experience with safety integration
struct CoachingFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let conversation: ConversationThread
    let networkMonitor = NetworkMonitor.shared

    @State private var currentStep: CoachingStep = .selectIntent
    @State private var selectedIntent: CoachingIntent?
    @State private var parameters: CoachingParameters = .default
    @State private var coachingResponse: CoachingResponse?
    @State private var safetyAnalysis: SafetyAnalysis?
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showingError = false
    @State private var showingSafetyResources = false

    enum CoachingStep {
        case selectIntent
        case generating
        case results
        case error
    }

    var body: some View {
        Group {
            switch currentStep {
            case .selectIntent:
                OfflineAwareView(requiresNetwork: false) {
                    IntentSelectionView(conversation: conversation) { intent, params in
                        selectedIntent = intent
                        parameters = params
                        startGeneration()
                    }
                }

            case .generating:
                loadingView

            case .results:
                if let response = coachingResponse, let intent = selectedIntent {
                    CoachingResultsView(
                        coaching: response,
                        intent: intent,
                        safetyAnalysis: safetyAnalysis,
                        onRegenerate: {
                            startGeneration()
                        },
                        onShowSafetyResources: {
                            showingSafetyResources = true
                        }
                    )
                }

            case .error:
                if let error = error {
                    NavigationStack {
                        ErrorView(
                            error: error,
                            onRetry: {
                                startGeneration()
                            },
                            onDismiss: {
                                currentStep = .selectIntent
                            }
                        )
                        .navigationTitle("Error")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    currentStep = .selectIntent
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingSafetyResources) {
            if let analysis = safetyAnalysis {
                SafetyResourcesView(analysis: analysis)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        NavigationStack {
            CoachingLoadingView(intent: selectedIntent)
                .navigationTitle("Generating")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            currentStep = .selectIntent
                        }
                    }
                }
        }
    }

    // MARK: - Generation

    private func startGeneration() {
        guard let intent = selectedIntent else { return }

        // Check network connectivity
        guard networkMonitor.isConnected else {
            error = CoachingError.offline
            currentStep = .error
            return
        }

        currentStep = .generating
        isLoading = true
        error = nil

        Task {
            do {
                let messages = conversation.messages.sorted { $0.timestamp < $1.timestamp }

                // Run coaching and safety analysis in parallel
                async let coachingTask = LLMClient.shared.generateCoaching(
                    conversation: messages,
                    intent: intent,
                    parameters: parameters
                )
                async let safetyTask = SafetyClassifier.shared.analyzeSafety(conversation: messages)

                let (coachingResult, safetyResult) = try await (coachingTask, safetyTask)

                // Merge safety flags into coaching response
                var finalCoaching = coachingResult
                if !safetyResult.flags.isEmpty {
                    let existingTypes = Set(finalCoaching.riskFlags.map { $0.type })
                    let newFlags = safetyResult.flags.filter { !existingTypes.contains($0.type) }
                    finalCoaching = CoachingResponse(
                        summary: finalCoaching.summary,
                        replies: finalCoaching.replies,
                        riskFlags: finalCoaching.riskFlags + newFlags,
                        followUpQuestions: finalCoaching.followUpQuestions
                    )
                }

                await MainActor.run {
                    coachingResponse = finalCoaching
                    safetyAnalysis = safetyResult
                    currentStep = .results
                    isLoading = false

                    // Save session to conversation
                    saveCoachingSession(intent: intent, response: finalCoaching)
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.currentStep = .error
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

// MARK: - Coaching Error

enum CoachingError: Error, LocalizedError {
    case offline
    case safetyAnalysisFailed

    var errorDescription: String? {
        switch self {
        case .offline:
            return "You're offline. Please check your internet connection and try again."
        case .safetyAnalysisFailed:
            return "Could not complete safety analysis. Please try again."
        }
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
