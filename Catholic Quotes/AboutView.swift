import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // cream background
            Color(red: 0.98, green: 0.96, blue: 0.92)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // top bar with close button
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .stroke(Color(red: 0.5, green: 0.5, blue: 0.5), lineWidth: 1)
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
                
                Spacer()
                
                // content
                VStack(spacing: 24) {
                    // title
                    Text("About")
                        .font(.system(size: 24, weight: .regular, design: .serif))
                        .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                    
                    // Description
                    Text("Daily Catholic Quotes displays a different quote each day, with special quotes for liturgical feast days and saint memorials.")
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                    
                    // divider line
                    Rectangle()
                        .fill(Color(red: 0.8, green: 0.8, blue: 0.8))
                        .frame(width: 200, height: 1)
                        .padding(.vertical, 8)
                    
                    // version
                    Text("Version 1.0")
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    
                    // calendar link
                    Link("Full Liturgical Calendar →",
                         destination: URL(string: "https://mycatholic.life/liturgy/liturgical-calendar/")!)
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    
                    // bug report link
                    Link(destination: URL(string: "mailto:mathiasjgerpedersen@hotmail.com?subject=Catholic%20Quotes%20App%20-%20Bug%20Report&body=Please%20describe%20the%20issue%20or%20question:%0A%0A")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.bubble")
                                .font(.system(size: 12))
                            Text("Report Bug or Request Help")
                                .font(.system(size: 14, weight: .regular, design: .serif))
                        }
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    }
                }
                
                Spacer()
                Spacer()
            }
        }
    }
}

#Preview {
    AboutView()
}
