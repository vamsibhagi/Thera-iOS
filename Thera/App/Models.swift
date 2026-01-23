import Foundation
import FamilyControls
import ManagedSettings

// MARK: - Task Logic
enum TaskType: String, Codable, CaseIterable {
    case light = "light"
    case focused = "focused"
}

struct TaskItem: Identifiable, Codable, Hashable {
    let id: String
    var text: String
    var type: TaskType
    var category: String // "Health", "Learning", etc.
    var url: String? // Optional deep link or web link
    var isTheraSuggested: Bool
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    
    // Helper to check if it has a link
    var hasLink: Bool {
        return url != nil && !url!.isEmpty
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

enum EffortPreference: String, Codable, CaseIterable {
    case veryLight = "Very Light"
    case mixed = "Mix of both"
    case focused = "A bit focused"
}
