import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        // Handle the event
        if event == .creationGoal {
            // Unlock consumption apps by clearing the shields
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            
            // Persist state to shared UserDefaults for the Widget/App to see
            // Note: Use a suitename for App Group to share data
            if let userDefaults = UserDefaults(suiteName: "group.com.thera.app") {
                userDefaults.set(true, forKey: "isDailyGoalMet")
                
                // Update streak logic here (simplified)
                let currentStreak = userDefaults.integer(forKey: "currentStreak")
                let lastCompletionDate = userDefaults.object(forKey: "lastCompletionDate") as? Date
                
                if let lastDate = lastCompletionDate, Calendar.current.isDateInYesterday(lastDate) {
                     userDefaults.set(currentStreak + 1, forKey: "currentStreak")
                } else if lastCompletionDate == nil || !Calendar.current.isDateInToday(lastCompletionDate!) {
                    // Reset streak if missed a day, or start new
                    // But if it's the same day, don't increment
                     if lastCompletionDate == nil || !Calendar.current.isDateInToday(lastCompletionDate!) {
                         if let lastDate = lastCompletionDate, !Calendar.current.isDateInYesterday(lastDate) {
                             userDefaults.set(1, forKey: "currentStreak")
                         } else {
                             // First time
                             userDefaults.set(1, forKey: "currentStreak")
                         }
                     }
                }
                userDefaults.set(Date(), forKey: "lastCompletionDate")
            }
        }
    }
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        if activity == .dailyCreation {
            // Re-lock consumption apps at the start of the day
            // We need to retrieve the blocked selection from UserDefaults
            if let userDefaults = UserDefaults(suiteName: "group.com.thera.app"),
               let data = userDefaults.data(forKey: "ConsumptionSelection"),
               let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                
                store.shield.applications = selection.applicationTokens
                store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
                
                // Reset daily state
                userDefaults.set(false, forKey: "isDailyGoalMet")
            }
        }
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Cleanup if needed
    }
}

extension DeviceActivityEvent.Name {
    static let creationGoal = Self("creationGoal")
}

extension DeviceActivityName {
    static let dailyCreation = Self("dailyCreation")
}
