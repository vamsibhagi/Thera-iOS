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
    
    // MARK: - Stable Shield Management
    // We maintain a separate list of "Blocked Apps" (Limit Reached) to survive race conditions
    // during concurrent probation storage updates.
    private var blockedTokens: Set<ApplicationToken> {
        get {
            guard let data = userDefaults?.data(forKey: "PersistentBlockedTokens"),
                  let tokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: data) else {
                return []
            }
            return tokens
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults?.set(data, forKey: "PersistentBlockedTokens")
            }
        }
    }
    
    // Bootstraps local state from current store if needed (Migration)
    private func ensureLocalState() {
        if userDefaults?.data(forKey: "PersistentBlockedTokens") == nil {
            let current = store.shield.applications ?? []
            logger.log("Bootstrapping blockedTokens with \(current.count) apps")
            blockedTokens = current
        }
    }
    
    private func syncShields() {
        ensureLocalState()
        
        // 1. Base = Apps that have reached their limit
        let base = blockedTokens
        
        // 2. Exempt = Apps currently on probation (ProbationToken_ prefix)
        var exempt = Set<ApplicationToken>()
        let dict = userDefaults?.dictionaryRepresentation() ?? [:]
        let allKeys = dict.keys
        let probationKeys = allKeys.filter { $0.starts(with: "ProbationToken_") }
        
        for key in probationKeys {
            if let data = userDefaults?.data(forKey: key),
               let token = try? JSONDecoder().decode(ApplicationToken.self, from: data) {
                exempt.insert(token)
            }
        }
        
        // 3. Target = Base - Exempt
        let target = base.subtracting(exempt)
        
        // 4. Atomic-ish Update
        store.shield.applications = target
        store.shield.applicationCategories = nil
        
        logger.log("Synced Shields. Blocked: \(base.count), Probation: \(exempt.count), ACTIVE: \(target.count)")
    }
    
    private func shieldApp(withId id: UUID) {
        // Load AppLimits Mapping
        guard let data = userDefaults?.data(forKey: "AppLimits"),
              let allLimits = try? JSONDecoder().decode([AppLimit].self, from: data) else { return }
        
        // Find specific token
        guard let limit = allLimits.first(where: { $0.id == id }) else { return }
        
        // Update State
        ensureLocalState()
        var current = blockedTokens
        current.insert(limit.token)
        blockedTokens = current
        
        // Apply
        syncShields()
        logger.log("Shielded app with ID: \(id)")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        logger.log("intervalDidEnd: \(activity.rawValue, privacy: .public)")
        
        // Handle Dynamic Probation (Unique IDs)
        if activity.rawValue.starts(with: "probation_") {
             let probationID = activity.rawValue.replacingOccurrences(of: "probation_", with: "")
             logger.log("Probation ended for ID: \(probationID).")
            
            // 1. Cleanup Persistence (Remove Exemption)
            userDefaults?.removeObject(forKey: "ProbationToken_\(probationID)")
            
            // 2. Sync Shields (Will re-apply shield if in blockedTokens)
            syncShields()
            
            // 3. Stop the temporary schedule
            let center = DeviceActivityCenter()
            center.stopMonitoring([activity])
        }
        else if activity == .probation {
             let center = DeviceActivityCenter()
             center.stopMonitoring([.probation])
        }
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        logger.log("🔥 eventDidReachThreshold: \(event.rawValue, privacy: .public)")
        
        if activity.rawValue.starts(with: "monitor_") {
             let components = event.rawValue.components(separatedBy: "_")
             if components.count == 2 {
                 let uuidString = components[1]
                 if let uuid = UUID(uuidString: uuidString) {
                     shieldApp(withId: uuid)
                 }
             }
        }
    }
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        logger.log("intervalDidStart: \(activity.rawValue, privacy: .public)")
        
        if activity.rawValue.starts(with: "monitor_") || activity == .distractionLimits {
            let components = Calendar.current.dateComponents([.hour], from: Date())
            if let hour = components.hour, hour == 0 {
                // Midnight Reset
                blockedTokens = [] // Clear state
                syncShields()      // Apply (clears store)
                logger.log("Midnight: Cleared all shields.")
            }
        }
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
