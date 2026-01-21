import SwiftUI
import FamilyControls

@main
struct TheraApp: App {
    @StateObject private var screenTimeManager = TheraScreenTimeManager.shared
    @StateObject private var persistenceManager = PersistenceManager.shared
    
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
