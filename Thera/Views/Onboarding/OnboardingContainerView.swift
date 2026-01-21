import SwiftUI

struct OnboardingContainerView: View {
    @State private var currentStep = 1
    @EnvironmentObject var persistenceManager: PersistenceManager
    
    var body: some View {
        ZStack {
            // Background is managed by individual views or global here
            // Currently simple transition
            switch currentStep {
            case 1:
                OnboardingIntroView(currentStep: $currentStep)
            case 2:
                OnboardingScreenTimeView(currentStep: $currentStep)
            case 3:
                OnboardingNotificationView(currentStep: $currentStep)
            case 4:
                OnboardingCreationAppsView(currentStep: $currentStep)
            case 5:
                OnboardingGoalView(currentStep: $currentStep)
            case 6:
                OnboardingConsumptionAppsView(currentStep: $currentStep)
            case 7:
                OnboardingWidgetPromoView(currentStep: $currentStep)
            default:
                EmptyView() // Should navigate to Home
            }
        }
        .animation(.easeInOut, value: currentStep)
    }
}
