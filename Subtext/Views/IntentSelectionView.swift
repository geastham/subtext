//
//  IntentSelectionView.swift
//  Subtext
//
//  Created by Codegen
//  Phase 3: AI Integration & Coaching
//

import SwiftUI
import SwiftData

// MARK: - Intent Selection View

struct IntentSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    let conversation: ConversationThread
    let onIntentSelected: (CoachingIntent, CoachingParameters) -> Void

    @State private var selectedIntent: CoachingIntent?
    @State private var tone: CoachingParameters.Tone = .warm
    @State private var verbosity: CoachingParameters.Verbosity = .balanced
    @State private var formality: CoachingParameters.Formality = .casual
    @State private var showParameters = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    intentGrid

                    if selectedIntent != nil {
                        parametersSection
                            .transition(.move(edge: .bottom).combined(with: .opacity))

                        generateButton
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Get Coaching")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedIntent)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.purple)

            Text("What do you need help with?")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Choose an intent to get personalized coaching")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Intent Grid

    private var intentGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(CoachingIntent.allCases, id: \.self) { intent in
                IntentCard(
                    intent: intent,
                    isSelected: selectedIntent == intent
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if selectedIntent == intent {
                            selectedIntent = nil
                        } else {
                            selectedIntent = intent
                        }
                    }
                }
            }
        }
    }

    // MARK: - Parameters Section

    private var parametersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Adjust Style")
                    .font(.headline)

                Spacer()

                Button {
                    withAnimation {
                        showParameters.toggle()
                    }
                } label: {
                    Image(systemName: showParameters ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }

            if showParameters {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tone")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Picker("Tone", selection: $tone) {
                            Text("Warm").tag(CoachingParameters.Tone.warm)
                            Text("Neutral").tag(CoachingParameters.Tone.neutral)
                            Text("Direct").tag(CoachingParameters.Tone.direct)
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detail Level")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Picker("Verbosity", selection: $verbosity) {
                            Text("Concise").tag(CoachingParameters.Verbosity.concise)
                            Text("Balanced").tag(CoachingParameters.Verbosity.balanced)
                            Text("Detailed").tag(CoachingParameters.Verbosity.detailed)
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Formality")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Picker("Formality", selection: $formality) {
                            Text("Casual").tag(CoachingParameters.Formality.casual)
                            Text("Moderate").tag(CoachingParameters.Formality.moderate)
                            Text("Formal").tag(CoachingParameters.Formality.formal)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            guard let intent = selectedIntent else { return }
            let params = CoachingParameters(
                tone: tone,
                verbosity: verbosity,
                formality: formality
            )
            onIntentSelected(intent, params)
            dismiss()
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("Generate Coaching")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}

// MARK: - Intent Card

struct IntentCard: View {
    let intent: CoachingIntent
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: intent.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .purple)

                Text(intent.rawValue)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)

                Text(intent.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 130)
            .padding()
            .background(isSelected ? Color.purple : Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConversationThread.self, Message.self,
        configurations: config
    )

    let conversation = ConversationThread(
        title: "Chat with Sarah",
        participants: ["Me", "Sarah"]
    )
    container.mainContext.insert(conversation)

    return IntentSelectionView(conversation: conversation) { intent, params in
        print("Selected: \(intent.rawValue) with \(params.tone.rawValue) tone")
    }
    .modelContainer(container)
}
