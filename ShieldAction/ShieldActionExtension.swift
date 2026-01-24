import ManagedSettings
import DeviceActivity
import Foundation

class ShieldActionExtension: ShieldActionDelegate {
    
    // App Group Store
    let store = ManagedSettingsStore()
    
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // "I'll do it!" -> Pressed
            
            // 1. Retrieve the task ID that was suggested
            let userDefaults = UserDefaults(suiteName: "group.com.thera.app")
            if let taskID = userDefaults?.string(forKey: "lastProposedTaskID") {
                // 2. Mark it as "selected/completed" in our simple store
                // NOTE: In a real app, we'd append to a "History" array.
                // For now, we print to console (which user can see in logs) or just toggle a flag.
                print("User chose task: \(taskID)")
                
                // Let's increment a 'Score' or something simple to prove capture
                let currentScore = userDefaults?.integer(forKey: "TheraScore") ?? 0
                userDefaults?.set(currentScore + 1, forKey: "TheraScore")
            }
            
            // 3. Close the app to return home/allow focus
            completionHandler(.close)
            
        case .secondaryButtonPressed:
            // "Open App Anyway"
            // We allow the usage by removing the shield for THIS app instance.
            // This is the "nudge" bypass.
            
            if var currentShields = store.shield.applications {
                currentShields.remove(application)
                store.shield.applications = currentShields
            }
            
            // Note: In a full implementation, we would want to re-shield this app 
            // after a period of time or when the app is closed.
            // For now, this allows the user to actually enter the app as requested.
            
            completionHandler(.none)
            
        @unknown default:
            completionHandler(.none)
        }
    }
}

