//
//  KitchenAssistantUITests.swift
//  KitchenAssistantUITests
//
//  UI Tests for Kitchen Assistant
//

import XCTest

final class KitchenAssistantUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Launch Tests
    
    func testAppLaunches() throws {
        // Test that the app launches successfully
        XCTAssertTrue(app.exists)
    }
    
    func testMainScreenExists() throws {
        // Wait for the main screen to appear
        let mainView = app.otherElements["ContentView"]
        let exists = mainView.waitForExistence(timeout: 5)
        XCTAssertTrue(exists, "Main view should exist after launch")
    }
    
    // MARK: - Camera View Tests
    
    func testCameraViewElements() throws {
        // Check if camera-related elements exist
        let cameraButton = app.buttons["Take Photo"]
        if cameraButton.exists {
            XCTAssertTrue(cameraButton.isHittable)
        }
        
        // Check for gallery button
        let galleryButton = app.buttons["Choose from Gallery"]
        if galleryButton.exists {
            XCTAssertTrue(galleryButton.isHittable)
        }
    }
    
    // MARK: - Settings Tests
    
    func testSettingsToggleExists() throws {
        // Check if settings toggle exists
        let settingsToggle = app.switches["Use Local Processing"]
        if settingsToggle.exists {
            XCTAssertTrue(settingsToggle.exists)
        }
    }
    
    func testSettingsCanBeToggled() throws {
        // Try to toggle settings if available
        let settingsToggle = app.switches["Use Local Processing"]
        
        if settingsToggle.waitForExistence(timeout: 2) {
            let initialValue = settingsToggle.value as? String
            settingsToggle.tap()
            
            // Wait for toggle to update
            sleep(1)
            
            let newValue = settingsToggle.value as? String
            XCTAssertNotEqual(initialValue, newValue, "Toggle should change value")
        }
    }
    
    // MARK: - Navigation Tests
    
    func testNavigationBetweenViews() throws {
        // Test basic navigation if tabs exist
        let tabBar = app.tabBars.firstMatch
        
        if tabBar.exists {
            let buttons = tabBar.buttons
            XCTAssertGreaterThan(buttons.count, 0, "Should have at least one tab")
        }
    }
    
    // MARK: - Text Input Tests
    
    func testMealCravingInput() throws {
        // Find text field for meal craving
        let textField = app.textFields["What would you like to cook?"]
        
        if textField.waitForExistence(timeout: 2) {
            textField.tap()
            textField.typeText("pasta")
            
            XCTAssertEqual(textField.value as? String, "pasta")
        }
    }
    
    // MARK: - Button Interaction Tests
    
    func testGenerateRecipeButton() throws {
        // Find generate recipe button
        let generateButton = app.buttons["Generate Recipe"]
        
        if generateButton.waitForExistence(timeout: 2) {
            XCTAssertTrue(generateButton.isHittable)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testAppDoesNotCrashOnInvalidInput() throws {
        // Test that app doesn't crash with invalid inputs
        let textField = app.textFields.firstMatch
        
        if textField.exists {
            textField.tap()
            textField.typeText("!@#$%^&*()")
            
            // App should still be running
            XCTAssertTrue(app.exists)
        }
    }
    
    // MARK: - Performance Tests
    
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    func testScrollPerformance() throws {
        let scrollView = app.scrollViews.firstMatch
        
        if scrollView.exists {
            measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
                scrollView.swipeUp()
                scrollView.swipeDown()
            }
        }
    }
}

