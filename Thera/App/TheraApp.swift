import SwiftUI
import FamilyControls

@main
struct TheraApp: App {
    @StateObject private var screenTimeManager = TheraScreenTimeManager.shared
    @StateObject private var persistenceManager = PersistenceManager.shared
    
    init() {
        if ProcessInfo.processInfo.arguments.contains("-resetOnboarding") {
            UserDefaults(suiteName: "group.com.thera.app")?.removeObject(forKey: "hasCompletedOnboarding")
            UserDefaults(suiteName: "group.com.thera.app")?.removeObject(forKey: "DistractingSelection")
        }
        
        if ProcessInfo.processInfo.arguments.contains("-skipOnboarding") {
            UserDefaults(suiteName: "group.com.thera.app")?.set(true, forKey: "hasCompletedOnboarding")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if persistenceManager.hasCompletedOnboarding {
                    HomeView()
                } else {
                    OnboardingContainerView()
                }
            }
            .environmentObject(screenTimeManager)
            .environmentObject(persistenceManager)
            .onAppear {
                // Request authorization on launch if needed, or check status
                // screenTimeManager.checkAuthorizationStatus()
            }
        }
    }
}
