import ManagedSettings
import DeviceActivity
import Foundation

import OSLog

class ShieldActionExtension: ShieldActionDelegate {
    
    // App Group Store
    let store = ManagedSettingsStore()
    private let logger = Logger(subsystem: "com.vamsibhagi.Thera", category: "ShieldAction")
    
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // Log entry to confirm the extension is alive and receiving the tap
        logger.log("Handle action called: \(String(describing: action)) for \(String(describing: application))")

        switch action {
        case .primaryButtonPressed:
            // "I'll do it!" -> Pressed
            
            // 1. Retrieve the task ID that was suggested
            let userDefaults = UserDefaults(suiteName: "group.com.thera.app")
            if let taskID = userDefaults?.string(forKey: "lastProposedTaskID") {
                // 2. Mark it as "selected/completed" in our simple store
                logger.log("User chose task: \(taskID)")
                
                // Let's increment a 'Score' or something simple to prove capture
                let currentScore = userDefaults?.integer(forKey: "TheraScore") ?? 0
                userDefaults?.set(currentScore + 1, forKey: "TheraScore")
            }
            
            // 3. Close the app to return home/allow focus
            completionHandler(.close)
            
        case .secondaryButtonPressed:
            // "Open App Anyway"
            
            // Safe Unlock Pattern:
            // Unique ID for this probation session to prevent collisions
            let probationID = UUID().uuidString
            let activityName = DeviceActivityName("probation_\(probationID)")
            
            // 1. Configure the Probation Schedule (1 min)
            // SYSTEM LIMITATION: DeviceActivity requires a minimum interval of 15 minutes.
            // WORKAROUND: We backdate the START time by 15 minutes.
            let now = Date()
            let start = Calendar.current.date(byAdding: .minute, value: -15, to: now)!
            let end = Calendar.current.date(byAdding: .minute, value: 1, to: now)!
            
            // Using exact date components (including year/month/day) + repeats: false
            // ensures this is treated as a unique, one-off event.
            let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
            let schedule = DeviceActivitySchedule(
                intervalStart: Calendar.current.dateComponents(components, from: start),
                intervalEnd: Calendar.current.dateComponents(components, from: end),
                repeats: false
            )
            
            let center = DeviceActivityCenter()
            do {
                // 2. Attempt to Schedule
                try center.startMonitoring(
                    activityName,
                    during: schedule
                )
                logger.log("Successfully started monitoring \(activityName.rawValue)")
                
                // 3. Save Context (Token) for Restoration
                if let tokenData = try? JSONEncoder().encode(application) {
                    UserDefaults(suiteName: "group.com.thera.app")?.set(tokenData, forKey: "ProbationToken_\(probationID)")
                }
                
                // 4. Remove Shield
                logger.log("Secondary button pressed. Removing shield.")
                if var currentShields = store.shield.applications {
                    currentShields.remove(application)
                    store.shield.applications = currentShields
                }
                
                completionHandler(.none) // Shield Removed
                
            } catch {
                // 4. Handle Failure (Keep Shield)
                print("THERA_ERROR: Failed to start monitoring: \(error.localizedDescription)")
                logger.error("Failed to start monitoring probation: \(error.localizedDescription, privacy: .public)")
                
                // Fallback: Do NOT remove shield so user isn't permanently unlocked.
                completionHandler(.none) // Shield Stays
            }
            
        @unknown default:
            logger.warning("Unknown action received")
            completionHandler(.none)
        }
    }
}

extension DeviceActivityName {
    static let probation = Self("probation")
}

