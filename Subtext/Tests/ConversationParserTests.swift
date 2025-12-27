//
//  ConversationParserTests.swift
//  Subtext
//
//  Created by Codegen
//  Phase 2: Conversation Management
//

import XCTest
@testable import Subtext

final class ConversationParserTests: XCTestCase {

    // MARK: - Format Detection Tests

    func testDetectIMessageFormat() async throws {
        let sample = "[12/25/24, 10:30:45] Sarah: Hey there!"
        let format = await ConversationParser.shared.detectFormat(sample)
        XCTAssertEqual(format, .iMessage)
    }

    func testDetectIMessageFormatMultipleMessages() async throws {
        let sample = """
        [12/25/24, 10:30:45] Sarah: Hey there!
        [12/25/24, 10:31:00] John: Hi Sarah!
        [12/25/24, 10:31:30] Sarah: How are you?
        """
        let format = await ConversationParser.shared.detectFormat(sample)
        XCTAssertEqual(format, .iMessage)
    }

    func testDetectWhatsAppFormat() async throws {
        let sample = "12/25/24, 10:30 - Sarah: Hey!"
        let format = await ConversationParser.shared.detectFormat(sample)
        XCTAssertEqual(format, .whatsApp)
    }

    func testDetectWhatsAppFormatMultipleMessages() async throws {
        let sample = """
        12/25/24, 10:30 - Sarah: Hey!
        12/25/24, 10:31 - John: Hi Sarah!
        12/25/24, 10:32 - Sarah: Want to grab coffee?
        """
        let format = await ConversationParser.shared.detectFormat(sample)
        XCTAssertEqual(format, .whatsApp)
    }

    func testDetectTelegramFormat() async throws {
        let sample = "[10:30, 25.12.2024] Sarah: Hey!"
        let format = await ConversationParser.shared.detectFormat(sample)
        XCTAssertEqual(format, .telegram)
    }

    func testDetectTelegramFormatMultipleMessages() async throws {
        let sample = """
        [10:30, 25.12.2024] Sarah: Hey!
        [10:31, 25.12.2024] John: Hi there!
        [10:32, 25.12.2024] Sarah: How's it going?
        """
        let format = await ConversationParser.shared.detectFormat(sample)
        XCTAssertEqual(format, .telegram)
    }

    func testDetectManualFormat() async throws {
        let sample = """
        Sarah: Hey!
        John: Hi!
        Sarah: How are you?
        """
        let format = await ConversationParser.shared.detectFormat(sample)
        XCTAssertEqual(format, .manual)
    }

    func testDetectUnknownFormat() async throws {
        let sample = "This is just plain text with no structure"
        let format = await ConversationParser.shared.detectFormat(sample)
        XCTAssertEqual(format, .unknown)
    }

    // MARK: - Parse iMessage Tests

    func testParseIMessageConversation() async throws {
        let sample = """
        [12/25/24, 10:30:45] Sarah: Hey there!
        [12/25/24, 10:31:00] John: Hi Sarah!
        [12/25/24, 10:31:30] Sarah: Want to grab coffee?
        """
        let parsed = try await ConversationParser.shared.parse(sample)

        XCTAssertEqual(parsed.format, .iMessage)
        XCTAssertEqual(parsed.messages.count, 3)
        XCTAssertEqual(parsed.participants.count, 2)
        XCTAssertTrue(parsed.participants.contains("Sarah"))
        XCTAssertTrue(parsed.participants.contains("John"))

        XCTAssertEqual(parsed.messages[0].text, "Hey there!")
        XCTAssertEqual(parsed.messages[0].sender, "Sarah")

        XCTAssertEqual(parsed.messages[1].text, "Hi Sarah!")
        XCTAssertEqual(parsed.messages[1].sender, "John")

        XCTAssertEqual(parsed.messages[2].text, "Want to grab coffee?")
        XCTAssertEqual(parsed.messages[2].sender, "Sarah")
    }

    func testParseIMessageWithMultilineMessage() async throws {
        let sample = """
        [12/25/24, 10:30:45] Sarah: Hey there!
        How are you doing?
        [12/25/24, 10:31:00] John: I'm good!
        """
        let parsed = try await ConversationParser.shared.parse(sample)

        XCTAssertEqual(parsed.messages.count, 2)
        XCTAssertEqual(parsed.messages[0].text, "Hey there!\nHow are you doing?")
    }

    // MARK: - Parse WhatsApp Tests

    func testParseWhatsAppConversation() async throws {
        let sample = """
        12/25/24, 10:30 - Sarah: Hey!
        12/25/24, 10:31 - John: Hi Sarah!
        """
        let parsed = try await ConversationParser.shared.parse(sample)

        XCTAssertEqual(parsed.format, .whatsApp)
        XCTAssertEqual(parsed.messages.count, 2)
        XCTAssertEqual(parsed.participants.count, 2)

        XCTAssertEqual(parsed.messages[0].text, "Hey!")
        XCTAssertEqual(parsed.messages[0].sender, "Sarah")

        XCTAssertEqual(parsed.messages[1].text, "Hi Sarah!")
        XCTAssertEqual(parsed.messages[1].sender, "John")
    }

    func testParseWhatsAppWithMultilineMessage() async throws {
        let sample = """
        12/25/24, 10:30 - Sarah: Hey!
        This is a continuation of my message
        12/25/24, 10:31 - John: Got it!
        """
        let parsed = try await ConversationParser.shared.parse(sample)

        XCTAssertEqual(parsed.messages.count, 2)
        XCTAssertEqual(parsed.messages[0].text, "Hey!\nThis is a continuation of my message")
    }

