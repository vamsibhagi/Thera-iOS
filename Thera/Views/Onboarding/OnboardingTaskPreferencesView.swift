import SwiftUI

struct OnboardingTaskPreferencesView: View {
    @Binding var currentStep: Int
    @EnvironmentObject var persistenceManager: PersistenceManager
    
    @State private var selectedPreference: SuggestionPreference = .mix
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("How do you want to pause?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                Text("Thera will suggest quick alternatives to your phone habits.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            .padding(.bottom, 40)
            
            // Preference Selection
            VStack(alignment: .leading, spacing: 16) {
                Text("Where do you want to spend your time?")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                // Vertical Buttons
                VStack(spacing: 12) {
                    PreferenceButton(
                        title: "On-phone suggestions",
                        subtitle: "Productive apps, reading, learning",
                        isSelected: selectedPreference == .onPhone,
                        action: { selectedPreference = .onPhone }
                    )
                    
                    PreferenceButton(
                        title: "Off-phone suggestions",
                        subtitle: "Stretches, breathing, quick chores",
                        isSelected: selectedPreference == .offPhone,
                        action: { selectedPreference = .offPhone }
                    )
                    
                    PreferenceButton(
                        title: "Mix of both",
                        subtitle: "A balanced variety of activities",
                        isSelected: selectedPreference == .mix,
                        action: { selectedPreference = .mix }
                    )
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Continue Button
            Button(action: {
                savePreferences()
                currentStep += 1
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
    
    func savePreferences() {
        persistenceManager.suggestionPreference = selectedPreference
    }
}

struct PreferenceButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        }
    }
}
