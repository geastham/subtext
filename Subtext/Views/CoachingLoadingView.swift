//
//  CoachingLoadingView.swift
//  Subtext
//
//  Created by Codegen
//  Phase 4: Safety & Polish
//

import SwiftUI

// MARK: - Enhanced Coaching Loading View

struct CoachingLoadingView: View {
    @State private var isAnimating = false
    @State private var currentTipIndex = 0

    let intent: CoachingIntent?
    let tips = [
        "All your conversations are processed entirely on your device. Your privacy is our priority.",
        "Different tones work for different situations. Experiment to find what feels authentic to you.",
        "Setting boundaries is a sign of self-respect, not rudeness.",
        "The best responses are ones that feel true to who you are.",
        "It's okay to take time before responding. Thoughtful communication builds stronger connections."
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animated loading indicator
            loadingAnimation

            VStack(spacing: 8) {
                Text("Analyzing conversation...")
                    .font(.headline)

                if let intent = intent {
                    Text("Getting \(intent.rawValue.lowercased()) suggestions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Tips carousel
            tipCard

            Spacer()
        }
        .padding()
        .onAppear {
            startAnimations()
            startTipRotation()
        }
    }

    // MARK: - Loading Animation

    private var loadingAnimation: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.purple.opacity(0.3), lineWidth: 4)
                .frame(width: 80, height: 80)

            // Animated ring
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.purple, lineWidth: 4)
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)

            // Center sparkle
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundColor(.purple)
                .scaleEffect(isAnimating ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
        }
    }

    // MARK: - Tip Card

    private var tipCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Did you know?")
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Text(tips[currentTipIndex])
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .animation(.easeInOut, value: currentTipIndex)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 40)
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation {
            isAnimating = true
        }
    }

    private func startTipRotation() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation {
                currentTipIndex = (currentTipIndex + 1) % tips.count
            }
        }
    }
}

// MARK: - Shimmer Loading View

struct ShimmerLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<3) { index in
                shimmerCard
                    .opacity(isAnimating ? 1.0 : 0.6)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }

    private var shimmerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 80, height: 12)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(height: 60)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 120, height: 12)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    CoachingLoadingView(intent: .reply)
}
