import Foundation

extension Date {
    /// Returns the start of the day (midnight) for this date.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Returns a date range for the given number of days starting from this date.
    func dateRange(days: Int) -> ClosedRange<Date>? {
        guard let end = Calendar.current.date(byAdding: .day, value: days - 1, to: self) else {
            return nil
        }
        return self...end
    }

    /// Formats this date as a time string using the given timezone.
    func formattedTime(timezone: TimeZone = .current, format: String = "HH:mm") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = timezone
        return formatter.string(from: self)
    }

    /// Formats this date as a date string in Turkish locale.
    func formattedDate(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: self)
    }

    /// Returns the Hijri calendar month for this date.
    var hijriMonth: Int {
        Calendar(identifier: .islamicUmmAlQura).component(.month, from: self)
    }

    /// Returns whether this date is in Ramadan (Hijri month 9).
    var isInRamadan: Bool {
        hijriMonth == 9
    }
}
