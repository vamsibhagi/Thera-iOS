import SwiftUI

struct OnboardingWidgetPromoView: View {
    @Binding var currentStep: Int
    @EnvironmentObject var persistenceManager: PersistenceManager
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Set the widget")
                .font(.title) // Headline
                .fontWeight(.bold)
            
            Text("People who use the Thera widget are 70% more likely to keep their creation streak.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            // Widget Preview Illustration
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(UIColor.systemGray6))
                    .frame(width: 200, height: 400) // iPhone shape-ish
                    .shadow(radius: 10)
                
                VStack {
                     // Home Screen Grid
                    HStack(spacing: 15) {
                        RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.3)).frame(width: 50, height: 50)
                        RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.3)).frame(width: 50, height: 50)
                        RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.3)).frame(width: 50, height: 50)
                    }
                    .padding(.top, 40)
                    
                    // The Widget
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .frame(width: 140, height: 140) // Small widget size
                        .overlay(
                            VStack {
                                Text("Creation Streak")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                                Text("0") // Data placeholder
                                    .font(.system(size: 40, weight: .bold))
                                Spacer()
                                Text("Today: 0m")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                            }
                            .padding()
                        )
                        .shadow(radius: 2)
                        .padding(.top, 20)
                    
                    Spacer()
                }
            }
            .padding(.vertical)
            
            Text("The widget keeps your streak and today’s progress visible.\nThis makes creation the default.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                // "Initiates iOS widget add flow" -> Not possible programmatically.
                // We will complete onboarding here.
                // START MONITORING
                TheraScreenTimeManager.shared.saveSelectionsAndSchedule(dailyGoalMinutes: persistenceManager.dailyGoalMinutes)
                
                persistenceManager.completeOnboarding()
            }) {
                Text("Add Widget")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Text("Keep the widget on your home screen to lock in your habit.")
                .font(.caption2)
                .foregroundColor(.gray)
                .padding(.bottom, 20)
        }
        .padding()
    }
}
