import Foundation

class DataManager {
    static let shared = DataManager()

    private var quotesDatabase: QuotesDatabase
    private var liturgicalCalendar: LiturgicalCalendar
    private var shuffleManager: ShuffleManager

    // Cache for today's liturgical celebration name
    private var todaysLiturgicalCelebration: String?

    private init() {
        // Load quotes database
        guard let quotesUrl = Bundle.main.url(forResource: "quotes_database", withExtension: "json"),
              let quotesData = try? Data(contentsOf: quotesUrl),
              let database = try? JSONDecoder().decode(QuotesDatabase.self, from: quotesData) else {
            
            // FALLBACK: If quotes fail to load, use hardcoded default
            print("ERROR: Failed to load quotes_database.json - using fallback quote")
            self.quotesDatabase = QuotesDatabase(
                quotes: [
                    Quote(
                        id: 0,
                        text: "You have made us for yourself, O Lord, and our hearts are restless until they rest in you.",
                        author: "St. Augustine"
                    )
                ],
                playback: PlaybackState(
                    shuffledOrder: [0],
                    currentIndex: 0,
                    cycleNumber: 1,
                    lastUpdated: ""
                )
            )
            self.liturgicalCalendar = LiturgicalCalendar(fixedDates: [:], moveableDates: [:])
            self.shuffleManager = ShuffleManager(quotes: self.quotesDatabase.quotes)
            return
        }
        self.quotesDatabase = database
        
        // Load liturgical calendar
        guard let calendarUrl = Bundle.main.url(forResource: "liturgical_calendar", withExtension: "json"),
              let calendarData = try? Data(contentsOf: calendarUrl),
              let calendar = try? JSONDecoder().decode(LiturgicalCalendar.self, from: calendarData) else {
            
            // FALLBACK: If liturgical calendar fails, continue with empty calendar
            print("ERROR: Failed to load liturgical_calendar.json - using empty calendar")
            self.liturgicalCalendar = LiturgicalCalendar(fixedDates: [:], moveableDates: [:])
            self.shuffleManager = ShuffleManager(quotes: database.quotes)
            return
        }
        self.liturgicalCalendar = calendar
        
        // Initialize shuffle manager
        self.shuffleManager = ShuffleManager(quotes: database.quotes)
    }
    
    // MARK: - Rank Hierarchy
    
    /// Returns numeric priority for liturgical ranks (higher = more important)
    private func rankPriority(_ rank: String) -> Int {
        switch rank.lowercased() {
        case "solemnity": return 5
        case "feast": return 4
        case "memorial": return 3
        case "optional memorial": return 2
        case "commemoration": return 1
        default: return 0
        }
    }
    
    // MARK: - Get Today's Quote
    
    func getTodaysQuote() -> Quote? {
        // First priority: Check if today is a liturgical day
        if let liturgicalQuote = getTodaysLiturgicalQuote() {
            return Quote(
                id: -1,  // Special ID for liturgical quotes
                text: liturgicalQuote.text,
                author: liturgicalQuote.author
            )
        }
        
        // Second priority: Get common quote from shuffle
        return shuffleManager.getTodaysCommonQuote()
    }
    
    /// Get liturgical quote for today (if any), handling conflicts by rank
    private func getTodaysLiturgicalQuote() -> LiturgicalQuote? {
        let today = Date()
        let calendar = Calendar.current
        let dateString = formatDateKey(today)
        let currentYear = calendar.component(.year, from: today)

        var celebrations: [(LiturgicalQuote, String, Int)] = [] // (quote, name, priority)

        // Check fixed dates
        if let fixedDay = liturgicalCalendar.fixedDates[dateString] {
            let quote = selectQuoteForYear(from: fixedDay.quotes, year: currentYear)
            let priority = rankPriority(fixedDay.rank)
            celebrations.append((quote, fixedDay.celebration, priority))
        }

        // Check moveable dates
        let moveableDates = EasterCalculator.calculateMoveableDates(for: currentYear)
        for (key, moveableDate) in moveableDates {
            let moveDateString = formatDateKey(moveableDate)
            if moveDateString == dateString {
                // This moveable feast is today!
                if let moveableDay = liturgicalCalendar.moveableDates[key] {
                    let quote = selectQuoteForYear(from: moveableDay.quotes, year: currentYear)
                    let priority = rankPriority(moveableDay.rank)
                    celebrations.append((quote, moveableDay.celebration, priority))
                }
            }
        }

        // If multiple celebrations on same day, choose highest rank
        if !celebrations.isEmpty {
            let highest = celebrations.max { $0.2 < $1.2 }!
            print("Today: \(highest.1) (rank priority: \(highest.2))")
            if celebrations.count > 1 {
                print("   Resolved conflict with \(celebrations.count) celebrations")
            }
            // Store the celebration name for getTodaysLiturgicalDayName() to use
            todaysLiturgicalCelebration = highest.1
            return highest.0
        }

        // No liturgical day today
        todaysLiturgicalCelebration = nil
        return nil
    }
    
