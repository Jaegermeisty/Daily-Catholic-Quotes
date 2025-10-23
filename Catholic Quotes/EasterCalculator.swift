import Foundation

/// Calculates Easter Sunday and other moveable feast dates
class EasterCalculator {
    
    /// Calculate Easter Sunday for a given year using the Computus algorithm
    /// This uses the Anonymous Gregorian algorithm
    static func calculateEaster(for year: Int) -> Date {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12 // Set to noon to avoid timezone issues
        
        return Calendar.current.date(from: components)!
    }
    
    /// Calculate all moveable feast dates for a given year
    static func calculateMoveableDates(for year: Int) -> [String: Date] {
        let easter = calculateEaster(for: year)
        let calendar = Calendar.current
        
        var dates: [String: Date] = [:]
        
        // Ash Wednesday: 46 days before Easter
        dates["ashWednesday"] = calendar.date(byAdding: .day, value: -46, to: easter)!
        
        // Palm Sunday: 7 days before Easter
        dates["palmSunday"] = calendar.date(byAdding: .day, value: -7, to: easter)!
        
        // Holy Thursday: 3 days before Easter
        dates["holyThursday"] = calendar.date(byAdding: .day, value: -3, to: easter)!
        
        // Good Friday: 2 days before Easter
        dates["goodFriday"] = calendar.date(byAdding: .day, value: -2, to: easter)!
        
        // Easter Vigil: 1 day before Easter (Saturday evening)
        dates["easterVigil"] = calendar.date(byAdding: .day, value: -1, to: easter)!
        
        // Easter Sunday
        dates["easterSunday"] = easter
        
        // Divine Mercy Sunday: 7 days after Easter
        dates["divineMercySunday"] = calendar.date(byAdding: .day, value: 7, to: easter)!
        
        // Ascension: 39 days after Easter (40 days minus Easter itself)
        dates["ascension"] = calendar.date(byAdding: .day, value: 39, to: easter)!
        
        // Pentecost: 49 days after Easter
        dates["pentecost"] = calendar.date(byAdding: .day, value: 49, to: easter)!
        
        // Corpus Christi: 60 days after Easter
        dates["corpusChristi"] = calendar.date(byAdding: .day, value: 60, to: easter)!
        
        return dates
    }
    
    /// Get a moveable feast date as a formatted string "MM-DD"
    static func getMoveableDateString(feast: String, year: Int) -> String? {
        let dates = calculateMoveableDates(for: year)
        guard let date = dates[feast] else { return nil }
        
        let calendar = Calendar.current
        let month = String(format: "%02d", calendar.component(.month, from: date))
        let day = String(format: "%02d", calendar.component(.day, from: date))
        
        return "\(month)-\(day)"
    }
}
