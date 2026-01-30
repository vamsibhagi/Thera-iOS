import ManagedSettings
import ManagedSettingsUI
import UIKit
import FamilyControls
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.vamsibhagi.Thera", category: "ShieldConfig")

// MARK: - Local Models (Fallback since Models.swift is not shared)

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
        case .waiting: return "Waiting"
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

struct CustomSuggestion: Codable, Identifiable {
    let id: UUID
    let text: String
    let emoji: String
    var isEnabled: Bool?
}

// We also need SuggestionPreference for the decoding
enum SuggestionPreference: String, Codable {
    case onPhone = "on_phone"
    case offPhone = "off_phone"
    case mix = "mixed"
}

// iOS Shield Configuration Provider

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    private let userDefaults = UserDefaults(suiteName: "group.com.thera.app") 
    
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return createShield(for: application.localizedDisplayName ?? "this app", token: .application(application))
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return createShield(for: application.localizedDisplayName ?? "this app", token: .category(category))
    }

    private enum ShieldToken {
        case application(Application)
        case category(ActivityCategory)
    }

    private func createShield(for target: String, token: ShieldToken) -> ShieldConfiguration {
        // 1. Get Smart Context
        let context = getSmartContext()
        
        // 2. Load Suggestions
        let builtIn = loadBuiltInSuggestions(for: context)
        let custom = loadCustomSuggestions()
        
        // Combine into a master pool
        // We'll put custom ones first to maintain the 70/30 feel or just mix them.
        // Let's mix them but keep custom at the front of the rotation if they exist.
        var masterPool: [Suggestion] = []
        masterPool.append(contentsOf: custom.map { Suggestion(id: $0.id.uuidString, context: .bed, mode: .offPhone, emoji: $0.emoji, text: $0.text, tags: [], enabled: true) })
        masterPool.append(contentsOf: builtIn)
        
        if masterPool.isEmpty {
            masterPool.append(fallbackHero)
        }

        // 3. Get Offset from UserDefaults
        userDefaults?.synchronize()
        let offset = userDefaults?.integer(forKey: "shieldShuffleOffset") ?? 0
        
        // 4. Pick Hero based on rotation
        // We use a base random index stored in UserDefaults so the first suggestion is random, 
        // but the 'Next' button cycles deterministically.
        var baseIdx = userDefaults?.integer(forKey: "shieldBaseIndex") ?? 0
        if baseIdx == 0 && userDefaults?.object(forKey: "shieldBaseIndex") == nil {
            baseIdx = Int.random(in: 0..<1000)
            userDefaults?.set(baseIdx, forKey: "shieldBaseIndex")
        }
        
        let heroIdx = (baseIdx + offset) % masterPool.count
        let hero = masterPool[heroIdx]
        
        // Save for action extension (if needed, but cycling handles itself)
        userDefaults?.set(hero.id, forKey: "lastProposedTaskID")
        
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: .systemBackground,
            icon: UIImage(systemName: "hand.raised.fill"),
            title: ShieldConfiguration.Label(text: "\(hero.emoji) \(hero.text)", color: .label),
            subtitle: ShieldConfiguration.Label(text: "Instead of \(target), try this.", color: .secondaryLabel),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Another idea", color: .systemBlue),
            primaryButtonBackgroundColor: .clear, // Make it look like a secondary action if we want, or keep it prominent
            secondaryButtonLabel: ShieldConfiguration.Label(text: "Unlock for 1 min", color: .secondaryLabel)
        )
    }
    
    // MARK: - Helper Logic
    
    private func getSmartContext() -> SuggestionContext {
        // Re-implementing logic here to be safe if static method isn't reachable
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let isWeekend = calendar.isDateInWeekend(Date())

        switch hour {
        case 5..<9: return isWeekend ? .bed : .commuting
        case 9..<17: return isWeekend ? .couch : .work
        case 17..<19: return isWeekend ? .couch : .commuting
        case 19..<22: return .couch // Evening
        default: return .bed // Night
        }
    }
    
    private var fallbackHero: Suggestion {
        Suggestion(id: "fallback", context: .bed, mode: .offPhone, emoji: "🧘", text: "Take 3 deep breaths", tags: [], enabled: true)
    }

    private func loadBuiltInSuggestions(for context: SuggestionContext) -> [Suggestion] {
        // 1. Load JSON
        let filename = "suggested_tasks"
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let all = try? JSONDecoder().decode([Suggestion].self, from: data) else {
            logger.error("Failed to load suggestions json")
            return []
        }
        
        return filterByPreference(all, for: context)
    }
    
    private func loadCustomSuggestions() -> [CustomSuggestion] {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.thera.app")?
            .appendingPathComponent("Library/Application Support/custom_suggestions.json") else {
            return []
        }
        
        guard let data = try? Data(contentsOf: url),
              let all = try? JSONDecoder().decode([CustomSuggestion].self, from: data) else {
            return []
        }
        
        // No more filtering by context or preference for "My List" items
        return all.filter { $0.isEnabled ?? true }
    }
    
    private func filterByPreference(_ suggestions: [Suggestion], for context: SuggestionContext) -> [Suggestion] {
        let modePreference = getModePreference()
        
        return suggestions.filter { item in
            if item.context != context { return false }
            if modePreference != "mixed" && item.mode.rawValue != modePreference { return false }
            return item.enabled ?? true
        }
    }
    

    
    private func getModePreference() -> String {
        if let data = userDefaults?.data(forKey: "SuggestionPreference"),
           let decoded = try? JSONDecoder().decode(SuggestionPreference.self, from: data) {
            switch decoded {
            case .onPhone: return "on_phone"
            case .offPhone: return "off_phone"
            case .mix: return "mixed"
            }
        }
        return "mixed"
    }
}

