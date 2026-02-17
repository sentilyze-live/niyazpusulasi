import Foundation

extension String {
    /// Returns the localized string for this key from Localizable.xcstrings
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// Returns the localized string for this key with formatted arguments
    /// - Parameter args: Variable arguments to be formatted into the localized string
    /// - Returns: Formatted localized string
    ///
    /// Example:
    /// ```swift
    /// "days_remaining".localized(with: 5) // "5 gün kaldı" (TR) / "5 days left" (EN)
    /// ```
    func localized(with args: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: args)
    }
}
