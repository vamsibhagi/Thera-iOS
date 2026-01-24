import SwiftUI

struct OnboardingWidgetPromoView: View {
    @Binding var currentStep: Int
    @EnvironmentObject var persistenceManager: PersistenceManager
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Set the widget")
                .font(.title)
                .fontWeight(.bold)
            
            Text("People who use the Thera widget are 70% more likely to keep their screen streak and do more meaningful activities.")
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
                    
                    // The Widget (V2 Design mimic)
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .frame(width: 140, height: 140) // Small widget size
                        .overlay(
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Thera")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                
                                Text("Pause.\nPick something better.")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .lineLimit(2)
                                
                                Text("• Drink water")
                                    .font(.caption)
                                    .padding(.top, 4)
                            }
                            .padding()
                        )
                        .shadow(radius: 2)
                        .padding(.top, 20)
                    
                    Spacer()
                }
            }
            .padding(.vertical)
            
            Text("The widget keeps purposeful suggestions visible at all times.\nPick a better alternative without even opening the app.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                // START V2 MONITORING
                TheraScreenTimeManager.shared.saveSelectionsAndSchedule(appLimits: persistenceManager.appLimits)
                persistenceManager.completeOnboarding()
            }) {
                Text("Complete Setup")
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
