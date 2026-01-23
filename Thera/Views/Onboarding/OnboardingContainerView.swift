import SwiftUI

struct OnboardingContainerView: View {
    @State private var currentStep = 1
    @EnvironmentObject var persistenceManager: PersistenceManager
    
    var body: some View {
        ZStack {
            // Background color for consistency
            Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
            
            switch currentStep {
            case 1:
                OnboardingCarouselView(currentStep: $currentStep)
            case 2:
                // Reusing existing ScreenTime View (Access)
                OnboardingScreenTimeView(currentStep: $currentStep)
            case 3:
                // Reusing existing Notification View
                OnboardingNotificationView(currentStep: $currentStep)
            case 4:
                // New: Distraction Selection
                // We'll create this next
                OnboardingDistractionSelectionView(currentStep: $currentStep)
            case 5:
                // New: Limit Setting
                OnboardingLimitSettingView(currentStep: $currentStep)
            case 6:
                // New: Task Preferences
                OnboardingTaskPreferencesView(currentStep: $currentStep)
            case 7:
                // Widget Promo (Updated logic)
                OnboardingWidgetPromoView(currentStep: $currentStep)
            default:
                EmptyView()
            }
        }
        .animation(.easeInOut, value: currentStep)
    }
}
