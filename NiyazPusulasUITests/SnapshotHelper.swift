//
//  SnapshotHelper.swift
//  Example
//
//  Created by Felix Krause on 10/8/15.
//  Copyright (c) 2015 Felix Krause. All rights reserved.
//

// -----------------------------------------------------
// IMPORTANT: When modifying this file, make sure to
//            track the changes in the fastlane code base
//            Please submit a pull request there
//            https://github.com/fastlane/fastlane/blob/master/snapshot/lib/assets/SnapshotHelper.swift
// -----------------------------------------------------

import Foundation
import XCTest

var deviceLanguage = ""
var locale = ""

func setupSnapshot(_ app: XCUIApplication, waitForAnimations: Bool = true) {
    Snapshot.setupSnapshot(app, waitForAnimations: waitForAnimations)
}

func snapshot(_ name: String, waitForLoadingIndicator: Bool) {
    if waitForLoadingIndicator {
        Snapshot.snapshot(name)
    } else {
        Snapshot.snapshot(name, timeWaitingForIdle: 0)
    }
}

/// - Parameters:
///   - name: The name of the snapshot
///   - timeout: Amount of seconds to wait until the network loading indicator disappears. Pass `0` if you don't want to wait.
func snapshot(_ name: String, timeWaitingForIdle timeout: TimeInterval = 20) {
    Snapshot.snapshot(name, timeWaitingForIdle: timeout)
}

enum SnapshotError: Error, CustomDebugStringConvertible {
    case cannotFindHomeDirectory
    case cannotRunOnPhysicalDevice

    var debugDescription: String {
        switch self {
        case .cannotFindHomeDirectory:
            return "XCUITest-formatted: Couldn't find home directory"
        case .cannotRunOnPhysicalDevice:
            return "Can't use Snapshot on a physical device."
        }
    }
}

@objcMembers
open class Snapshot: NSObject {
    static var app: XCUIApplication?
    static var waitForAnimations = true
    static var cacheDirectory: URL?
    static var screenshotsDirectory: URL? {
        return cacheDirectory?.appendingPathComponent("screenshots", isDirectory: true)
    }

    open class func setupSnapshot(_ app: XCUIApplication, waitForAnimations: Bool = true) {
        Snapshot.app = app
        Snapshot.waitForAnimations = waitForAnimations

        do {
            let cacheDir = try pathPrefix()
            Snapshot.cacheDirectory = cacheDir
            setLanguage(app)
            setLocale(app)
            setLaunchArguments(app)
        } catch let error {
            NSLog(error.localizedDescription)
        }
    }

    class func setLanguage(_ app: XCUIApplication) {
        guard let cacheDirectory = cacheDirectory else {
            NSLog("CacheDirectory is not set - probably running on a physical device?")
            return
        }

        let path = cacheDirectory.appendingPathComponent("language.txt")

        do {
            let trimCharacters = CharacterSet(charactersIn: "\n\r")
            let trimmedString = try String(contentsOf: path, encoding: .utf8).trimmingCharacters(in: trimCharacters)
            deviceLanguage = trimmedString
            app.launchArguments += ["-AppleLanguages", "(\(trimmedString))"]
        } catch {
            NSLog("Couldn't detect/set language...")
        }
    }

    class func setLocale(_ app: XCUIApplication) {
        guard let cacheDirectory = cacheDirectory else {
            NSLog("CacheDirectory is not set - probably running on a physical device?")
            return
        }

        let path = cacheDirectory.appendingPathComponent("locale.txt")

        do {
            let trimCharacters = CharacterSet(charactersIn: "\n\r")
            let trimmedString = try String(contentsOf: path, encoding: .utf8).trimmingCharacters(in: trimCharacters)
            locale = trimmedString
            app.launchArguments += ["-AppleLocale", "\"\(trimmedString)\""]
        } catch {
            NSLog("Couldn't detect/set locale...")
        }
    }

    class func setLaunchArguments(_ app: XCUIApplication) {
        guard let cacheDirectory = cacheDirectory else {
            NSLog("CacheDirectory is not set - probably running on a physical device?")
            return
        }

        let path = cacheDirectory.appendingPathComponent("snapshot-launch_arguments.txt")
        app.launchArguments += ["-FASTLANE_SNAPSHOT", "YES", "-ui_testing"]

        do {
            let launchArguments = try String(contentsOf: path, encoding: String.Encoding.utf8)
            let trimmedArguments = launchArguments.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedArguments.isEmpty {
                app.launchArguments += trimmedArguments.components(separatedBy: "\n")
            }
        } catch {
            NSLog("Couldn't detect/set launch arguments...")
        }
    }

