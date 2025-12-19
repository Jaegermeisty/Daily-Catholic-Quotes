import SwiftUI

struct ContentView: View {
    let quote = DataManager.shared.getTodaysQuote()
    let nextFeast = DataManager.shared.getNextLiturgicalDay()
    let todaysFeast = DataManager.shared.getTodaysLiturgicalDayName()
    @State private var showingAbout = false
    
    var body: some View {
        ZStack {
            // Cream background
            Color(red: 0.98, green: 0.96, blue: 0.92)
                .ignoresSafeArea()
            
            VStack {
                // Top bar with help button
                HStack {
                    Button(action: {
                        showingAbout = true
                    }) {
                        Text("?")
                            .font(.system(size: 16, weight: .medium, design: .serif))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .stroke(Color(red: 0.5, green: 0.5, blue: 0.5), lineWidth: 1)
                            )
                    }
                    .padding(.leading, 20)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Next feast day
                    if let feast = nextFeast {
                        HStack(spacing: 4) {
                            Text(feast.name)
                                .font(.system(size: 12, weight: .medium, design: .serif))
                                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                            Text("→")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                            Text(feast.dateString)
                                .font(.system(size: 12, weight: .medium, design: .serif))
                                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 16)
                    }
                }
                
                Spacer()
                
                // Main quote content
                VStack(spacing: 20) {
                    if let quote = quote {
                        // Quote text with dynamic sizing
                        Text(quote.text)
                            .font(.system(size: dynamicFontSize(for: quote.text), weight: .regular, design: .serif))
                            .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 30)
                        
                        // Author name
                        Text("— \(quote.author)")
                            .font(.system(size: dynamicAuthorFontSize(for: quote.text), weight: .regular, design: .serif))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                            .italic()

                        // Today's feast day indicator (if applicable)
                        if let feastDay = todaysFeast {
                            Text("✦ \(feastDay)")
                                .font(.system(size: 11, weight: .regular, design: .serif))
                                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                                .padding(.top, 6)
                        }
                    } else {
                        Text("Loading quotes...")
                            .font(.system(size: 18, weight: .regular, design: .serif))
                            .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                    }
                }
                
                Spacer()
                
                if let quote = quote {
                    ShareLink(item: formatShareText(quote: quote)) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 11))
                            Text("Share Quote")
                                .font(.system(size: 12, weight: .regular, design: .serif))
                        }
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
    
    // Calculate dynamic font size based on quote length
    private func dynamicFontSize(for text: String) -> CGFloat {
        let length = text.count
        
        switch length {
        case 0..<80:
            return 28
        case 80..<150:
            return 24
        case 150..<250:
            return 20
        case 250..<350:
            return 18
        default:
            return 16
        }
    }
    
    // Author font size scales with quote
    private func dynamicAuthorFontSize(for text: String) -> CGFloat {
        let quoteSize = dynamicFontSize(for: text)
        return quoteSize * 0.7
    }
    private func formatShareText(quote: Quote) -> String {
        return """
        "\(quote.text)"
        — \(quote.author)
        
        From Catholic Quotes
        """
    }
}

#Preview {
    ContentView()
}
