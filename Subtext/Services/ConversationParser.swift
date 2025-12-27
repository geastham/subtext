//
//  ConversationParser.swift
//  Subtext
//
//  Created by Codegen
//  Phase 2: Conversation Management
//

import Foundation

// MARK: - Types

enum ConversationFormat: String, CaseIterable {
    case iMessage = "iMessage"
    case whatsApp = "WhatsApp"
    case telegram = "Telegram"
    case manual = "Manual"
    case unknown = "Unknown"
}

struct ParsedConversation {
    let format: ConversationFormat
    let messages: [ParsedMessage]
    let participants: Set<String>
    let detectedAt: Date
}

struct ParsedMessage: Identifiable {
    let id = UUID()
    let text: String
    let sender: String?  // Nil if unknown
    let timestamp: Date?
    let isFromUser: Bool
}

// MARK: - Parser Actor

actor ConversationParser {
    static let shared = ConversationParser()

    private init() {}

    // MARK: - Format Detection

    func detectFormat(_ text: String) -> ConversationFormat {
        // iMessage: "[Date, Time] Contact Name: Message"
        // Example: [12/25/24, 10:30:45] Sarah: Hey there!
        if text.contains(regex: #"\[\d{1,2}/\d{1,2}/\d{2,4}, \d{1,2}:\d{2}:\d{2}\]"#) {
            return .iMessage
        }

        // WhatsApp: "MM/DD/YY, HH:MM - Contact Name: Message"
        // Example: 12/25/24, 10:30 - Sarah: Hey!
        if text.contains(regex: #"\d{1,2}/\d{1,2}/\d{2,4}, \d{1,2}:\d{2}\s*-\s*[^:]+:"#) {
            return .whatsApp
        }

        // Telegram: "[HH:MM, DD.MM.YYYY] Contact Name: Message"
        // Example: [10:30, 25.12.2024] Sarah: Hey!
        if text.contains(regex: #"\[\d{2}:\d{2}, \d{2}\.\d{2}\.\d{4}\]"#) {
            return .telegram
        }

        // Check for generic patterns (Name: Message format)
        let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let linesWithColons = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let colonIndex = trimmed.firstIndex(of: ":") {
                let beforeColon = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                // Name should be reasonably short (no more than 50 chars) and have content after colon
                return beforeColon.count > 0 && beforeColon.count < 50 && trimmed.count > colonIndex.utf16Offset(in: trimmed) + 1
            }
            return false
        }

        // If more than half of non-empty lines have colon pattern, treat as manual
        if linesWithColons.count > lines.count / 2 {
            return .manual
        }

        return .unknown
    }

    // MARK: - Main Parse Function

    func parse(_ text: String) throws -> ParsedConversation {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            throw ParserError.emptyText
        }

        let format = detectFormat(trimmedText)

        let messages: [ParsedMessage]

        switch format {
        case .iMessage:
            messages = try parseIMessage(trimmedText)
        case .whatsApp:
            messages = try parseWhatsApp(trimmedText)
        case .telegram:
            messages = try parseTelegram(trimmedText)
        case .manual:
            messages = try parseManual(trimmedText)
        case .unknown:
            // Try manual parsing as fallback
            messages = try parseManual(trimmedText)
        }

        guard !messages.isEmpty else {
            throw ParserError.noMessagesFound
        }

        let participants = Set(messages.compactMap { $0.sender })

        return ParsedConversation(
            format: format,
            messages: messages,
            participants: participants,
            detectedAt: Date()
        )
    }

    // MARK: - iMessage Parser

    private func parseIMessage(_ text: String) throws -> [ParsedMessage] {
        // Pattern: [MM/DD/YY, HH:MM:SS] Contact Name: Message
        let pattern = #"\[([^\]]+)\]\s*([^:]+):\s*(.*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            throw ParserError.invalidFormat
        }

        let nsText = text as NSString
        let lines = text.components(separatedBy: .newlines)

        var messages: [ParsedMessage] = []
        var currentMessage: (dateStr: String, sender: String, text: String)?

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard !trimmedLine.isEmpty else { continue }

            let range = NSRange(trimmedLine.startIndex..., in: trimmedLine)
            if let match = regex.firstMatch(in: trimmedLine, options: [], range: range) {
                // Save previous message if exists
                if let current = currentMessage {
                    let timestamp = parseDate(current.dateStr, formats: ["M/d/yy, H:mm:ss", "MM/dd/yy, HH:mm:ss", "M/d/yyyy, H:mm:ss"])
                    messages.append(ParsedMessage(
                        text: current.text,
                        sender: current.sender,
                        timestamp: timestamp,
                        isFromUser: false
                    ))
                }

                let nsLine = trimmedLine as NSString
                let dateStr = nsLine.substring(with: match.range(at: 1))
                let sender = nsLine.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
                let messageText = nsLine.substring(with: match.range(at: 3))

                currentMessage = (dateStr, sender, messageText)
            } else if let current = currentMessage {
                // Continuation of previous message
                currentMessage = (current.dateStr, current.sender, current.text + "\n" + trimmedLine)
            }
        }

        // Don't forget the last message
        if let current = currentMessage {
            let timestamp = parseDate(current.dateStr, formats: ["M/d/yy, H:mm:ss", "MM/dd/yy, HH:mm:ss", "M/d/yyyy, H:mm:ss"])
            messages.append(ParsedMessage(
                text: current.text,
                sender: current.sender,
                timestamp: timestamp,
                isFromUser: false
            ))
        }

        return messages
    }

    // MARK: - WhatsApp Parser

    private func parseWhatsApp(_ text: String) throws -> [ParsedMessage] {
        // Pattern: MM/DD/YY, HH:MM - Contact Name: Message
        let pattern = #"(\d{1,2}/\d{1,2}/\d{2,4}, \d{1,2}:\d{2})\s*-\s*([^:]+):\s*(.*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            throw ParserError.invalidFormat
        }

        let lines = text.components(separatedBy: .newlines)

        var messages: [ParsedMessage] = []
        var currentMessage: (dateStr: String, sender: String, text: String)?

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard !trimmedLine.isEmpty else { continue }

            let range = NSRange(trimmedLine.startIndex..., in: trimmedLine)
            if let match = regex.firstMatch(in: trimmedLine, options: [], range: range) {
                // Save previous message if exists
                if let current = currentMessage {
                    let timestamp = parseDate(current.dateStr, formats: ["M/d/yy, H:mm", "MM/dd/yy, HH:mm", "M/d/yyyy, H:mm"])
                    messages.append(ParsedMessage(
                        text: current.text,
                        sender: current.sender,
                        timestamp: timestamp,
                        isFromUser: false
                    ))
                }

                let nsLine = trimmedLine as NSString
                let dateStr = nsLine.substring(with: match.range(at: 1))
                let sender = nsLine.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
                let messageText = nsLine.substring(with: match.range(at: 3))

                currentMessage = (dateStr, sender, messageText)
            } else if let current = currentMessage {
                // Continuation of previous message
                currentMessage = (current.dateStr, current.sender, current.text + "\n" + trimmedLine)
            }
        }

        // Don't forget the last message
        if let current = currentMessage {
            let timestamp = parseDate(current.dateStr, formats: ["M/d/yy, H:mm", "MM/dd/yy, HH:mm", "M/d/yyyy, H:mm"])
            messages.append(ParsedMessage(
                text: current.text,
                sender: current.sender,
                timestamp: timestamp,
                isFromUser: false
            ))
        }

        return messages
    }

    // MARK: - Telegram Parser

    private func parseTelegram(_ text: String) throws -> [ParsedMessage] {
        // Pattern: [HH:MM, DD.MM.YYYY] Contact Name: Message
        let pattern = #"\[(\d{2}:\d{2}, \d{2}\.\d{2}\.\d{4})\]\s*([^:]+):\s*(.*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            throw ParserError.invalidFormat
        }

        let lines = text.components(separatedBy: .newlines)

        var messages: [ParsedMessage] = []
        var currentMessage: (dateStr: String, sender: String, text: String)?

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard !trimmedLine.isEmpty else { continue }

            let range = NSRange(trimmedLine.startIndex..., in: trimmedLine)
            if let match = regex.firstMatch(in: trimmedLine, options: [], range: range) {
                // Save previous message if exists
                if let current = currentMessage {
                    let timestamp = parseDate(current.dateStr, formats: ["HH:mm, dd.MM.yyyy"])
                    messages.append(ParsedMessage(
                        text: current.text,
                        sender: current.sender,
                        timestamp: timestamp,
                        isFromUser: false
                    ))
                }

                let nsLine = trimmedLine as NSString
                let dateStr = nsLine.substring(with: match.range(at: 1))
                let sender = nsLine.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
                let messageText = nsLine.substring(with: match.range(at: 3))

                currentMessage = (dateStr, sender, messageText)
            } else if let current = currentMessage {
                // Continuation of previous message
                currentMessage = (current.dateStr, current.sender, current.text + "\n" + trimmedLine)
            }
        }

        // Don't forget the last message
        if let current = currentMessage {
            let timestamp = parseDate(current.dateStr, formats: ["HH:mm, dd.MM.yyyy"])
            messages.append(ParsedMessage(
                text: current.text,
                sender: current.sender,
                timestamp: timestamp,
                isFromUser: false
            ))
        }

        return messages
    }

    // MARK: - Manual Parser

    private func parseManual(_ text: String) throws -> [ParsedMessage] {
        // Simple format: "Name: Message" per line
        let lines = text.components(separatedBy: .newlines)

        var messages: [ParsedMessage] = []
        var lastSender: String? = nil

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // Try to split on first colon
            if let colonIndex = trimmed.firstIndex(of: ":") {
                let sender = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let message = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)

                // Only treat as sender:message if sender is short (less than 50 chars)
                // and the message part is not empty
                if sender.count > 0 && sender.count < 50 && !message.isEmpty {
                    lastSender = sender
                    messages.append(ParsedMessage(
                        text: message,
                        sender: sender,
                        timestamp: nil,
                        isFromUser: false
                    ))
                } else {
                    // Treat whole line as message from last sender or unknown
                    messages.append(ParsedMessage(
                        text: trimmed,
                        sender: lastSender ?? "Unknown",
                        timestamp: nil,
                        isFromUser: false
                    ))
                }
            } else {
                // No colon, treat whole line as message from last sender
                messages.append(ParsedMessage(
                    text: trimmed,
                    sender: lastSender ?? "Unknown",
                    timestamp: nil,
                    isFromUser: false
                ))
            }
        }

        return messages
    }

    // MARK: - Helpers

    private func parseDate(_ dateString: String, formats: [String]) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }

    // MARK: - Errors

    enum ParserError: LocalizedError {
        case unknownFormat
        case invalidFormat
        case emptyText
        case noMessagesFound

        var errorDescription: String? {
            switch self {
            case .unknownFormat:
                return "Unable to recognize the conversation format"
            case .invalidFormat:
                return "The text format is invalid"
            case .emptyText:
                return "Please paste some text to parse"
            case .noMessagesFound:
                return "No messages could be extracted from the text"
            }
        }
    }
}

// MARK: - String Extension

extension String {
    func contains(regex pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let range = NSRange(self.startIndex..., in: self)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}
