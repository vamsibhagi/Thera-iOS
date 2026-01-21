import SwiftUI

struct OnboardingGoalView: View {
    @Binding var currentStep: Int
    @EnvironmentObject var persistenceManager: PersistenceManager
    @State private var selectedTime: Int? = nil // Minutes
    
    let options = [15, 30, 60, 120, 180]
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6)
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
            
            VStack(spacing: 30) {
                // NavBar placeholder
                HStack {
                    Button(action: {
                        currentStep -= 1
                    }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    Spacer()
                }
                .padding()
                
                VStack(spacing: 8) {
                    Text("Daily creation goal")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("How much time do you want to spend creating each day?")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 12) {
                    ForEach(options, id: \.self) { minutes in
                        Button(action: {
                            selectedTime = minutes
                        }) {
                            Text(formatTime(minutes))
                                .font(.headline)
                                .foregroundColor(selectedTime == minutes ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedTime == minutes ? Color.white : Color(UIColor.systemGray5))
                                .cornerRadius(30) // Pill shape
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                Button(action: {
                    if let time = selectedTime {
                        persistenceManager.setGoal(minutes: time)
                        currentStep += 1
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white) // Text is white on blue button
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTime != nil ? Color.blue : Color.gray.opacity(0.5))
                        .cornerRadius(12)
                }
                .disabled(selectedTime == nil)
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
    
    func formatTime(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }
    }
}
