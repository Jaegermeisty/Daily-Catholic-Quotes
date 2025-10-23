import Foundation

// MARK: - Common Quotes Models

/// Represents a single quote from the database
struct Quote: Codable, Identifiable {
    let id: Int
    let text: String
    let author: String
}

/// The root structure of quotes_database.json
struct QuotesDatabase: Codable {
    let quotes: [Quote]
    let playback: PlaybackState
}

/// Keeps track of shuffle state for common quotes
struct PlaybackState: Codable {
    var shuffledOrder: [Int]
    var currentIndex: Int
    var cycleNumber: Int
    var lastUpdated: String
}

// MARK: - Liturgical Calendar Models

/// Represents a quote with text and author (for liturgical days)
struct LiturgicalQuote: Codable {
    let text: String
    let author: String
}

/// Represents a fixed-date liturgical celebration (like Christmas)
struct LiturgicalDay: Codable {
    let celebration: String
    let rank: String
    let color: String
    let season: String
    let quotes: [LiturgicalQuote]
}

/// Represents a moveable liturgical celebration (like Easter)
struct MoveableLiturgicalDay: Codable {
    let easterOffset: Int
    let celebration: String
    let rank: String
    let color: String
    let season: String
    let quotes: [LiturgicalQuote]
}

/// The root structure of liturgical_calendar.json
struct LiturgicalCalendar: Codable {
    let fixedDates: [String: LiturgicalDay]
    let moveableDates: [String: MoveableLiturgicalDay]
}
