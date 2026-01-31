import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings
import SwiftUI
import Combine
import OSLog

private let logger = Logger(subsystem: "com.vamsibhagi.Thera", category: "ScreenTimeManager")

class TheraScreenTimeManager: ObservableObject {
    static let shared = TheraScreenTimeManager()
    
    // The selection of apps for Distraction (V2)
    @Published var distractingSelection = FamilyActivitySelection()
    @Published var isAuthorized = false
    
    let center = AuthorizationCenter.shared
    let store = ManagedSettingsStore()
    let activityCenter = DeviceActivityCenter()
    
    private init() {
        // Load saved selection from App Group
        if let defaults = UserDefaults(suiteName: "group.com.thera.app"),
           let data = defaults.data(forKey: "DistractingSelection"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            self.distractingSelection = selection
        }
        
        Task {
            await checkAuthorization()
        }
    }

    
    @MainActor
    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            self.isAuthorized = true
        } catch {
            print("Failed to authorize: \(error)")
            self.isAuthorized = false
        }
    }
    
    @MainActor
    func checkAuthorization() async {
        if center.authorizationStatus == .approved {
            self.isAuthorized = true
        }
    }
    
    // Logic to save the selection and schedule the V2 activity
    func saveSelectionsAndSchedule(appLimits: [AppLimit], categoryLimits: [CategoryLimit]) {
        // 1. Save selection to UserDefaults
        if let defaults = UserDefaults(suiteName: "group.com.thera.app") {
            if let encoded = try? JSONEncoder().encode(distractingSelection) {
                defaults.set(encoded, forKey: "DistractingSelection")
            }
        }
        
        // 2. Schedule Monitoring (Per-App Isolation)
        // We DO NOT call disableShields() here anymore. We let the individual monitors manage their shields.
        // This preserves the state of other apps when one is updated.
        scheduleMonitoring(appLimits: appLimits, categoryLimits: categoryLimits)
    }
    
    func scheduleMonitoring(appLimits: [AppLimit], categoryLimits: [CategoryLimit]) {
        logger.log("Starting Smart Schedule for \(appLimits.count) apps and \(categoryLimits.count) categories...")
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        for limit in appLimits {
            // Unique Name per App Limit Configuration
            // We use the UUID to ensure stability.
            let activityNameStr = "monitor_\(limit.id.uuidString)"
            let activityName = DeviceActivityName(activityNameStr)
            
            // Check if this activity is already running?
            // "Smart Diff": In reality, we just overwrite the schedule.
            // If the schedule parameters are identical, iOS *should* carry over the state without resetting.
            // However, to be extra safe and avoid side-effects, we could check if it exists.
            // But for V1 of this fix, let's trust that calling startMonitoring on an EXISTING activity 
            // with the SAME parameters is non-destructive (or at least less destructive than stopping all).
            // Actually, we WANT to restart it if the limit CHANGED.
            // But if we just blindly start, it might reset.
            
            // Let's create the event for this specific app
            let eventName = DeviceActivityEvent.Name("limit_\(limit.id.uuidString)")
            let threshold = DateComponents(minute: limit.dailyLimitMinutes)
            
            let event = DeviceActivityEvent(
                applications: Set([limit.token]),
                threshold: threshold
            )
            
            do {
                // Smart Update:
                // We only restart the monitor if the limit has changed.
                // Restarting a DeviceActivityMonitor resets its accumulated usage for the day,
                // so we must avoid it unless necessary.
                
                if shouldUpdateMonitor(id: limit.id, limit: limit.dailyLimitMinutes) {
                    logger.log("Updating monitor for app \(limit.id)...")
                    
                    // Unshield immediately when limit changes
                    // This creates a "fresh start" feeling or at least unblocks if they increased the limit.
                    if var currentShields = store.shield.applications {
                         currentShields.remove(limit.token)
                         store.shield.applications = currentShields
                    }
                    
                    // Update persistent state to reflect unshielding
                    removeBlockedToken(limit.token)
                    
                    try activityCenter.startMonitoring(
                        activityName,
                        during: schedule,
                        events: [eventName: event]
                    )
                    saveMonitorState(id: limit.id, limit: limit.dailyLimitMinutes)
                } else {
                    logger.log("Skipping update for app \(limit.id) (Unchanged)")
                }
                
            } catch {
                logger.error("Failed to start monitor for \(limit.id): \(error.localizedDescription)")
            }
        }
        
        // B. Category Limits
        for limit in categoryLimits {
            let activityNameStr = "monitor_cat_\(limit.id.uuidString)"
            let activityName = DeviceActivityName(activityNameStr)
            
            let eventName = DeviceActivityEvent.Name("limit_cat_\(limit.id.uuidString)")
            let threshold = DateComponents(minute: limit.dailyLimitMinutes)
            
            // Categories logic
            let event = DeviceActivityEvent(
                applications: [],
                categories: Set([limit.token]),
                webDomains: [],
                threshold: threshold
            )
            
            do {
                if shouldUpdateMonitor(id: limit.id, limit: limit.dailyLimitMinutes) {
                    logger.log("Updating monitor for category \(limit.id)...")
                    try activityCenter.startMonitoring(
                        activityName,
                        during: schedule,
                        events: [eventName: event]
                    )
                    saveMonitorState(id: limit.id, limit: limit.dailyLimitMinutes)
                }
            } catch {
                logger.error("Failed to start monitor for category \(limit.id): \(error.localizedDescription)")
            }
        }
        
        // 3. Clean up "Stale" monitors (Apps removed)
        cleanUp(validAppLimits: appLimits, validCategoryLimits: categoryLimits)
    }
    
    private func cleanUp(validAppLimits: [AppLimit], validCategoryLimits: [CategoryLimit]) {
        let validAppIDs = Set(validAppLimits.map { $0.id.uuidString })
        let validCatIDs = Set(validCategoryLimits.map { $0.id.uuidString })
        let validIDs = validAppIDs.union(validCatIDs)
        
        let defaults = UserDefaults.standard
        
        // A. Stop Stale Monitors (Apps & Categories)
        let allKeys = defaults.dictionaryRepresentation().keys
        let configKeys = allKeys.filter { $0.starts(with: "monitor_config_") }
        
        var staleActivities: [DeviceActivityName] = []
        
        for key in configKeys {
             // key format: monitor_config_UUID
             let uuidString = key.replacingOccurrences(of: "monitor_config_", with: "")
             if !validIDs.contains(uuidString) {
                 // We don't know if the stale monitor was named "monitor_UUID" or "monitor_cat_UUID".
                 // Try stopping both variants to be safe.
                 staleActivities.append(DeviceActivityName("monitor_\(uuidString)"))
                 staleActivities.append(DeviceActivityName("monitor_cat_\(uuidString)"))
                 
                 // Remove config
                 defaults.removeObject(forKey: key)
             }
        }
        
        if !staleActivities.isEmpty {
            logger.log("Stopping \(staleActivities.count) stale monitors...")
            activityCenter.stopMonitoring(staleActivities)
        }
        
        // B. Update Blocked Tokens (Source of Truth for Shields)
        cleanUpBlockedApps(validAppLimits: validAppLimits)
        cleanUpBlockedCategories(validCategoryLimits: validCategoryLimits)
    }
    
    private func cleanUpBlockedApps(validAppLimits: [AppLimit]) {
        if let groupDefaults = UserDefaults(suiteName: "group.com.thera.app"),
           let data = groupDefaults.data(forKey: "PersistentBlockedTokens"),
           var blockedTokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: data) {
            
            let originalCount = blockedTokens.count
            let validTokens = validAppLimits.map { $0.token }
            
            blockedTokens = blockedTokens.filter { blockedToken in
                validTokens.contains(blockedToken)
            }
            
            if blockedTokens.count != originalCount {
                logger.log("Cleanup: Removed stale tokens from BlockedApps.")
                if let newData = try? JSONEncoder().encode(blockedTokens) {
                    groupDefaults.set(newData, forKey: "PersistentBlockedTokens")
                }
                
                // Force Update Shields (App Only)
                // Note: Simplified logic ignoring probation for now during cleanup phase to avoid complexity.
                store.shield.applications = blockedTokens
            }
        }
    }
    
    private func removeBlockedToken(_ token: ApplicationToken) {
        if let groupDefaults = UserDefaults(suiteName: "group.com.thera.app"),
           let data = groupDefaults.data(forKey: "PersistentBlockedTokens"),
           var blockedTokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: data) {
            
            if blockedTokens.contains(token) {
                blockedTokens.remove(token)
                if let newData = try? JSONEncoder().encode(blockedTokens) {
                    groupDefaults.set(newData, forKey: "PersistentBlockedTokens")
                }
            }
        }
    }
    
    private func cleanUpBlockedCategories(validCategoryLimits: [CategoryLimit]) {
        // Since we don't persist blocked categories yet, we ensure store is cleaned if no categories are monitored.
        if validCategoryLimits.isEmpty {
            store.shield.applicationCategories = nil
        }
    }
    
    // MARK: - Smart Diff Helpers
    
    private func shouldUpdateMonitor(id: UUID, limit: Int) -> Bool {
        let defaults = UserDefaults.standard // Local state sufficient
        let key = "monitor_config_\(id.uuidString)"
        let lastLimit = defaults.integer(forKey: key)
        
        // Update if:
        // 1. New (lastLimit == 0)
        // 2. Limit Changed (lastLimit != current)
        return lastLimit != limit
    }
    
    private func saveMonitorState(id: UUID, limit: Int) {
        let defaults = UserDefaults.standard
        let key = "monitor_config_\(id.uuidString)"
        defaults.set(limit, forKey: key)
    }
    
}
