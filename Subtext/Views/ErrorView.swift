//
//  ErrorView.swift
//  Subtext
//
//  Created by Codegen
//  Phase 4: Safety & Polish
//

import SwiftUI

// MARK: - Error View

struct ErrorView: View {
    let error: Error
    let onRetry: () -> Void
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Error icon with animation
            errorIcon

            // Error message
            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.headline)

                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Action buttons
            VStack(spacing: 12) {
                Button(action: onRetry) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Text("Go Back")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 40)

            // Troubleshooting tips
            troubleshootingSection

            Spacer()
        }
        .padding()
    }

    // MARK: - Error Icon

    private var errorIcon: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.2))
                .frame(width: 100, height: 100)

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
        }
    }

    // MARK: - Error Message

    private var errorMessage: String {
        if let llmError = error as? LLMClient.LLMError {
            return llmError.errorDescription ?? "An unknown error occurred."
        }
        return error.localizedDescription
    }

    // MARK: - Troubleshooting Section

    private var troubleshootingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Troubleshooting tips:")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                troubleshootingTip("Check your internet connection")
                troubleshootingTip("Make sure your device supports on-device AI")
                troubleshootingTip("Try closing and reopening the app")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private func troubleshootingTip(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 4))
                .foregroundColor(.secondary)
                .padding(.top, 6)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Inline Error Banner

struct InlineErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)

            Text(message)
                .font(.subheadline)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)? = nil
    var actionTitle: String = "Get Started"

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.purple.opacity(0.5))

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.medium)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}

// MARK: - Preview

#Preview("Error View") {
    ErrorView(
        error: LLMClient.LLMError.modelNotAvailable,
        onRetry: { print("Retry tapped") },
        onDismiss: { print("Dismiss tapped") }
    )
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "bubble.left.and.bubble.right",
        title: "No Conversations Yet",
        message: "Import a conversation to get started with coaching.",
        action: { print("Action tapped") },
        actionTitle: "Import Conversation"
    )
}
