import SwiftUI

struct ContextSectionView: View {
    let context: SuggestionContext
    let suggestions: [Suggestion]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text(context.displayName)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Bubbles Grid/Stack
            // Using VStack as they likely take up full width.
            // Requirement: "Display exactly 4 suggestions bubbles"
            // If we have less than 4 (due to filtering error), it will just show what we have.
            
            VStack(spacing: 8) {
                ForEach(suggestions) { suggestion in
                    SuggestionBubbleView(suggestion: suggestion)
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 16)
    }
}
