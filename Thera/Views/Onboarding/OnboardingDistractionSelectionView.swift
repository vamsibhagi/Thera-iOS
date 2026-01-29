import SwiftUI
import FamilyControls

struct OnboardingDistractionSelectionView: View {
    @Binding var currentStep: Int
    @EnvironmentObject var screenTimeManager: TheraScreenTimeManager
    @State private var isPickerPresented = false
    @State private var showAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Text("Select annoying apps")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                Text("Select the apps you feel are distracting.\nDefinitely select apps where you endlessly scroll.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            .padding(.bottom, 30)
            
            // Selection Status / Trigger
            List {
                Section {
                    Button(action: {
                        isPickerPresented = true
                    }) {
                        HStack {
                            Text("Open App List")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                } footer: {
                    Text("We use Apple's secure picker. We can't see your apps until you select them.")
                }
                
                // Show count of selected items
                if !screenTimeManager.distractingSelection.applicationTokens.isEmpty || !screenTimeManager.distractingSelection.categoryTokens.isEmpty {
                    Section(header: Text("Selected")) {
                        HStack {
                            Text("Apps Selected")
                            Spacer()
                            Text("\(screenTimeManager.distractingSelection.applicationTokens.count)")
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Categories Selected")
                            Spacer()
                            Text("\(screenTimeManager.distractingSelection.categoryTokens.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            
            Spacer()
            
            // Footer Action
            Button(action: {
                if validateSelection() {
                    currentStep += 1
                } else {
                    showAlert = true
                }
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isSelectionEmpty ? Color.gray.opacity(0.5) : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(isSelectionEmpty && !ProcessInfo.processInfo.arguments.contains("-resetOnboarding"))
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $screenTimeManager.distractingSelection)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Selection Required"),
                message: Text("Please select at least one distracting app to continue."),
                dismissButton: .default(Text("OK"))
            )
        }
        // Auto-present picker on first load for smoother experience? 
        // Maybe better to let user click button so they understand context.
    }
    
    var isSelectionEmpty: Bool {
        return screenTimeManager.distractingSelection.applicationTokens.isEmpty &&
               screenTimeManager.distractingSelection.categoryTokens.isEmpty
    }
    
    func validateSelection() -> Bool {
        if ProcessInfo.processInfo.arguments.contains("-resetOnboarding") { return true }
        return !isSelectionEmpty
    }
}