    open class func snapshot(_ name: String, timeWaitingForIdle timeout: TimeInterval = 20) {
        if timeout > 0 {
            waitForLoadingIndicatorToDisappear(within: timeout)
        }

        NSLog("snapshot: \(name)")

        if Snapshot.waitForAnimations {
            sleep(1)
        }

        #if os(OSX)
            XCUIApplication().typeKey(XCUIKeyboardKeySecondaryFn, modifierFlags: [])
        #else
            let app = Snapshot.app ?? XCUIApplication()

            // Verifying accessibility
            for _ in 1...3 {
                _ = app.statusBars.firstMatch.waitForExistence(timeout: 0.1)
            }
        #endif

        let screenshot = XCUIScreen.main.screenshot()
        guard var cacheDirectory = self.cacheDirectory else {
            NSLog("CacheDirectory is not set - probably running on a physical device?")
            return
        }
        cacheDirectory = cacheDirectory.appendingPathComponent("screenshots", isDirectory: true)
        let path = cacheDirectory.appendingPathComponent("\(name).png")
        let pngData = screenshot.pngRepresentation
        do {
            try pngData.write(to: path)
        } catch {
            NSLog("Problem writing screenshot: \(name) to \(path)")
        }
    }

    class func waitForLoadingIndicatorToDisappear(within timeout: TimeInterval) {
        #if os(tvOS)
            return
        #endif

        let networkLoadingIndicator = XCUIApplication().otherElements.deviceStatusBars.networkLoadingIndicators.element
        let networkLoadingIndicatorDisappeared = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: networkLoadingIndicator)
        _ = XCTWaiter.wait(for: [networkLoadingIndicatorDisappeared], timeout: timeout)
    }

    class func pathPrefix() throws -> URL? {
        let homeDir: URL
        // on OSX config is stored in /Users/<username>/Library
        // on iOS  config is stored in a shared directory
        #if os(OSX)
            guard let user = ProcessInfo().environment["USER"] else {
                throw SnapshotError.cannotFindHomeDirectory
            }
            homeDir = URL(fileURLWithPath: "/Users/\(user)/Library")
        #else
            #if arch(i386) || arch(x86_64) || arch(arm64)
                if let dir = ProcessInfo().environment["SIMULATOR_HOST_HOME"] {
                    homeDir = URL(fileURLWithPath: dir).appendingPathComponent("Library")
                } else if let dir = ProcessInfo().environment["SNAPSHOT_ARTIFACTS"] {
                    return URL(fileURLWithPath: dir)
                } else {
                    throw SnapshotError.cannotFindHomeDirectory
                }
            #else
                throw SnapshotError.cannotRunOnPhysicalDevice
            #endif
        #endif
        return homeDir.appendingPathComponent("Caches/tools.fastlane")
    }
}

private extension XCUIElementQuery {
    var networkLoadingIndicators: XCUIElementQuery {
        let isNetworkLoadingIndicator = NSPredicate { (evaluatedObject, _) in
            guard let element = evaluatedObject as? XCUIElementAttributes else { return false }

            return element.isNetworkLoadingIndicator
        }

        return self.containing(isNetworkLoadingIndicator)
    }

    var deviceStatusBars: XCUIElementQuery {
        let deviceWidth = UIScreen.main.bounds.width

        let isStatusBar = NSPredicate { (evaluatedObject, _) in
            guard let element = evaluatedObject as? XCUIElementAttributes else { return false }

            return element.frame.width == deviceWidth && element.frame.height <= 100
        }

        return self.containing(isStatusBar)
    }
}

private extension XCUIElementAttributes {
    var isNetworkLoadingIndicator: Bool {
        if hasWhiteListedIdentifier { return false }

        let hasOldLoadingIndicatorSize = frame.size == CGSize(width: 10, height: 20)
        let hasNewLoadingIndicatorSize = frame.size.width.rounded(.up) == 12 && frame.size.height.rounded(.up) == 12

        return hasOldLoadingIndicatorSize || hasNewLoadingIndicatorSize
    }

    var hasWhiteListedIdentifier: Bool {
        let whiteListedIdentifiers = ["GeofenceLocationTrackingOn", "StandardLocationTrackingOn"]

        return whiteListedIdentifiers.contains(identifier)
    }

    func isPartiallyAligned(withFrame frame: CGRect) -> Bool {
        let aligned = self.frame.minX == frame.minX || self.frame.maxX == frame.maxX
        return aligned
    }
}
