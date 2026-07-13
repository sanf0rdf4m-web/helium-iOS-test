import XCTest

final class HeliumUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        app = XCUIApplication()
        app.launch()
    }

    func testVerticalTabsAndNewTabShell() {
        let expandTabs = app.buttons["Expand vertical tabs"]
        let collapseTabs = app.buttons["Collapse vertical tabs"]
        if expandTabs.waitForExistence(timeout: 2) {
            expandTabs.tap()
        } else {
            XCTAssertTrue(collapseTabs.waitForExistence(timeout: 3))
        }

        XCTAssertTrue(app.staticTexts["New Tab"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Add shortcut"].exists)
        XCTAssertTrue(app.buttons["Privacy shields"].exists)
        XCTAssertTrue(app.buttons["Helium menu"].exists)

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Helium iPad vertical tabs"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testSettingsSurface() {
        let menu = app.buttons["Helium menu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()

        let settings = app.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 3))
        settings.tap()

        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.textFields["Search settings"].exists)
        XCTAssertTrue(app.staticTexts["Appearance and behavior"].exists)

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Helium iPad settings"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testShieldsPanel() {
        let shields = app.buttons["Privacy shields"]
        XCTAssertTrue(shields.waitForExistence(timeout: 5))
        shields.tap()

        XCTAssertTrue(app.staticTexts["Blocked on this page"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Domains connected"].exists)
        XCTAssertTrue(app.buttons["Show protection details"].exists)

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Helium iPad shields"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
