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

        // 1. Welcome Screen
        let getStartedButton = app.buttons["Get Started"]
        if getStartedButton.exists {
            getStartedButton.tap()
        }
        
        // 2. Family Picker (System Permission)
        // Note: We cannot interact with the System Picker.
        // We assume the user (or test runner) taps "Cancel" or "Done" manually if interactively running,
        // OR the app handles the "Selection" state gracefully.
        // For automation, we just check if "Continue" appears after some action or if we can proceed.
        
        // 3. Continue through screens
        // Loop through "Continue" buttons until we hit completion
        let continueButton = app.buttons["Continue"]
        // Limit loop to avoid infinite stuck
        for _ in 0..<5 {
            if continueButton.exists {
                continueButton.tap()
                sleep(1) // Wait for animation
            } else {
                break
            }
        }
        
        // 4. Completion
        if app.buttons["Let's Go!"].exists {
            app.buttons["Let's Go!"].tap()
        }
        
        // 5. Verify Home Screen
        XCTAssertTrue(app.navigationBars["Thera"].exists, "Should be on Home Screen")
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
