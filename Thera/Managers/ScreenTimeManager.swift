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
    func saveSelectionsAndSchedule(appLimits: [AppLimit]) {
        // 1. Save selection to UserDefaults
        if let defaults = UserDefaults(suiteName: "group.com.thera.app") {
            if let encoded = try? JSONEncoder().encode(distractingSelection) {
                defaults.set(encoded, forKey: "DistractingSelection")
            }
        }
        
        // 2. Schedule Monitoring (Per-App Isolation)
        // We DO NOT call disableShields() here anymore. We let the individual monitors manage their shields.
        // This preserves the state of other apps when one is updated.
        scheduleMonitoring(appLimits: appLimits)
    }
    
    func scheduleMonitoring(appLimits: [AppLimit]) {
        logger.log("Starting Smart Schedule for \(appLimits.count) apps...")
        
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
                // We stop the specific monitor before starting it to ensure config update?
                // Or does start overwrite? Start overwrites.
                // NOTE: If we stop, we lose data? Yes.
                // So we should ideally only update if changed. To do that we need to store "Last Config".
                // Allow "Force Refresh" for now as it's better than Global Reset.
                // User said: "If user updates the limit for some app... refresh only for those apps."
                
                // TODO: specific check if limit changed.
                // For now, restarting ONLY this app's monitor impacts ONLY this app.
                // Which meets the requirement: "For the apps that aren't modified... don't refresh."
                // Wait, if I loop through ALL apps and call startMonitoring, am I resetting ALL apps?
                // YES, if startMonitoring resets usage.
                
                // CRITICAL FIX: Only update if the limit changed!
                if shouldUpdateMonitor(for: limit) {
                    logger.log("Updating monitor for app \(limit.id)...")
                    try activityCenter.startMonitoring(
                        activityName,
                        during: schedule,
                        events: [eventName: event]
                    )
                    saveMonitorState(for: limit)
                } else {
                    logger.log("Skipping update for app \(limit.id) (Unchanged)")
                }
                
            } catch {
                logger.error("Failed to start monitor for \(limit.id): \(error.localizedDescription)")
            }
        }
        
        // Clean up "Stale" monitors? (Apps removed)
        // This requires tracking active IDs and stopping the rest.
        // For MVP/Verification now, let's focus on the "Add/Update" case working correctly.
    }
    
    // MARK: - Smart Diff Helpers
    
    private func shouldUpdateMonitor(for limit: AppLimit) -> Bool {
        let defaults = UserDefaults.standard // Local state sufficient
        let key = "monitor_config_\(limit.id.uuidString)"
        let lastLimit = defaults.integer(forKey: key)
        
        // Update if:
        // 1. New (lastLimit == 0)
        // 2. Limit Changed (lastLimit != current)
        return lastLimit != limit.dailyLimitMinutes
    }
    
    private func saveMonitorState(for limit: AppLimit) {
        let defaults = UserDefaults.standard
        let key = "monitor_config_\(limit.id.uuidString)"
        defaults.set(limit.dailyLimitMinutes, forKey: key)
    }
    
    func enableShields() {
        let tokens = distractingSelection.applicationTokens
        logger.log("Enabling shields for \(tokens.count) apps")
        
        // V2/V3: Shield Distracting Apps 24/7 to enable the "Pre-Open" nudge.
        store.shield.applications = tokens
        store.shield.applicationCategories = nil
    }


    
    func disableShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }
}
