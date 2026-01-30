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
            // "Another idea" -> Pressed
            
            let userDefaults = UserDefaults(suiteName: "group.com.thera.app")
            
            // 1. Increment the shuffle offset
            let currentOffset = userDefaults?.integer(forKey: "shieldShuffleOffset") ?? 0
            userDefaults?.set(currentOffset + 1, forKey: "shieldShuffleOffset")
            userDefaults?.synchronize() // Force flush for extension IPC
            
            logger.log("Cycling to next suggestion. New offset: \(currentOffset + 1)")
            
            // 2. Trigger Redraw
            // The system only redraws the shield if the shield state actually changes.
            // We "poke" it by removing and immediately re-adding the application to the shield.
            if var apps = store.shield.applications {
                apps.remove(application)
                store.shield.applications = apps
                
                // Immediately put it back. This sequence forces the system to re-query 
                // the ShieldConfigurationProvider for a new config.
                apps.insert(application)
                store.shield.applications = apps
            }
            
            completionHandler(.none) // Keep shield up, content will refresh due to the poke above
            
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
    
    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        logger.log("Handle action called for CATEGORY: \(String(describing: category))")
        
        switch action {
        case .primaryButtonPressed:
            // "Another idea" -> Pressed (Category)
            
            let userDefaults = UserDefaults(suiteName: "group.com.thera.app")
            let currentOffset = userDefaults?.integer(forKey: "shieldShuffleOffset") ?? 0
            userDefaults?.set(currentOffset + 1, forKey: "shieldShuffleOffset")
            userDefaults?.synchronize()
            
            // Poke the store to refresh category shield
            if let policy = store.shield.applicationCategories {
                switch policy {
                case .specific(var categories, let exceptions):
                    categories.remove(category)
                    store.shield.applicationCategories = .specific(categories, except: exceptions)
                    
                    // Put it back
                    categories.insert(category)
                    store.shield.applicationCategories = .specific(categories, except: exceptions)
                case .all(let exceptions):
                    // Add to exceptions then remove
                    store.shield.applicationCategories = .all(except: exceptions.union([category]))
                    store.shield.applicationCategories = .all(except: exceptions)
                default:
                    break
                }
            }
            
            completionHandler(.none)
            
        case .secondaryButtonPressed:
            // "Open App Anyway"
            
            // Safe Unlock Pattern for Categories:
            let probationID = UUID().uuidString
            let activityName = DeviceActivityName("probation_cat_\(probationID)") // Distinct prefix
            
            // 1. Configure the Probation Schedule (1 min)
            // WORKAROUND: Backdate START time by 15 minutes due to system minimum.
            let now = Date()
            let start = Calendar.current.date(byAdding: .minute, value: -15, to: now)!
            let end = Calendar.current.date(byAdding: .minute, value: 1, to: now)!
            
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
                logger.log("Successfully started monitoring category probation: \(activityName.rawValue)")
                
                // 3. Save Context (Category Token) for Restoration
                if let tokenData = try? JSONEncoder().encode(category) {
                    UserDefaults(suiteName: "group.com.thera.app")?.set(tokenData, forKey: "ProbationCategoryToken_\(probationID)")
                }
                
                // 4. Remove Shield
                // Note: store.shield.applicationCategories is Policy enum. 
                // We need to fetch current, update it, and save back.
                logger.log("Secondary button pressed. Removing category shield.")
                
                if let policy = store.shield.applicationCategories {
                     switch policy {
                     case let .specific(categories, exceptions):
                         var updatedCats = categories
                         updatedCats.remove(category)
                         if updatedCats.isEmpty {
                             store.shield.applicationCategories = nil
                         } else {
                             store.shield.applicationCategories = .specific(updatedCats, except: exceptions)
                         }
                     case .all:
                         // Complex case: 'all' blocked. To unblock one, add to exceptions.
                         // store.shield.applicationCategories = .all(except: exceptions.union([category]))
                         // For now, assuming we use .specific logic mostly.
                         break
                     case .none:
                         break
                     @unknown default:
                         break
                     }
                }
                
                completionHandler(.none) // Shield Removed
                
            } catch {
                print("THERA_ERROR: Failed to start category monitoring: \(error.localizedDescription)")
                logger.error("Failed to start monitoring category probation: \(error.localizedDescription, privacy: .public)")
                completionHandler(.none) 
            }
            
        @unknown default:
            completionHandler(.none)
        }
    }
}

extension DeviceActivityName {
    static let probation = Self("probation")
}

