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
            // 1. Configure the Probation Schedule (5 mins)
            // SYSTEM LIMITATION: DeviceActivity requires a minimum interval of 15 minutes.
            // WORKAROUND: We backdate the START time by 15 minutes.
            // Schedule: [Now - 15min] to [Now + 5min].
            // Total Duration: 20 minutes (Valid > 15).
            // Remaining Time: 5 minutes (User Goal).
            let now = Date()
            let start = Calendar.current.date(byAdding: .minute, value: -15, to: now)!
            let end = Calendar.current.date(byAdding: .minute, value: 5, to: now)!
            let schedule = DeviceActivitySchedule(
                intervalStart: Calendar.current.dateComponents([.hour, .minute], from: start),
                intervalEnd: Calendar.current.dateComponents([.hour, .minute], from: end),
                repeats: true
            )
            
            let center = DeviceActivityCenter()
            do {
                // 2. Attempt to Schedule Monitoring Failure here means we should NOT unlock.
                try center.startMonitoring(
                    .probation,
                    during: schedule
                )
                logger.log("Successfully started monitoring probation")
                
                // 3. ONLY Remove Shield if scheduling succeeded
                logger.log("Secondary button pressed. Removing shield.")
                if var currentShields = store.shield.applications {
                    currentShields.remove(application)
                    store.shield.applications = currentShields
                }
                
                completionHandler(.none) // Shield Removed, App Opens
                
            } catch {
                // 4. Handle Failure (Keep Shield)
                print("THERA_ERROR: Failed to start monitoring: \(error.localizedDescription)")
                logger.error("Failed to start monitoring probation: \(error.localizedDescription, privacy: .public)")
                
                // Fallback: Do NOT remove shield so user isn't permanently unlocked.
                // Optionally: We could allow it once, but for strict limits, we fail closed.
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

