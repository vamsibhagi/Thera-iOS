import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    private let userDefaults = UserDefaults(suiteName: "group.com.thera.app") 
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        // V3 Logic: When a limit is reached, we (re)enable the shield 
        // to show the "Limit Reached" nudge with suggestions.
        if activity == .distractionLimits {
            shieldSelectedApps()
        }
    }
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        // Re-enable "Suggestions First" nudge at the start of the interval (usually daily)
        if activity == .distractionLimits {
            shieldSelectedApps()
        }
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
    }
    
    private func shieldSelectedApps() {
        guard let data = userDefaults?.data(forKey: "DistractingSelection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return
        }
        
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = nil
    }
}


extension DeviceActivityName {
    static let distractionLimits = Self("dailyDistractionLimits")
}
