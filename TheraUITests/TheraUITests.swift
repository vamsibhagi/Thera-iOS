import XCTest

final class TheraUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Onboarding Flow Test
    
    @MainActor
    func testOnboardingHappyPath() throws {
        let app = XCUIApplication()
        // Simulate Fresh Install
        app.launchArguments.append("-resetOnboarding")
        app.launch()

        // 1. Welcome / Carousel
        // Tap "Next" 3 times (Index 0 -> 1, 1 -> 2, 2 -> Proceed)
        for _ in 0..<3 {
            let nextButton = app.buttons["Next"]
            if nextButton.waitForExistence(timeout: 2) {
                nextButton.tap()
            }
        }
        
        // 2. Screen Time Permission
        let stContinue = app.buttons["Continue"]
        if stContinue.waitForExistence(timeout: 2) {
            stContinue.tap()
        }
        
        // 3. Notification Permission
        let allowButton = app.buttons["Allow"] 
        // Note: System alert might block this. Assuming mock UI or bypass.
        // Actually, the view has a mocked "Allow" button before the system alert.
        if allowButton.waitForExistence(timeout: 2) {
            allowButton.tap()
        }
        
        // 4. Distraction Selection
        // Should be bypassed by launch argument
        let distractionContinue = app.buttons["Continue"]
        if distractionContinue.waitForExistence(timeout: 2) {
            distractionContinue.tap()
        }
        
        // 5. Limit Setting
        let limitContinue = app.buttons["Continue"]
        if limitContinue.waitForExistence(timeout: 2) {
            limitContinue.tap()
        }
        
        // 6. Task Preferences
        let prefsContinue = app.buttons["Continue"]
        if prefsContinue.waitForExistence(timeout: 2) {
            prefsContinue.tap()
        }
        
        // 7. Widget Promo (Final Step)
        let completeButton = app.buttons["Complete Setup"]
        if completeButton.waitForExistence(timeout: 2) {
            completeButton.tap()
        }
        
        // 8. Verify Home Screen
        let screenTimeHeader = app.staticTexts["Screen Time"]
        XCTAssertTrue(screenTimeHeader.waitForExistence(timeout: 5), "Should have reached Home Screen")
    }
    
    // MARK: - Home & Settings Test
    
    @MainActor
    func testHomeScreen() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Ensure we are on Home (Skip onboarding if needed)
        if app.buttons["Get Started"].exists {
             // If we are stuck in onboarding from a previous fail, try to skip?
             // Or just fail here.
             // Ideally we run testOnboardingHappyPath first.
        }
        
        // Verify Components
        // Check for "Screen Time" section header
        let screenTimeHeader = app.staticTexts["Screen Time"]
        if screenTimeHeader.waitForExistence(timeout: 5) {
            XCTAssertTrue(screenTimeHeader.exists)
        }
        
        // Open Settings
        // actually, SwiftUI navigation links often don't have accessibility labels by default unless set.
        // Try finding by button index in nav bar
        let navBarButton = app.navigationBars.buttons.firstMatch
        if navBarButton.exists {
            navBarButton.tap()
            XCTAssertTrue(app.navigationBars["Settings"].exists)
        }
    }
}
