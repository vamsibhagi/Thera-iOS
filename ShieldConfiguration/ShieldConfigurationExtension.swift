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
    let context: SuggestionContext
    let mode: SuggestionMode
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
        return createShield(for: application.localizedDisplayName ?? "this app")
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return createShield(for: application.localizedDisplayName ?? "this app")
    }

    private func createShield(for target: String) -> ShieldConfiguration {
        // 1. Get Smart Context
        let context = getSmartContext()
        
        // 2. Load Suggestions
        let builtIn = loadBuiltInSuggestions(for: context)
        let custom = loadCustomSuggestions(for: context)
        
        // 3. 70/30 Split Pick
        let hero: Suggestion
        
        if !custom.isEmpty {
            let roll = Int.random(in: 1...100)
            if roll <= 70 {
                // Pick custom
                let choice = custom.randomElement()!
                hero = Suggestion(id: choice.id.uuidString, context: choice.context, mode: choice.mode, emoji: choice.emoji, text: choice.text, tags: [], enabled: true)
            } else if !builtIn.isEmpty {
                // Pick built-in
                hero = builtIn.randomElement()!
            } else {
                hero = custom.randomElement().map { Suggestion(id: $0.id.uuidString, context: $0.context, mode: $0.mode, emoji: $0.emoji, text: $0.text, tags: [], enabled: true) } ?? fallbackHero
            }
        } else {
            // Fallback to built-in or default
            hero = builtIn.randomElement() ?? fallbackHero
        }
        
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
    
    private func loadCustomSuggestions(for context: SuggestionContext) -> [CustomSuggestion] {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.thera.app")?
            .appendingPathComponent("Library/Application Support/custom_suggestions.json") else {
            return []
        }
        
        guard let data = try? Data(contentsOf: url),
              let all = try? JSONDecoder().decode([CustomSuggestion].self, from: data) else {
            return []
        }
        
        // Filter by context and preference
        return filterCustomByPreference(all, for: context)
    }
    
    private func filterByPreference(_ suggestions: [Suggestion], for context: SuggestionContext) -> [Suggestion] {
        let modePreference = getModePreference()
        
        return suggestions.filter { item in
            if item.context != context { return false }
            if modePreference != "mixed" && item.mode.rawValue != modePreference { return false }
            return item.enabled ?? true
        }
    }
    
    private func filterCustomByPreference(_ suggestions: [CustomSuggestion], for context: SuggestionContext) -> [CustomSuggestion] {
        let modePreference = getModePreference()
        
        return suggestions.filter { item in
            if item.context != context { return false }
            if modePreference != "mixed" && item.mode.rawValue != modePreference { return false }
            return item.isEnabled ?? true
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

