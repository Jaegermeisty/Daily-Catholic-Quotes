import Foundation

/// Manages the shuffle state for common (non-liturgical) quotes
class ShuffleManager {
    private let userDefaults = UserDefaults(suiteName: "group.com.mathias.Catholic-Quotes")!
    private let shuffleStateKey = "shuffleState"
    private let lastUpdatedKey = "lastUpdatedDate"
    
    // Reference to the quotes database
    private var allQuotes: [Quote] = []
    
    init(quotes: [Quote]) {
        self.allQuotes = quotes
    }
    
    // MARK: - Get Today's Common Quote
    
    /// Get the appropriate common quote for today
    func getTodaysCommonQuote() -> Quote? {
        // Check if we need to update (new day)
        if shouldUpdateForNewDay() {
            incrementToNextQuote()
        }
        
        // Get current state
        let state = loadShuffleState()
        
        // Get the quote at current position
        guard state.currentIndex < state.shuffledOrder.count else {
            print("⚠️ Index out of bounds, resetting shuffle")
            resetShuffle()
            return getTodaysCommonQuote()
        }
        
        let quoteId = state.shuffledOrder[state.currentIndex]
        
        print("🔀 Shuffle cycle \(state.cycleNumber), position \(state.currentIndex + 1)/791, showing quote ID \(quoteId)")
        
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
        print("🔄 Shuffle reset to beginning")
    }
    
    /// Convert Date to string format for storage
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
