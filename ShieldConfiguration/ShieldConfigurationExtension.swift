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
        return createShield(for: application.localizedDisplayName ?? "this app")
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return createShield(for: application.localizedDisplayName ?? "this app")
    }

    private func createShield(for target: String) -> ShieldConfiguration {
        // 1. Get Smart Context
        let context = getSmartContext()
        
        // 2. Load and Filter Suggestions
        let suggestions = loadSuggestions(for: context)
        
        // 3. Pick Hero
        let hero = suggestions.randomElement() ?? Suggestion(id: "fallback", context: .bed, mode: .offPhone, emoji: "🧘", text: "Take 3 deep breaths", tags: [], enabled: true)
        
        // Save for action extension
        userDefaults?.set(hero.id, forKey: "lastProposedTaskID")
        
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: .systemBackground,
            icon: UIImage(systemName: "hand.raised.fill"),
            title: ShieldConfiguration.Label(text: "\(hero.emoji) \(hero.text)", color: .label),
            subtitle: ShieldConfiguration.Label(text: "Instead of \(target), try this \(context.displayName.lowercased()).", color: .secondaryLabel),
            primaryButtonLabel: ShieldConfiguration.Label(text: "I'll do it", color: .white),
            primaryButtonBackgroundColor: .systemBlue,
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
    
    private func loadSuggestions(for context: SuggestionContext) -> [Suggestion] {
        // 1. Load JSON
        let filename = "suggested_tasks"
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let all = try? JSONDecoder().decode([Suggestion].self, from: data) else {
            logger.error("Failed to load suggestions json")
            return []
        }
        
        // 2. Read Preference
        var modePreference: String = "mixed"
        if let data = userDefaults?.data(forKey: "SuggestionPreference"),
           let decoded = try? JSONDecoder().decode(SuggestionPreference.self, from: data) {
            // Map the enum to simple logic
            switch decoded {
            case .onPhone: modePreference = "on_phone"
            case .offPhone: modePreference = "off_phone"
            case .mix: modePreference = "mixed"
            }
        }
        
        // 3. Filter
        let filtered = all.filter { item in
            // Must match context
            if item.context != context { return false }
            
            // Must match mode (if not mixed)
            if modePreference != "mixed" {
                if item.mode.rawValue != modePreference { return false }
            }
            
            return item.enabled ?? true
        }
        
        return filtered
    }
}

