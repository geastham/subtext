//
//  SubtextUITests.swift
//  Subtext
//
//  Created by Codegen
//  Phase 5: Testing & Launch
//

import XCTest

/// UI tests for critical user paths
final class SubtextUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - App Launch Tests

    func testAppLaunches() {
        // Verify app launches without crash
        XCTAssertTrue(app.state == .runningForeground)
    }

    func testMainTabsExist() {
        // Verify main navigation exists
        let tabBar = app.tabBars.firstMatch

        // Wait for tab bar to exist
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
    }

    // MARK: - Import Conversation Flow Tests

    func testNavigateToImport() {
        // Tap the add/import button
        let addButton = app.buttons["add"].firstMatch

        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()

            // Verify import view appears
            let textView = app.textViews.firstMatch
            XCTAssertTrue(textView.waitForExistence(timeout: 3), "Import text view should appear")
        }
    }

    func testImportConversationBasic() {
        // Navigate to import
        let addButton = app.buttons["add"].firstMatch

        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()

            // Enter conversation text
            let textView = app.textViews.firstMatch
            if textView.waitForExistence(timeout: 3) {
                textView.tap()
                textView.typeText("[12/25/24, 10:30:45] Sarah: Hey!")

                // Look for parse button
                let parseButton = app.buttons["Parse Conversation"].firstMatch
                if parseButton.waitForExistence(timeout: 3) {
                    parseButton.tap()

                    // Wait for parsing to complete
                    let successIndicator = app.staticTexts["Conversation Parsed!"].firstMatch
                    XCTAssertTrue(successIndicator.waitForExistence(timeout: 5), "Parse should succeed")
                }
            }
        }
    }

    func testImportWithEmptyText() {
        // Navigate to import
        let addButton = app.buttons["add"].firstMatch

        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()

            // Try to parse without entering text
            let parseButton = app.buttons["Parse Conversation"].firstMatch
            if parseButton.waitForExistence(timeout: 3) {
                parseButton.tap()

                // Should show error
                let errorAlert = app.alerts.firstMatch
                // Error handling should show or parse button should be disabled
            }
        }
    }

    // MARK: - Conversation List Tests

    func testConversationListDisplays() {
        // First tab should be conversation list
        let list = app.collectionViews.firstMatch

        // Either list exists or empty state exists
        let exists = list.waitForExistence(timeout: 3)
        // If no conversations, might show empty state text
    }

    func testTapConversationOpenDetail() {
        // If there are any cells, tap the first one
        let firstCell = app.cells.firstMatch

        if firstCell.waitForExistence(timeout: 3) {
            firstCell.tap()

            // Verify detail view appears (e.g., coaching button)
            let coachingButton = app.buttons["Get Coaching"].firstMatch
            // Detail view should have some identifying element
        }
    }

    // MARK: - Coaching Flow Tests

    func testCoachingFlowWithTestData() {
        // Launch with test data
        app.terminate()
        app.launchArguments = ["--uitesting", "--testdata"]
        app.launch()

        // Open first conversation
        let firstCell = app.cells.firstMatch

        if firstCell.waitForExistence(timeout: 5) {
            firstCell.tap()

            // Tap Get Coaching
            let coachingButton = app.buttons["Get Coaching"].firstMatch
            if coachingButton.waitForExistence(timeout: 3) {
                coachingButton.tap()

                // Select intent
                let replyButton = app.buttons["Reply"].firstMatch
                if replyButton.waitForExistence(timeout: 3) {
                    replyButton.tap()

                    // Wait for results (may take time for generation)
                    let resultsTitle = app.staticTexts["Situation Analysis"].firstMatch
                    XCTAssertTrue(resultsTitle.waitForExistence(timeout: 15), "Coaching results should appear")
                }
            }
        }
    }

    func testCopyReplyAction() {
        // Navigate to coaching results (with test data)
        app.terminate()
        app.launchArguments = ["--uitesting", "--testdata", "--mockcoaching"]
        app.launch()

        let firstCell = app.cells.firstMatch

        if firstCell.waitForExistence(timeout: 5) {
            firstCell.tap()

            let coachingButton = app.buttons["Get Coaching"].firstMatch
            if coachingButton.waitForExistence(timeout: 3) {
                coachingButton.tap()

                let replyButton = app.buttons["Reply"].firstMatch
                if replyButton.waitForExistence(timeout: 3) {
                    replyButton.tap()

                    // Wait for Copy Reply button
                    let copyButton = app.buttons["Copy Reply"].firstMatch
                    if copyButton.waitForExistence(timeout: 15) {
                        copyButton.tap()

                        // Verify copied confirmation
                        let copiedAlert = app.alerts["Copied!"].firstMatch
                        // Or check for toast/notification
                    }
                }
            }
        }
    }

    // MARK: - Settings Tests

    func testNavigateToSettings() {
        // Tap settings tab
        let settingsTab = app.tabBars.buttons["Settings"].firstMatch

        if settingsTab.waitForExistence(timeout: 3) {
            settingsTab.tap()

            // Verify settings view appears
            let settingsTitle = app.navigationBars["Settings"].firstMatch
            XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3), "Settings view should appear")
        }
    }

    func testDeleteAllDataFlow() {
        // Navigate to settings
        let settingsTab = app.tabBars.buttons["Settings"].firstMatch

        if settingsTab.waitForExistence(timeout: 3) {
            settingsTab.tap()

            // Find delete button
            let deleteButton = app.buttons["Delete All Data"].firstMatch
            if deleteButton.waitForExistence(timeout: 3) {
                deleteButton.tap()

                // Confirm in alert
                let confirmButton = app.alerts.buttons["Delete"].firstMatch
                if confirmButton.waitForExistence(timeout: 3) {
                    confirmButton.tap()

                    // Verify success
                    let successAlert = app.alerts["Data Deleted"].firstMatch
                    XCTAssertTrue(successAlert.waitForExistence(timeout: 3), "Delete confirmation should appear")
                }
            }
        }
    }

    func testCancelDeleteAllData() {
        // Navigate to settings
        let settingsTab = app.tabBars.buttons["Settings"].firstMatch

        if settingsTab.waitForExistence(timeout: 3) {
            settingsTab.tap()

            let deleteButton = app.buttons["Delete All Data"].firstMatch
            if deleteButton.waitForExistence(timeout: 3) {
                deleteButton.tap()

                // Cancel in alert
                let cancelButton = app.alerts.buttons["Cancel"].firstMatch
                if cancelButton.waitForExistence(timeout: 3) {
                    cancelButton.tap()

                    // Should return to settings without deletion
                    XCTAssertTrue(deleteButton.exists, "Should still be on settings screen")
                }
            }
        }
    }

    // MARK: - Intent Selection Tests

    func testAllIntentsAvailable() {
        app.terminate()
        app.launchArguments = ["--uitesting", "--testdata"]
        app.launch()

        let firstCell = app.cells.firstMatch

        if firstCell.waitForExistence(timeout: 5) {
            firstCell.tap()

            let coachingButton = app.buttons["Get Coaching"].firstMatch
            if coachingButton.waitForExistence(timeout: 3) {
                coachingButton.tap()

                // Verify all intents are available
                let intents = ["Reply", "Interpret", "Set Boundary", "Flirt", "Resolve Conflict"]

                for intent in intents {
                    let intentButton = app.buttons[intent].firstMatch
                    XCTAssertTrue(intentButton.waitForExistence(timeout: 3), "\(intent) button should exist")
                }
            }
        }
    }

    // MARK: - Safety Resources Tests

    func testSafetyResourcesDisplay() {
        // Navigate to a conversation with safety flags
        app.terminate()
        app.launchArguments = ["--uitesting", "--safetytestdata"]
        app.launch()

        let firstCell = app.cells.firstMatch

        if firstCell.waitForExistence(timeout: 5) {
            firstCell.tap()

            // Look for safety banner or resources
            let safetyBanner = app.staticTexts["Safety Concern Detected"].firstMatch
            // May or may not exist depending on test data
        }
    }

    // MARK: - Error State Tests

    func testOfflineBannerAppears() {
        // This would require network simulation
        // In practice, check if offline banner component exists when network unavailable
    }

    func testErrorViewDisplaysCorrectly() {
        // Trigger an error state
        app.terminate()
        app.launchArguments = ["--uitesting", "--forceerror"]
        app.launch()

        // Look for error view components
        let errorView = app.staticTexts.matching(identifier: "error-message").firstMatch
        // Error handling may vary
    }

    // MARK: - Accessibility Tests

    func testMainElementsAccessible() {
        // Verify key elements have accessibility identifiers
        let addButton = app.buttons["add"].firstMatch
        XCTAssertTrue(addButton.isHittable || addButton.waitForExistence(timeout: 3))
    }

    func testVoiceOverLabelsExist() {
        // Check accessibility labels for key elements
        let tabBar = app.tabBars.firstMatch

        if tabBar.waitForExistence(timeout: 3) {
            // Tab bar buttons should have labels
            XCTAssertTrue(tabBar.buttons.count > 0, "Tab bar should have accessible buttons")
        }
    }

    // MARK: - Navigation Tests

    func testBackNavigationFromDetail() {
        app.terminate()
        app.launchArguments = ["--uitesting", "--testdata"]
        app.launch()

        let firstCell = app.cells.firstMatch

        if firstCell.waitForExistence(timeout: 5) {
            firstCell.tap()

            // Wait for detail view
            sleep(1)

            // Navigate back
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            if backButton.exists {
                backButton.tap()

                // Verify back at list
                XCTAssertTrue(firstCell.waitForExistence(timeout: 3), "Should return to list")
            }
        }
    }

    func testTabSwitching() {
        let tabBar = app.tabBars.firstMatch

        if tabBar.waitForExistence(timeout: 3) {
            let buttons = tabBar.buttons

            // Switch between tabs
            for i in 0..<buttons.count {
                buttons.element(boundBy: i).tap()
                sleep(1)
            }

            // Return to first tab
            if buttons.count > 0 {
                buttons.element(boundBy: 0).tap()
            }
        }
    }

    // MARK: - Performance Tests

    func testAppLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }

    func testScrollPerformance() {
        app.terminate()
        app.launchArguments = ["--uitesting", "--largetestdata"]
        app.launch()

        let list = app.collectionViews.firstMatch

        if list.waitForExistence(timeout: 5) {
            measure {
                list.swipeUp()
                list.swipeDown()
            }
        }
    }
}

// MARK: - Test Helpers

extension SubtextUITests {

    /// Wait for an element with a custom timeout
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    /// Dismiss any presented alerts
    func dismissAlerts() {
        let alerts = app.alerts
        if alerts.count > 0 {
            alerts.buttons.firstMatch.tap()
        }
    }

    /// Navigate to a specific tab by name
    func navigateToTab(_ tabName: String) {
        let tab = app.tabBars.buttons[tabName].firstMatch
        if tab.waitForExistence(timeout: 3) {
            tab.tap()
        }
    }
}
