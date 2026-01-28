import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

import OSLog

class TheraMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    private let userDefaults = UserDefaults(suiteName: "group.com.thera.app")
    private let logger = Logger(subsystem: "com.vamsibhagi.Thera", category: "DeviceActivityMonitor")
    
    override init() {
        super.init()
        logger.log("🚀 TheraMonitorExtension instantiated!")
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        logger.log("🔥 eventDidReachThreshold: \(event.rawValue, privacy: .public)")
        
        if activity.rawValue.starts(with: "monitor_") {
             // Extract UUID? Actually we passed ID in event Name too: "limit_<UUID>"
             let components = event.rawValue.components(separatedBy: "_")
             if components.count == 2 {
                 // Format: limit_UUIDString
                 let uuidString = components[1]
                 if let uuid = UUID(uuidString: uuidString) {
                     logger.log("Limit reached for app ID: \(uuid). Shielding...")
                     shieldApp(withId: uuid)
                 }
             }
        }
    }
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        logger.log("intervalDidStart: \(activity.rawValue, privacy: .public)")
        
        // Check for our per-app monitors (monitor_UUID) OR the old legacy one just in case
        if activity.rawValue.starts(with: "monitor_") || activity == .distractionLimits {
            // Start of day (Midnight): Clear all shields
            // We check the hour to avoid verifying shields if the extension restarts mid-day (e.g. user update)
            let components = Calendar.current.dateComponents([.hour], from: Date())
            if let hour = components.hour, hour == 0 {
                store.shield.applications = nil
                store.shield.applicationCategories = nil
                logger.log("Midnight: Cleared all shields.")
            }
        }
    }
    
    // ...
    
    private func shieldApp(withId id: UUID) {
        // Load AppLimits Mapping
        guard let data = userDefaults?.data(forKey: "AppLimits"),
              let allLimits = try? JSONDecoder().decode([AppLimit].self, from: data) else { return }
        
        // Find specific token
        guard let limit = allLimits.first(where: { $0.id == id }) else { return }
        
        var currentShields = store.shield.applications ?? Set<ApplicationToken>()
        currentShields.insert(limit.token)
        store.shield.applications = currentShields
        store.shield.applicationCategories = nil 
        
        logger.log("Shielded app with ID: \(id)")
    }
    
    private func shieldSelectedApps() {
        // Fallback or Probation End
        guard let data = userDefaults?.data(forKey: "DistractingSelection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else { return }
        
        store.shield.applications = selection.applicationTokens
    }
}


// Helper for decoding
struct AppLimit: Codable, Identifiable {
    var id: UUID = UUID()
    let token: ApplicationToken
    let dailyLimitMinutes: Int
}

extension DeviceActivityName {
    static let distractionLimits = Self("dailyDistractionLimits_V2")
    static let probation = Self("probation")
}
