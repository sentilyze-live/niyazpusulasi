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
    }

    // MARK: - Screenshot 1: Today / Prayer Times

    func test01_TodayView() throws {
        // Wait for app to load
        sleep(3)

        // Tap the first tab (Bugün)
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons.element(boundBy: 0).tap()
        sleep(2)

        snapshot("01_today_prayer_times")
    }

    // MARK: - Screenshot 2: Ramadan / Imsakiye

    func test02_RamadanView() throws {
        sleep(2)

        let tabBar = app.tabBars.firstMatch
        tabBar.buttons.element(boundBy: 1).tap()
        sleep(2)

        snapshot("02_ramadan_imsakiye")
    }

    // MARK: - Screenshot 3: Habits / Heatmap

    func test03_HabitsView() throws {
        sleep(2)

        let tabBar = app.tabBars.firstMatch
        tabBar.buttons.element(boundBy: 2).tap()
        sleep(2)

        snapshot("03_habits_heatmap")
    }
}
