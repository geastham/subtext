//
//  CoachingResultsView.swift
//  Subtext
//
//  Created by Codegen
//  Phase 3: AI Integration & Coaching
//

import SwiftUI
import SwiftData

// MARK: - Coaching Results View

struct CoachingResultsView: View {
    @Environment(\.dismiss) private var dismiss

    let coaching: CoachingResponse
    let intent: CoachingIntent
    let onRegenerate: () -> Void

    @State private var selectedReply: CoachingReply?
    @State private var showingCopied = false
    @State private var copiedReplyId: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    intentBadge

                    summarySection

                    if !coaching.riskFlags.isEmpty {
                        riskFlagsSection
                    }

                    repliesSection

                    if !coaching.followUpQuestions.isEmpty {
                        followUpSection
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Coaching Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        onRegenerate()
                    } label: {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if showingCopied {
                    copiedToast
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingCopied)
        }
    }

    // MARK: - Intent Badge

    private var intentBadge: some View {
        HStack {
            Image(systemName: intent.icon)
            Text(intent.rawValue)
                .fontWeight(.medium)
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.purple.opacity(0.15))
        .foregroundColor(.purple)
        .cornerRadius(20)
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Situation Analysis", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundColor(.purple)

            Text(coaching.summary)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Risk Flags Section

    private var riskFlagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(coaching.riskFlags, id: \.description) { flag in
                RiskFlagBanner(flag: flag)
            }
        }
    }

    // MARK: - Replies Section

    private var repliesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Suggested Replies")
                    .font(.headline)
                Spacer()
                Text("\(coaching.replies.count) options")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(Array(coaching.replies.enumerated()), id: \.element.id) { index, reply in
                ReplyCard(
                    reply: reply,
                    index: index + 1,
                    isSelected: selectedReply?.id == reply.id,
                    showCopiedIndicator: copiedReplyId == reply.id,
                    onSelect: {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                            selectedReply = reply
                        }
                    },
                    onCopy: {
                        copyReply(reply)
                    }
                )
            }
        }
    }

    // MARK: - Follow Up Section

    private var followUpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Think About This", systemImage: "questionmark.circle.fill")
                .font(.headline)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(coaching.followUpQuestions, id: \.self) { question in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(.blue)
                            .padding(.top, 6)
                        Text(question)
                            .font(.subheadline)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Copied Toast

    private var copiedToast: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
            Text("Copied to clipboard")
        }
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.green)
        .cornerRadius(25)
        .shadow(radius: 10)
        .padding(.bottom, 20)
    }

    // MARK: - Actions

    private func copyReply(_ reply: CoachingReply) {
        #if os(iOS)
        UIPasteboard.general.string = reply.text
        #endif

        withAnimation {
            copiedReplyId = reply.id
            showingCopied = true
        }

        // Hide toast after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingCopied = false
                copiedReplyId = nil
            }
        }
    }
}

// MARK: - Reply Card

struct ReplyCard: View {
    let reply: CoachingReply
    let index: Int
    let isSelected: Bool
    let showCopiedIndicator: Bool
    let onSelect: () -> Void
    let onCopy: () -> Void

    @State private var showingRationale = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Option \(index)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text(reply.tone.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(toneColor.opacity(0.2))
                    .foregroundColor(toneColor)
                    .cornerRadius(6)

                Spacer()

                Button(action: { showingRationale.toggle() }) {
                    HStack(spacing: 4) {
                        Text("Why?")
                        Image(systemName: showingRationale ? "chevron.up" : "chevron.down")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            // Reply Text
            Text(reply.text)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)

            // Rationale (expandable)
            if showingRationale {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Why this works:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    Text(reply.rationale)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Copy Button
            Button(action: onCopy) {
                HStack {
                    Image(systemName: showCopiedIndicator ? "checkmark" : "doc.on.doc")
                    Text(showCopiedIndicator ? "Copied!" : "Copy Reply")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(showCopiedIndicator ? Color.green : Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(isSelected ? Color.purple.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onSelect()
        }
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: showingRationale)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: showCopiedIndicator)
    }

    private var toneColor: Color {
        switch reply.tone.lowercased() {
        case "warm": return .orange
        case "direct": return .blue
        case "playful": return .pink
        case "firm": return .red
        case "casual": return .green
        default: return .purple
        }
    }
}

// MARK: - Risk Flag Banner

struct RiskFlagBanner: View {
    let flag: RiskFlag

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(severityColor)

                    Text(flagTypeTitle)
                        .font(.headline)
                        .foregroundColor(severityColor)

                    Spacer()

                    Text(flag.severity.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(severityColor.opacity(0.2))
                        .foregroundColor(severityColor)
                        .cornerRadius(4)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text(flag.description)
                        .font(.subheadline)

                    if !flag.evidence.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Evidence:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            ForEach(flag.evidence, id: \.self) { evidence in
                                Text("\"\(evidence)\"")
                                    .font(.caption)
                                    .italic()
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(severityColor.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(severityColor.opacity(0.5), lineWidth: 1)
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isExpanded)
    }

    private var severityColor: Color {
        switch flag.severity {
        case .low: return .yellow
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var flagTypeTitle: String {
        switch flag.type {
        case .manipulation: return "Manipulation Detected"
        case .gaslighting: return "Gaslighting Pattern"
        case .pressuring: return "Pressuring Behavior"
        case .toxicity: return "Toxic Communication"
        case .redFlag: return "Red Flag"
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleResponse = CoachingResponse(
        summary: "Based on the conversation, they seem genuinely interested in connecting with you. Their message shows warmth and openness.",
        replies: [
            CoachingReply(
                text: "I'd love that! How about Friday evening?",
                rationale: "Direct and enthusiastic, shows you're equally interested without playing games.",
                tone: "warm"
            ),
            CoachingReply(
                text: "Sounds fun! Any particular cuisine you're in the mood for?",
                rationale: "Keeps the conversation going while showing flexibility and interest in their preferences.",
                tone: "casual"
            ),
            CoachingReply(
                text: "Yes! I know a great spot downtown if you're up for an adventure.",
                rationale: "Confident and takes initiative, suggests you're comfortable leading.",
                tone: "playful"
            )
        ],
        riskFlags: [],
        followUpQuestions: [
            "What outcome would feel best to you in this situation?",
            "How do you want them to feel after reading your message?"
        ]
    )

    return CoachingResultsView(
        coaching: sampleResponse,
        intent: .reply,
        onRegenerate: { print("Regenerate tapped") }
    )
}
