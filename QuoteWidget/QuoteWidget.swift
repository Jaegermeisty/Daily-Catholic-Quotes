import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote?
}

// MARK: - Timeline Provider

struct QuoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), quote: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        let entry = QuoteEntry(date: Date(), quote: DataManager.shared.getTodaysQuote())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        
        // Calculate midnight tonight (start of next day)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let midnightTonight = calendar.startOfDay(for: tomorrow)
        
        let currentQuote = DataManager.shared.getTodaysQuote()
        let entry = QuoteEntry(date: now, quote: currentQuote)
        
        // Tell iOS to refresh at midnight
        let timeline = Timeline(entries: [entry], policy: .after(midnightTonight))
        completion(timeline)
    }
}

// MARK: - Widget View

struct QuoteWidgetView: View {
    let entry: QuoteEntry
    
    var body: some View {
        ZStack {
            if let quote = entry.quote {
                VStack {
                    Spacer()
                    
                    // Quote text centered
                    Text(quote.text)
                        .font(.system(size: dynamicFontSize(for: quote.text), weight: .regular, design: .serif))
                        .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                        .multilineTextAlignment(.center)
                        .lineSpacing(1)
                        .padding(.horizontal, 10)
                        .padding(.top, 6)

                    Spacer()

                    // Author name bottom right
                    HStack {
                        Spacer()
                        Text("— \(quote.author)")
                            .font(.system(size: dynamicAuthorFontSize(for: quote.text), weight: .regular, design: .serif))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                            .italic()
                            .padding(.trailing, 10)
                            .padding(.bottom, 6)
                    }
                }
            } else {
                // FALLBACK: Show error state instead of just "Loading..."
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    
                    Text("Unable to load quote")
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    
                    Text("Open the app to refresh")
                        .font(.system(size: 10, design: .serif))
                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                }
                .multilineTextAlignment(.center)
                .padding()
            }
        }
        .containerBackground(Color(red: 0.98, green: 0.96, blue: 0.92), for: .widget)
    }
    
    // Dynamic font sizing for widget
    private func dynamicFontSize(for text: String) -> CGFloat {
        let length = text.count
        
        switch length {
        case 0..<80:
            return 18  // Short quotes
        case 80..<150:
            return 16  // Medium quotes
        case 150..<250:
            return 14  // Long quotes
        default:
            return 12  // Very long quotes
        }
    }
    
    private func dynamicAuthorFontSize(for text: String) -> CGFloat {
        let quoteSize = dynamicFontSize(for: text)
        return quoteSize * 0.7  // Author is 70% of quote size
    }
}

// MARK: - Widget Configuration

@main
struct QuoteWidget: Widget {
    let kind: String = "QuoteWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            QuoteWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Catholic Quote")
        .description("Displays a daily Catholic quote")
        .supportedFamilies([.systemMedium])  // Only medium size
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    QuoteWidget()
} timeline: {
    QuoteEntry(date: Date(), quote: Quote(id: 1, text: "Be who God meant you to be and you will set the world on fire.", author: "St. Catherine of Siena"))
}