    /// Select quote based on year (alternates between quotes)
    private func selectQuoteForYear(from quotes: [LiturgicalQuote], year: Int) -> LiturgicalQuote {
        guard !quotes.isEmpty else {
                print("⚠️ WARNING: No quotes available for liturgical day, using fallback")
                return LiturgicalQuote(
                    text: "Rejoice in the Lord always; again I will say, rejoice.",
                    author: "Philippians 4:4"
                )
            }
        
        if quotes.count == 1 {
            return quotes[0]
        }
        
        // Alternate based on even/odd year
        let index = year % 2 == 0 ? 0 : 1
        return quotes[min(index, quotes.count - 1)]
    }
    
    // MARK: - Get Today's Liturgical Day Name

    /// Returns the name of today's liturgical celebration if today is a special day
    /// Note: This value is set by getTodaysLiturgicalQuote() and cached
    func getTodaysLiturgicalDayName() -> String? {
        return todaysLiturgicalCelebration
    }

    // MARK: - Get Next Liturgical Day

    func getNextLiturgicalDay() -> (name: String, dateString: String)? {
        let calendar = Calendar.current
        let now = Date()
        
        // Create "today at noon" for consistent comparison
        var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        todayComponents.hour = 12
        let todayAtNoon = calendar.date(from: todayComponents)!
        
        let currentYear = calendar.component(.year, from: now)
        
        // Collect ALL upcoming liturgical days (including commemorations)
        var upcomingDays: [(date: Date, name: String, rank: String)] = []
        
        // Add fixed dates
        for (dateKey, day) in liturgicalCalendar.fixedDates {
            if let date = parseDate(fromKey: dateKey, year: currentYear) {
                if date > todayAtNoon {
                    upcomingDays.append((date, day.celebration, day.rank))
                }
            }
        }
        
        // Add moveable dates
        let moveableDates = EasterCalculator.calculateMoveableDates(for: currentYear)
        for (key, moveableDate) in moveableDates {
            if moveableDate > todayAtNoon {
                if let moveableDay = liturgicalCalendar.moveableDates[key] {
                    upcomingDays.append((moveableDate, moveableDay.celebration, moveableDay.rank))
                }
            }
        }
        
        // If we're late in the year, also check next year's dates
        if upcomingDays.isEmpty || calendar.component(.month, from: now) >= 11 {
            let nextYear = currentYear + 1
            
            // Add next year's fixed dates
            for (dateKey, day) in liturgicalCalendar.fixedDates {
                if let date = parseDate(fromKey: dateKey, year: nextYear) {
                    upcomingDays.append((date, day.celebration, day.rank))
                }
            }
            
            // Add next year's moveable dates
            let nextYearMoveableDates = EasterCalculator.calculateMoveableDates(for: nextYear)
            for (key, moveableDate) in nextYearMoveableDates {
                if let moveableDay = liturgicalCalendar.moveableDates[key] {
                    upcomingDays.append((moveableDate, moveableDay.celebration, moveableDay.rank))
                }
            }
        }
        
        // Group by date to handle conflicts
        let groupedByDate = Dictionary(grouping: upcomingDays) { formatDateKey($0.date) }
        
        // Resolve conflicts: for each date with multiple celebrations, pick highest rank
        var resolvedDays: [(date: Date, name: String, rank: String)] = []
        for (_, celebrations) in groupedByDate {
            if celebrations.count > 1 {
                // Multiple celebrations on same day - pick highest rank
                let highest = celebrations.max {
                    rankPriority($0.rank) < rankPriority($1.rank)
                }!
                resolvedDays.append(highest)
                print("Conflict on \(formatDateKey(highest.date)): chose \(highest.name) over \(celebrations.count - 1) others")
            } else {
                resolvedDays.append(celebrations[0])
            }
        }
        
        // Sort by date and get the nearest one
        guard let nextDay = resolvedDays.sorted(by: { $0.date < $1.date }).first else {
            return nil
        }
        
        // Format for display
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let dateString = formatter.string(from: nextDay.date)
        
        print("Next liturgical day: \(nextDay.name) on \(dateString) (\(nextDay.rank))")
        
        return (nextDay.name, dateString)
    }
    
    // MARK: - Helper Methods
    
    /// Format date as "MM-DD" key for dictionary lookup
    private func formatDateKey(_ date: Date) -> String {
        let calendar = Calendar.current
        let month = String(format: "%02d", calendar.component(.month, from: date))
        let day = String(format: "%02d", calendar.component(.day, from: date))
        return "\(month)-\(day)"
    }
    
    /// Parse a date key like "12-25" into a Date for the given year
    private func parseDate(fromKey key: String, year: Int) -> Date? {
        let components = key.split(separator: "-")
        guard components.count == 2,
              let month = Int(components[0]),
              let day = Int(components[1]) else {
            return nil
        }
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = 12
        
        return Calendar.current.date(from: dateComponents)
    }
}
