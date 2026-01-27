import SwiftUI

struct SuggestionBubbleView: View {
    let suggestion: Suggestion
    @ObservedObject var manager = SuggestionManager.shared
    @State private var hasVoted = false
    @State private var isVisible = true
    
    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                // Emoji
                Text(suggestion.emoji)
                    .font(.title)
                
                // Text
                Text(suggestion.text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                if !hasVoted {
                    // Vote Buttons
                    HStack(spacing: 16) {
                        Button(action: { vote(.thumbsDown) }) {
                            Image(systemName: "hand.thumbsdown")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Button(action: { vote(.thumbsUp) }) {
                            Image(systemName: "hand.thumbsup")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                } else {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
        }
    }
    
    private func vote(_ type: VoteType) {
        withAnimation {
            hasVoted = true
            manager.recordVote(suggestionId: suggestion.id, voteType: type)
            
            // If thumbs down, hide after a brief delay? Or just show checkmark?
            // User requirement: "Do not show that suggestion again"
            // For immediate feedback, if thumbs down, we explicitly hide it from view
            if type == .thumbsDown {
                isVisible = false
            }
        }
    }
}
