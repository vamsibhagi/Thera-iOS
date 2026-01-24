import Foundation
import FamilyControls
import ManagedSettings

// MARK: - Suggestion Logic
enum SuggestionCategory: String, Codable, CaseIterable {
    case onPhone = "on_phone"
    case offPhone = "off_phone"
}

struct TaskItem: Identifiable, Codable, Hashable {
    let id: String
    var text: String
    var emoji: String? // Added for Hero Shield UI
    var suggestionCategory: SuggestionCategory
    var activityType: String // "Health", "Learning", etc. (internal tagging)
    var url: String? // Optional deep link or web link (only for on-phone)
    var isTheraSuggested: Bool
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    
    // Helper to check if it has a link
    var hasLink: Bool {
        return suggestionCategory == .onPhone && url != nil && !url!.isEmpty
    }
}

// MARK: - User Preferences
struct Topic: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var text: String
    var isLiked: Bool // true = Like, false = Dislike
}

// MARK: - Screen Time Configuration
struct AppLimit: Codable, Hashable {
    let token: ApplicationToken
    var dailyLimitMinutes: Int
    
    // Helper to format as "1h 15m"
    var formattedLimit: String {
        let hours = dailyLimitMinutes / 60
        let minutes = dailyLimitMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// Global Config (Loaded from JSON)
struct SuggestedTaskConfig: Codable {
    let tasks: [TaskItem]
}

enum SuggestionPreference: String, Codable, CaseIterable {
    case onPhone = "On-phone suggestions"
    case offPhone = "Off-phone suggestions"
    case mix = "Mix of both"
}

