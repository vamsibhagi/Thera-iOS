import ManagedSettings
import ManagedSettingsUI
import UIKit
import FamilyControls

// MARK: - Shared Models (Duplicated for Extension Target Independence)
enum SuggestionCategory: String, Codable, CaseIterable {
    case onPhone = "on_phone"
    case offPhone = "off_phone"
}

struct TaskItem: Identifiable, Codable, Hashable {
    let id: String
    var text: String
    var emoji: String? // Added for Hero Shield UI
    var suggestionCategory: SuggestionCategory
    var activityType: String
    var url: String?
    var isTheraSuggested: Bool
    var isCompleted: Bool = false
    var createdAt: Date = Date()
}

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.vamsibhagi.Thera", category: "ShieldConfig")

// iOS Shield Configuration Provider
@objc(ShieldConfigurationExtension)
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    private let userDefaults = UserDefaults(suiteName: "group.com.thera.app") 
    
    override init() {
        super.init()
        logger.log("ShieldConfigurationExtension initialized")
    }
    
    // MARK: - API
    
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        logger.log("Creating shield for application: \(application.localizedDisplayName ?? "unknown")")
        return createShield(for: application.localizedDisplayName ?? "this app")
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        logger.log("Creating shield for application in category: \(application.localizedDisplayName ?? "unknown")")
        return createShield(for: application.localizedDisplayName ?? "this app")
    }



    
    private func createShield(for target: String) -> ShieldConfiguration {
        let tasks = loadSuggestions()
        guard let heroTask = tasks.first else {
            return ShieldConfiguration() // Fallback
        }
        
        // Save the proposed task ID so Action Extension knows what was accepted
        userDefaults?.set(heroTask.id, forKey: "lastProposedTaskID")
        
        let emoji = heroTask.emoji ?? "✨"
        
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial, // Thicker blur for focus
            backgroundColor: .systemBackground,
            icon: UIImage(systemName: "hourglass"), // System icon as anchor
            title: ShieldConfiguration.Label(text: "\(emoji) Purposeful Pause", color: .label),
            subtitle: ShieldConfiguration.Label(text: "Instead of opening \(target), why not:\n\n\(heroTask.text)\n", color: .label),
            primaryButtonLabel: ShieldConfiguration.Label(text: "I'll do it! \(emoji)", color: .white),
            primaryButtonBackgroundColor: .systemBlue,
            secondaryButtonLabel: ShieldConfiguration.Label(text: "Not now, open \(target)", color: .secondaryLabel)
        )
    }
    
    private func loadSuggestions() -> [TaskItem] {
        let fallback = [
            TaskItem(id: "f1", text: "Take 3 deep breaths", emoji: "🧘", suggestionCategory: .offPhone, activityType: "Health", url: nil, isTheraSuggested: true, isCompleted: false)
        ]
        
        guard let data = userDefaults?.data(forKey: "UserTasks"),
              let tasks = try? JSONDecoder().decode([TaskItem].self, from: data),
              !tasks.isEmpty else {
            return fallback
        }
        
        let filtered = tasks.filter { !$0.isCompleted }
        
        // Pick ONE hero task
        if let randomTask = filtered.randomElement() {
            return [randomTask]
        }
        
        return fallback // Fallback if no pending tasks
    }
}





