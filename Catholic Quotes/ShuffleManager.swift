import Foundation

/// Manages the shuffle state for common (non-liturgical) quotes
class ShuffleManager {
    private let userDefaults = UserDefaults(suiteName: "group.com.mathias.Catholic-Quotes")!
    private let shuffleStateKey = "shuffleState"
    private let lastUpdatedKey = "lastUpdatedDate"
    private let anchorDateKey = "shuffleAnchorDate"
    
    // Reference to the quotes database
    private var allQuotes: [Quote] = []
    
    init(quotes: [Quote]) {
        self.allQuotes = quotes
    }
    
    // MARK: - Get Today's Common Quote
    
    /// Get the appropriate common quote for today
    func getTodaysCommonQuote() -> Quote? {
        return getQuote(for: Date())
    }

    /// Get the appropriate common quote for a specific date (deterministic)
    func getQuote(for date: Date) -> Quote? {
        var state = loadShuffleState()

        if state.shuffledOrder.isEmpty {
            print("⚠️ Empty shuffle state, resetting shuffle")
            resetShuffle()
            state = loadShuffleState()
        }

        guard !state.shuffledOrder.isEmpty else {
            return nil
        }

        let anchorDate = loadAnchorDate(using: state)
        let index = indexForDate(date, anchorDate: anchorDate, count: state.shuffledOrder.count)
        let quoteId = state.shuffledOrder[index]

        return allQuotes.first { $0.id == quoteId }
    }
    
    // MARK: - Shuffle State Management
    
    /// Load shuffle state from storage (or create initial state)
    private func loadShuffleState() -> PlaybackState {
        // Try to load existing state
        if let savedData = userDefaults.data(forKey: shuffleStateKey),
           let state = try? JSONDecoder().decode(PlaybackState.self, from: savedData) {
            return state
        }
        
        // No saved state - create initial shuffle
        print("🆕 Creating initial shuffle state")
        let initialState = createInitialShuffle()
        saveShuffleState(initialState)
        return initialState
    }
    
    /// Save shuffle state to storage
    private func saveShuffleState(_ state: PlaybackState) {
        if let encoded = try? JSONEncoder().encode(state) {
            userDefaults.set(encoded, forKey: shuffleStateKey)
            userDefaults.set(Date(), forKey: lastUpdatedKey)
        }
    }
    
    /// Create initial shuffle from all quote IDs
    private func createInitialShuffle() -> PlaybackState {
        let allIds = allQuotes.map { $0.id }
        let shuffled = allIds.shuffled()
        
        return PlaybackState(
            shuffledOrder: shuffled,
            currentIndex: 0,
            cycleNumber: 1,
            lastUpdated: dateString(from: Date())
        )
    }
    
    /// Check if we should update for a new day
    private func shouldUpdateForNewDay() -> Bool {
        guard let lastUpdated = userDefaults.object(forKey: lastUpdatedKey) as? Date else {
            return true // Never updated before
        }
        
        let calendar = Calendar.current
        return !calendar.isDate(lastUpdated, inSameDayAs: Date())
    }
    
    /// Move to the next quote in the shuffle
    private func incrementToNextQuote() {
        var state = loadShuffleState()
        
        // Move to next position
        state.currentIndex += 1
        
        // Check if we've finished this cycle
        if state.currentIndex >= state.shuffledOrder.count {
            print("🔄 Completed cycle \(state.cycleNumber), generating new shuffle")
            
            // Generate new shuffle
            let allIds = allQuotes.map { $0.id }
            state.shuffledOrder = allIds.shuffled()
            state.currentIndex = 0
            state.cycleNumber += 1
        }
        
        // Update last updated date
        state.lastUpdated = dateString(from: Date())
        
        // Save updated state
        saveShuffleState(state)
        
        print("✅ Updated to position \(state.currentIndex + 1)/791 in cycle \(state.cycleNumber)")
    }
    
    /// Reset shuffle (for debugging or user request)
    func resetShuffle() {
        let newState = createInitialShuffle()
        saveShuffleState(newState)
        userDefaults.set(Calendar.current.startOfDay(for: Date()), forKey: anchorDateKey)
        print("🔄 Shuffle reset to beginning")
    }
    
    /// Convert Date to string format for storage
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func loadAnchorDate(using state: PlaybackState) -> Date {
        if let stored = userDefaults.object(forKey: anchorDateKey) as? Date {
            return stored
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let maxIndex = max(state.shuffledOrder.count - 1, 0)
        let safeIndex = min(max(state.currentIndex, 0), maxIndex)
        let anchor = calendar.date(byAdding: .day, value: -safeIndex, to: today) ?? today
        userDefaults.set(anchor, forKey: anchorDateKey)
        return anchor
    }

    private func indexForDate(_ date: Date, anchorDate: Date, count: Int) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: anchorDate)
        let target = calendar.startOfDay(for: date)
        let dayOffset = calendar.dateComponents([.day], from: start, to: target).day ?? 0
        return wrapIndex(dayOffset, count: count)
    }

    private func wrapIndex(_ value: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let mod = value % count
        return mod >= 0 ? mod : mod + count
    }
}
