import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings
import SwiftUI
import Combine

class TheraScreenTimeManager: ObservableObject {
    static let shared = TheraScreenTimeManager()
    
    // The selection of apps for Creation
    @Published var creationSelection = FamilyActivitySelection()
    // The selection of apps for Consumption
    @Published var consumptionSelection = FamilyActivitySelection()
    
    @Published var isAuthorized = false
    
    let center = AuthorizationCenter.shared
    
    // Managed Settings store to apply shields
    let store = ManagedSettingsStore()
    
    // Device Activity Center to schedule monitoring
    let activityCenter = DeviceActivityCenter()
    
    private init() {
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
        // AuthorizationStatus is not directly observable as a boolean property `authorized` 
        // in same way, but requestAuthorization will return if already authorized or prompt.
        // We track local state or assume needed.
        if center.authorizationStatus == .approved {
            self.isAuthorized = true
        }
    }
    
    // Logic to save the selection and schedule the activity
    func saveSelectionsAndSchedule(dailyGoalMinutes: Int) {
        // 1. Save selections to UserDefaults (encoded) so we can retrieve them for charts/widget
        // Note: FamilyActivitySelection is Codable
        // IMPORTANT: Use App Group suite so Extensions can read this data!
        if let defaults = UserDefaults(suiteName: "group.com.thera.app") {
            if let encodedCreation = try? JSONEncoder().encode(creationSelection) {
                defaults.set(encodedCreation, forKey: "CreationSelection")
            }
            if let encodedConsumption = try? JSONEncoder().encode(consumptionSelection) {
                defaults.set(encodedConsumption, forKey: "ConsumptionSelection")
            }
        }
        
        // 2. Schedule the Device Activity Monitor
        scheduleCreationMonitor(minutes: dailyGoalMinutes)
        
        // 3. Immediately Apply Shields to Consumption Apps (Logic: Locked until goal met)
        // We assume goal is NOT met initially when saving (unless it's late in day and already met)
        // For simplicity, we lock immediately. The Monitor will unlock when threshold reached.
        lockConsumptionApps()
    }
    
    func scheduleCreationMonitor(minutes: Int) {
        let eventName = DeviceActivityEvent.Name("creationGoal")
        let activityName = DeviceActivityName("dailyCreation")
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let timeLimit = DateComponents(minute: minutes)
        
        // We want to trigger when the USER uses CREATION apps for 'minutes'.
        // So the event includes the creation tokens.
        let event = DeviceActivityEvent(
            applications: creationSelection.applicationTokens,
            categories: creationSelection.categoryTokens,
            webDomains: creationSelection.webDomainTokens,
            threshold: timeLimit
        )
        
        do {
            try activityCenter.startMonitoring(
                activityName,
                during: schedule,
                events: [eventName: event]
            )
            print("Monitoring started for \(minutes) minutes of creation.")
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }
    
    func lockConsumptionApps() {
        // Apply shields to consumption apps
        // When we set these, the apps become restricted/shielded.
        store.shield.applications = consumptionSelection.applicationTokens
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(consumptionSelection.categoryTokens)
        // store.shield.webDomains = consumptionSelection.webDomainTokens // If web domains supported
    }
    
    func unlockConsumptionApps() {
        // Clear shields
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        // store.shield.webDomains = nil
    }
}
