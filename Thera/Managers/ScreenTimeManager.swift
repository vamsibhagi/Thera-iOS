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
        
        // 2. Schedule Monitoring (Per-Limit Buckets)
        scheduleMonitoring(appLimits: appLimits)
        
        // 3. Apply Permenant "Pre-Open" Shield
        // REFINED LOGIC: Explicitly disabled per user request to only shield on LIMIT REACHED.
        // enableShields()
    }
    
    func scheduleMonitoring(appLimits: [AppLimit]) {
        let activityName = DeviceActivityName("dailyDistractionLimits")
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        // Bucketize tokens by limit (5, 10, 15... 120)
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        
        // Group tokens by minute value
        let grouped = Dictionary(grouping: appLimits) { $0.dailyLimitMinutes }
        
        for (minutes, limits) in grouped {
            let tokens = Set(limits.map { $0.token })
            // Ensure we use the exact tokens from the selection that matches these?
            // Actually, we construct the event using these tokens.
            
            let eventName = DeviceActivityEvent.Name("limit_\(minutes)")
            let threshold = DateComponents(minute: minutes)
            
            let event = DeviceActivityEvent(
                applications: tokens,
                threshold: threshold
            )
            events[eventName] = event
        }
        
        do {
            try activityCenter.startMonitoring(
                activityName,
                during: schedule,
                events: events
            )
            print("Monitoring started with \(events.count) limit buckets.")
        } catch {
            print("Failed to start monitoring: \(error)")
        }
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
