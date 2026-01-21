import SwiftUI
import FamilyControls

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var persistenceManager: PersistenceManager
    @EnvironmentObject var screenTimeManager: TheraScreenTimeManager
    
    @State private var tempGoal: Int = 15
    @State private var isPickerPresentedCreation = false
    @State private var isPickerPresentedConsumption = false
    
    let goalOptions = [15, 30, 60, 120, 180]
    
    var body: some View {
        Form {
            Section(header: Text("Daily Creation Goal")) {
                Picker("Goal", selection: $tempGoal) {
                    ForEach(goalOptions, id: \.self) { minutes in
                        Text(formatTime(minutes)).tag(minutes)
                    }
                }
            }
            
            Section(header: Text("Creation Apps")) {
                Button("Edit Creation Apps") {
                    isPickerPresentedCreation = true
                }
                let count = screenTimeManager.creationSelection.applicationTokens.count +
                            screenTimeManager.creationSelection.categoryTokens.count
                if count > 0 {
                    Text("\(count) apps selected")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Consumption Apps")) {
                Button("Edit Consumption Apps") {
                    isPickerPresentedConsumption = true
                }
                let count = screenTimeManager.consumptionSelection.applicationTokens.count +
                            screenTimeManager.consumptionSelection.categoryTokens.count
                if count > 0 {
                    Text("\(count) apps blocked")
                        .foregroundColor(.secondary)
                }
                
                // Show default apps text
                VStack(alignment: .leading) {
                    Text("Always blocked by default:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(AppConfig.defaultConsumptionApps.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Section {
                HStack {
                    Button("Cancel") {
                        // Reset changes if any?
                        // Here we are editing live on the managers except Goal which is temp.
                        // Ideally we should clone selection. FamilyActivitySelection is value type (struct).
                        // But binding passes reference to manager state.
                        // For MVP, we save on "Update".
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Update") {
                         // Save Goal
                        persistenceManager.setGoal(minutes: tempGoal)
                        
                        // Save Selections
                        screenTimeManager.saveSelectionsAndSchedule(dailyGoalMinutes: tempGoal)
                        
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.headline)
                }
            }
        }
        .navigationTitle("Settings")
        .familyActivityPicker(isPresented: $isPickerPresentedCreation, selection: $screenTimeManager.creationSelection)
        .familyActivityPicker(isPresented: $isPickerPresentedConsumption, selection: $screenTimeManager.consumptionSelection)
        .onAppear {
            self.tempGoal = persistenceManager.dailyGoalMinutes
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
