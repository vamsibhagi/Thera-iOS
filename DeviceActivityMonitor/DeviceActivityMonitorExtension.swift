import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

import OSLog

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    private let userDefaults = UserDefaults(suiteName: "group.com.thera.app")
    private let logger = Logger(subsystem: "com.vamsibhagi.Thera", category: "DeviceActivityMonitor")
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        logger.log("eventDidReachThreshold: \(event.rawValue)")
        
        // V3 Logic: When a limit is reached, we (re)enable the shield 
        // to show the "Limit Reached" nudge with suggestions.
        if activity == .distractionLimits {
            shieldSelectedApps()
        }
    }
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        logger.log("intervalDidStart: \(activity.rawValue)")
        
        // Re-enable "Suggestions First" nudge at the start of the interval (usually daily)
        if activity == .distractionLimits {
            shieldSelectedApps()
        }
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        logger.log("intervalDidEnd: \(activity.rawValue)")
        
        if activity == .probation {
            logger.log("Probation ended. Re-shielding apps.")
            // Probation period ended (e.g. 15 mins passed).
            // Re-apply the shield to the selected apps.
            shieldSelectedApps()
            
            // Clean up the one-time schedule
            let center = DeviceActivityCenter()
            center.stopMonitoring([DeviceActivityName.probation])
        }
    }
    
    private func shieldSelectedApps() {
        guard let data = userDefaults?.data(forKey: "DistractingSelection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            logger.error("Failed to load DistractingSelection")
            return
        }
        
        logger.log("Shielding \(selection.applicationTokens.count) apps")
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = nil
    }
}


extension DeviceActivityName {
    static let distractionLimits = Self("dailyDistractionLimits")
    static let probation = Self("probation")
}