    // MARK: - Parse Telegram Tests

    func testParseTelegramConversation() async throws {
        let sample = """
        [10:30, 25.12.2024] Sarah: Hey!
        [10:31, 25.12.2024] John: Hi there!
        """
        let parsed = try await ConversationParser.shared.parse(sample)

        XCTAssertEqual(parsed.format, .telegram)
        XCTAssertEqual(parsed.messages.count, 2)
        XCTAssertEqual(parsed.participants.count, 2)

        XCTAssertEqual(parsed.messages[0].text, "Hey!")
        XCTAssertEqual(parsed.messages[0].sender, "Sarah")

        XCTAssertEqual(parsed.messages[1].text, "Hi there!")
        XCTAssertEqual(parsed.messages[1].sender, "John")
    }

    // MARK: - Parse Manual Tests

    func testParseManualConversation() async throws {
        let sample = """
        Sarah: Hey!
        John: Hi!
        Sarah: How are you?
        John: I'm good, thanks!
        """
        let parsed = try await ConversationParser.shared.parse(sample)

        XCTAssertEqual(parsed.format, .manual)
        XCTAssertEqual(parsed.messages.count, 4)
        XCTAssertEqual(parsed.participants.count, 2)

        XCTAssertEqual(parsed.messages[0].text, "Hey!")
        XCTAssertEqual(parsed.messages[0].sender, "Sarah")

        XCTAssertEqual(parsed.messages[3].text, "I'm good, thanks!")
        XCTAssertEqual(parsed.messages[3].sender, "John")
    }

    func testParseManualWithContinuation() async throws {
        let sample = """
        Sarah: Hey!
        How are you?
        John: I'm good!
        """
        let parsed = try await ConversationParser.shared.parse(sample)

        XCTAssertEqual(parsed.messages.count, 3)
        // "How are you?" should be attributed to Sarah (continuation)
        XCTAssertEqual(parsed.messages[1].sender, "Sarah")
        XCTAssertEqual(parsed.messages[1].text, "How are you?")
    }

    // MARK: - Error Tests

    func testParseEmptyText() async {
        do {
            _ = try await ConversationParser.shared.parse("")
            XCTFail("Should throw error for empty text")
        } catch {
            XCTAssertTrue(error is ConversationParser.ParserError)
            if let parserError = error as? ConversationParser.ParserError {
                XCTAssertEqual(parserError.localizedDescription, "Please paste some text to parse")
            }
        }
    }

    func testParseWhitespaceOnlyText() async {
        do {
            _ = try await ConversationParser.shared.parse("   \n\n   ")
            XCTFail("Should throw error for whitespace-only text")
        } catch {
            XCTAssertTrue(error is ConversationParser.ParserError)
        }
    }

    // MARK: - Edge Case Tests

    func testParseWithEmojis() async throws {
        let sample = """
        Sarah: Hey! 😊
        John: Hi! 👋 How are you?
        """
        let parsed = try await ConversationParser.shared.parse(sample)

        XCTAssertEqual(parsed.messages.count, 2)
        XCTAssertEqual(parsed.messages[0].text, "Hey! 😊")
        XCTAssertEqual(parsed.messages[1].text, "Hi! 👋 How are you?")
    }

    func testParseWithSpecialCharacters() async throws {
        let sample = """
        Sarah: Hey! What's up?
        John: Nothing much... just chilling!
        Sarah: Cool - want to hang out?
        """
        let parsed = try await ConversationParser.shared.parse(sample)

        XCTAssertEqual(parsed.messages.count, 3)
        XCTAssertEqual(parsed.messages[0].text, "Hey! What's up?")
        XCTAssertEqual(parsed.messages[1].text, "Nothing much... just chilling!")
        XCTAssertEqual(parsed.messages[2].text, "Cool - want to hang out?")
    }

    func testParseWithVeryLongMessage() async throws {
        let longText = String(repeating: "a", count: 1000)
        let sample = "Sarah: \(longText)"

        let parsed = try await ConversationParser.shared.parse(sample)

        XCTAssertEqual(parsed.messages.count, 1)
        XCTAssertEqual(parsed.messages[0].text.count, 1000)
    }

    func testParseThreeParticipants() async throws {
        let sample = """
        Sarah: Hey guys!
        John: Hi!
        Mike: Hey there!
        Sarah: Want to get lunch?
        """
        let parsed = try await ConversationParser.shared.parse(sample)

        XCTAssertEqual(parsed.messages.count, 4)
        XCTAssertEqual(parsed.participants.count, 3)
        XCTAssertTrue(parsed.participants.contains("Sarah"))
        XCTAssertTrue(parsed.participants.contains("John"))
        XCTAssertTrue(parsed.participants.contains("Mike"))
    }

    // MARK: - Timestamp Tests

    func testIMessageTimestampParsing() async throws {
        let sample = "[12/25/24, 10:30:45] Sarah: Hey!"
        let parsed = try await ConversationParser.shared.parse(sample)

        XCTAssertNotNil(parsed.messages[0].timestamp)
        if let timestamp = parsed.messages[0].timestamp {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.month, .day, .hour, .minute, .second], from: timestamp)
            XCTAssertEqual(components.month, 12)
            XCTAssertEqual(components.day, 25)
            XCTAssertEqual(components.hour, 10)
            XCTAssertEqual(components.minute, 30)
            XCTAssertEqual(components.second, 45)
        }
    }

    func testManualFormatNoTimestamp() async throws {
        let sample = "Sarah: Hey!"
        let parsed = try await ConversationParser.shared.parse(sample)

        XCTAssertNil(parsed.messages[0].timestamp)
    }
}
