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
    
    private var blockedCategoryTokens: Set<ActivityCategoryToken> {
        get {
            guard let data = userDefaults?.data(forKey: "PersistentBlockedCategories"),
                  let tokens = try? JSONDecoder().decode(Set<ActivityCategoryToken>.self, from: data) else {
                return []
            }
            return tokens
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults?.set(data, forKey: "PersistentBlockedCategories")
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
        
        if userDefaults?.data(forKey: "PersistentBlockedCategories") == nil {
             // Shield.applicationCategories returns ActivityCategoryPolicy?
             if let policy = store.shield.applicationCategories {
                 switch policy {
                 case let .specific(categories, _):
                     logger.log("Bootstrapping blockedCategories with \(categories.count) cats")
                     blockedCategoryTokens = categories
                 case .all, .none:
                     // We don't use 'all' or 'none' for blocking usually, so assume empty/ignore
                     break
                 @unknown default:
                     break
                 }
             }
        }
    }
    
    private func syncShields() {
        ensureLocalState()
        
        // 1. Base = Apps/Cats that have reached their limit
        let baseApps = blockedTokens
        let baseCats = blockedCategoryTokens
        
        // 2. Exempt Apps (ProbationToken_ prefix)
        var exemptApps = Set<ApplicationToken>()
        var exemptCats = Set<ActivityCategoryToken>()
        
        // Force refresh of UserDefaults to avoid staleness
        let defaults = UserDefaults(suiteName: "group.com.thera.app")
        let dict = defaults?.dictionaryRepresentation() ?? [:]
        let allKeys = dict.keys
        
        // App Probation
        let probationKeys = allKeys.filter { $0.starts(with: "ProbationToken_") }
        for key in probationKeys {
            if let data = defaults?.data(forKey: key),
               let token = try? JSONDecoder().decode(ApplicationToken.self, from: data) {
                exemptApps.insert(token)
            }
        }
        
        // Category Probation
        let catProbationKeys = allKeys.filter { $0.starts(with: "ProbationCategoryToken_") }
        for key in catProbationKeys {
            if let data = defaults?.data(forKey: key),
               let token = try? JSONDecoder().decode(ActivityCategoryToken.self, from: data) {
                exemptCats.insert(token)
            }
        }
        
        // 3. Target = Base - Exempt
        let targetApps = baseApps.subtracting(exemptApps)
        let targetCats = baseCats.subtracting(exemptCats)
        
        // 4. Atomic-ish Update
        store.shield.applications = targetApps
        
        if targetCats.isEmpty {
            store.shield.applicationCategories = nil
        } else {
            store.shield.applicationCategories = .specific(targetCats, except: Set())
        }
        
        logger.log("Synced Shields. Apps: \(targetApps.count), Cats: \(targetCats.count)")
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
    
    private func shieldCategory(withId id: UUID) {
        guard let data = userDefaults?.data(forKey: "CategoryLimits"),
              let allLimits = try? JSONDecoder().decode([CategoryLimit].self, from: data) else { return }
        
        guard let limit = allLimits.first(where: { $0.id == id }) else { return }
        
        ensureLocalState()
        var current = blockedCategoryTokens
        current.insert(limit.token)
        blockedCategoryTokens = current
        
        syncShields()
        logger.log("Shielded category with ID: \(id)")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        logger.log("intervalDidEnd: \(activity.rawValue, privacy: .public)")
        
        // Handle Dynamic Probation (Unique IDs)
        if activity.rawValue.starts(with: "probation_") {
             // Check if it is a category or app
             if activity.rawValue.starts(with: "probation_cat_") {
                 // Category Probation
                 let probationID = activity.rawValue.replacingOccurrences(of: "probation_cat_", with: "")
                 logger.log("Probation ended for Category ID: \(probationID).")
                 
                 userDefaults?.removeObject(forKey: "ProbationCategoryToken_\(probationID)")
             } else {
                 // App Probation
                 let probationID = activity.rawValue.replacingOccurrences(of: "probation_", with: "")
                 logger.log("Probation ended for App ID: \(probationID).")
                 
                 userDefaults?.removeObject(forKey: "ProbationToken_\(probationID)")
             }
            
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
             // Handle "monitor_cat_"
             if activity.rawValue.starts(with: "monitor_cat_") {
                 let components = event.rawValue.components(separatedBy: "_")
                 // Expect: limit_cat_UUID
                 // components: ["limit", "cat", "UUID"] -> count 3
                 if components.count >= 3 {
                     let uuidString = components[2]
                     if let uuid = UUID(uuidString: uuidString) {
                         shieldCategory(withId: uuid)
                     }
                 }
             } else {
                 // Handle "monitor_"
                 let components = event.rawValue.components(separatedBy: "_")
                 // Expect: limit_UUID
                 // components: ["limit", "UUID"] -> count 2
                 if components.count == 2 {
                     let uuidString = components[1]
                     if let uuid = UUID(uuidString: uuidString) {
                         shieldApp(withId: uuid)
                     }
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

struct CategoryLimit: Codable, Identifiable {
    var id: UUID = UUID()
    let token: ActivityCategoryToken
    let dailyLimitMinutes: Int
}

extension DeviceActivityName {
    static let distractionLimits = Self("dailyDistractionLimits_V2")
    static let probation = Self("probation")
}
