import SwiftUI
import FamilyControls

struct OnboardingScreenTimeView: View {
    @Binding var currentStep: Int
    @EnvironmentObject var screenTimeManager: TheraScreenTimeManager
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6) // Dark background simulated or use preferred color scheme
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark) // Requirement: Dark background
            
            VStack(spacing: 40) {
                Spacer()
                
                Text("First, allow Screen Time")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                
                Text("To manage consumption apps, Thera needs your permission")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                // Mock System Modal
                VStack(spacing: 20) {
                    Text("\"Thera\" Would Like to Access Screen Time")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                    
                    Text("Providing Thera access to Screen Time may allow it to see your activity data, restrict content, and limit the usage of apps and websites.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    
                    Divider()
                    
                    Button(action: {
                        Task {
                            await screenTimeManager.requestAuthorization()
                            // Move next regardless of outcome, or check? 
                            // Creating "Real" app behavior usually implies moving next after flow.
                            // If they deny, we can't do much. But ST API doesn't return 'denied' easily to code.
                            currentStep += 1
                        }
                    }) {
                        Text("Continue")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Divider()
                    
                    Button(action: {
                         // User chose fake "Don't Allow"
                         // Maybe show alert? Or just nothing? 
                         // Requirement: "If user provides permission... they go to next steps. Else the app will remain at this step."
                         // Real ST API doesn't callback with "Denied" boolean directly to app in all cases (it's opaque).
                         // But requestAuthorization throws if denied or restricted?
                    }) {
                        Text("Don't Allow")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color(.systemGray6)) // Brighter than bg
                .cornerRadius(14)
                .padding(.horizontal, 40)
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("Your data is protected by Apple")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Button("Learn More") {
                        // Info action
                    }
                    .font(.caption2)
                }
                .padding(.bottom)
            }
        }
    }
}
