import XCTest

final class SlideshowUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    // MARK: - Welcome Screen

    func testLaunchShowsWelcomeScreen() throws {
        app.launch()

        let openButton = app.buttons["openSlideshowButton"]
        let createButton = app.buttons["createNewButton"]
        XCTAssertTrue(openButton.waitForExistence(timeout: 5))
        XCTAssertTrue(createButton.exists)
    }

    // MARK: - Fixture Mode

    func testFixtureModeLoadsSlides() throws {
        app.launchArguments = ["--ui-test-fixtures"]
        app.launch()

        // Toolbar "Present" button appears when slides are loaded.
        // Use .firstMatch — toolbar buttons may have multiple AX representations.
        let presentButton = app.buttons["presentButton"].firstMatch
        XCTAssertTrue(presentButton.waitForExistence(timeout: 10),
                       "Present button should appear after loading fixtures")
        XCTAssertTrue(presentButton.isEnabled,
                       "Present button should be enabled when slides are loaded")
    }

    func testFixtureModeShowsSlideContent() throws {
        app.launchArguments = ["--ui-test-fixtures"]
        app.launch()

        // Wait for slides to load
        let presentButton = app.buttons["presentButton"]
        XCTAssertTrue(presentButton.waitForExistence(timeout: 10))

        // Verify a caption from the example sidecar is visible
        // "Paintings That Tell Secrets" has "The Night Watch" as first slide caption
        let nightWatch = app.staticTexts["The Night Watch"]
        XCTAssertTrue(nightWatch.waitForExistence(timeout: 5),
                       "Should show 'The Night Watch' caption from example sidecar")
    }

    func testSlideSelection() throws {
        app.launchArguments = ["--ui-test-fixtures"]
        app.launch()

        let presentButton = app.buttons["presentButton"]
        XCTAssertTrue(presentButton.waitForExistence(timeout: 10))

        // Click on a different slide to change selection
        let starryNight = app.staticTexts["Starry Night"]
        if starryNight.waitForExistence(timeout: 5) {
            starryNight.click()
            // Verify the inspector updates — look for caption text field
            let captionField = app.textFields.firstMatch
            XCTAssertTrue(captionField.waitForExistence(timeout: 3))
        }
    }

    // MARK: - Add Images

    func testAddImagesFromExamples() throws {
        app.launchArguments = ["--ui-test-add-images"]
        app.launch()

        let presentButton = app.buttons["presentButton"].firstMatch
        XCTAssertTrue(presentButton.waitForExistence(timeout: 10),
                       "Present button should appear after adding images")
        XCTAssertTrue(presentButton.isEnabled,
                       "Present button should be enabled when slides are loaded")
    }

    // MARK: - Accessibility

    func testAccessibilityAudit() throws {
        app.launchArguments = ["--ui-test-fixtures"]
        app.launch()

        let presentButton = app.buttons["presentButton"].firstMatch
        XCTAssertTrue(presentButton.waitForExistence(timeout: 10))

        try app.performAccessibilityAudit()
    }

    // MARK: - Keyboard Navigation

    func testEscapeFromWelcomeScreen() throws {
        app.launch()
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(app.buttons["openSlideshowButton"].exists,
                       "App should still show welcome screen after Escape")
    }
}
