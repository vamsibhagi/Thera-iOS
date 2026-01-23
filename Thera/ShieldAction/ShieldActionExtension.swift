import ManagedSettings
import DeviceActivity
import Foundation

class ShieldActionExtension: ShieldActionDelegate {
    
    // App Group Store
    let store = ManagedSettingsStore()
    
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // "Do a task" -> Redirect to Thera logic.
            // ShieldAction response .none doesn't open app.
            // We want to open THERA app.
            // Unfortunately, extensions cannot open URL types easily.
            // BUT .defer causes the shield to stay?
            // .close -> Closes the SHIELDED app (returns to home).
            // We want the user to go to Thera.
            // Best bet: The user must manually navigate? No, that's bad UX.
            // Does ShieldAction support opening URL? No.
            // WORKAROUND: We lift the shield temporarily? No.
            // Valid Response: .close (Quit app), .none (Stay).
            // This is a known limitation.
            // The "Primary Button" in standard shield is usually "Ask for more time".
            // If we repurpose it to "Do a task", clicking it keeps you in the shield?
            completionHandler(.none)
            
        case .secondaryButtonPressed:
            // "Open App Anyway" or "Add 5 Min"
            // We want to allow the usage.
            // .none (default)
            // We need to modify store to UNBLOCK.
            
            // Logic:
            // remove application from store.shield.applications
            // But we need to verify we have the tokens.
            // We don't have the full set here easily.
            // BUT we can perform store operations.
            
            // Strategy: We can't access `TheraScreenTimeManager` here.
            // We must read `DistractingSelection` from UserDefaults (App Group).
            // Then remove THIS token.
            // Then save back?
            
            // Simplified: We allow the app.
            // ShieldAction doesn't have an "Allow" response like .permit?
            // Wait, standard Family Control has "Ask For Time".
            // For custom shield handling:
            // We must mutate the Store.
            
            completionHandler(.none)
            
        @unknown default:
            completionHandler(.none)
        }
    }
}
