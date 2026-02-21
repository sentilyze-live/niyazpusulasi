import XCTest

final class ScreenshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Use Istanbul coordinates for demo data
        app.launchArguments += [
            "-FASTLANE_SNAPSHOT", "YES",
            "-SCREENSHOT_MODE", "YES"
        ]
        setupSnapshot(app)
        app.launch()

        // Dismiss any system permission alerts (location, notifications, etc.)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for title in ["Allow While Using App", "Allow Once", "Don't Allow", "İzin Ver"] {
            let btn = springboard.buttons[title]
            if btn.waitForExistence(timeout: 3) { btn.tap() }
        }
    }

    // MARK: - Helpers

    /// Navigates to a tab by index. Waits up to 10 s for the tab bar.
    private func goToTab(_ index: Int) {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 10) else { return }
        tabBar.buttons.element(boundBy: index).tap()
        sleep(2)
    }

    // MARK: - Screenshot 1: Today / Prayer Times

    func test01_TodayView() throws {
        // App starts on TodayView (tab 0) by default.
        // Wait for content to load rather than trying to tap the tab immediately.
        sleep(4)
        snapshot("01_today_prayer_times")
    }

    // MARK: - Screenshot 2: Ramadan / Imsakiye

    func test02_RamadanView() throws {
        sleep(2)
        goToTab(1)
        snapshot("02_ramadan_imsakiye")
    }

    // MARK: - Screenshot 3: Habits / Heatmap

    func test03_HabitsView() throws {
        sleep(2)
        goToTab(2)
        snapshot("03_habits_heatmap")
    }
}
