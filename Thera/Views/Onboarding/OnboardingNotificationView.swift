import SwiftUI

struct OnboardingNotificationView: View {
    @Binding var currentStep: Int
    @StateObject var notificationManager = NotificationManager.shared
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6)
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
            
            VStack(spacing: 40) {
                Spacer()
                
                Text("Allow notifications")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                
                Text("Thera uses notifications to help you stay on track with your daily creation goals")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                // Mock System Modal
                VStack(spacing: 20) {
                    Text("\"Thera\" Would Like to Send You Notifications")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                    
                    Text("Notifications may include reminders to complete your creation goal, updates when apps unlock, and helpful nudges to stay focused.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    
                    Divider()
                    
                    Button(action: {
                        Task {
                            await notificationManager.requestAuthorization()
                            currentStep += 1
                        }
                    }) {
                        Text("Allow")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Divider()
                    
                    Button(action: {
                        // Fake Don't Allow logic
                        // Depending on "User must see an option at the bottom... to skip"
                    }) {
                        Text("Don't Allow")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(14)
                .padding(.horizontal, 40)
                
                Button("Skip") {
                    currentStep += 1
                }
                .foregroundColor(.gray)
                .padding(.top)
                
                Spacer()
                
                Text("You can change this anytime in Settings")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.bottom)
            }
        }
    }
}
