import Foundation
import FamilyControls
import ManagedSettings

// MARK: - Suggestion Logic V3 (Redesign)

enum SuggestionContext: String, Codable, CaseIterable {
    case bed = "bed"
    case couch = "couch"
    case commuting = "commuting"
    case work = "work"
    case waiting = "waiting"
    
    var displayName: String {
        switch self {
        case .bed: return "On the bed"
        case .couch: return "On the couch"
        case .commuting: return "Commuting"
        case .work: return "At work"
        case .waiting: return "Waiting / killing time"
        }
    }
    
    // MARK: - Smart Sorting
    static func smartSort(date: Date = Date()) -> [SuggestionContext] {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let isWeekend = calendar.isDateInWeekend(date)

        switch hour {
        case 5..<9:  // 5 AM - 9 AM (Early Morning)
            return isWeekend ? [.bed, .couch, .waiting, .commuting, .work]
                             : [.bed, .commuting, .waiting, .work, .couch]
            
        case 9..<17: // 9 AM - 5 PM (Daytime)
            return isWeekend ? [.couch, .waiting, .commuting, .bed, .work]
                             : [.work, .waiting, .commuting, .couch, .bed]
            
        case 17..<19: // 5 PM - 7 PM (Transition)
            return isWeekend ? [.couch, .waiting, .commuting, .bed, .work]
                             : [.commuting, .waiting, .couch, .work, .bed]
            
        case 19..<22: // 7 PM - 10 PM (Evening)
            return [.couch, .bed, .waiting, .commuting, .work]
            
        default:      // 10 PM - 5 AM (Night)
            return [.bed, .couch, .waiting, .commuting, .work]
        }
    }
}

enum SuggestionMode: String, Codable, CaseIterable {
    case onPhone = "on_phone"
    case offPhone = "off_phone"
}

struct Suggestion: Identifiable, Codable, Hashable {
    let id: String
    let context: SuggestionContext
    let mode: SuggestionMode
    let emoji: String
    let text: String
    var tags: [String]?
    var enabled: Bool?
}

struct CustomSuggestion: Codable, Identifiable, Hashable {
    let id: UUID
    let text: String
    let emoji: String
    var isEnabled: Bool = true
}

// MARK: - Voting System
enum VoteType: String, Codable {
    case thumbsUp = "thumbs_up"
    case thumbsDown = "thumbs_down"
}

struct UserVote: Codable, Hashable {
    let userId: String // UUID string
    let suggestionId: String
    let voteType: VoteType
    let timestamp: Date
}

// MARK: - Legacy Models (Do not remove yet to avoid breaking compilation during transition)
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
struct AppLimit: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
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

struct CategoryLimit: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    let token: ActivityCategoryToken
    var dailyLimitMinutes: Int
    
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

