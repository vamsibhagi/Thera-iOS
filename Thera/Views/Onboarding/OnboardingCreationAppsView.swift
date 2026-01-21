import SwiftUI
import FamilyControls

struct OnboardingCreationAppsView: View {
    @Binding var currentStep: Int
    @EnvironmentObject var screenTimeManager: TheraScreenTimeManager
    @EnvironmentObject var persistenceManager: PersistenceManager
    @State private var isPickerPresented = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                VStack(spacing: 12) {
                    Text("Select creation apps")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Creation means doing something, not just consuming.\nWriting, learning, coding, designing, practicing, or building.\nPick the apps you use to create real value.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Text("Some apps are not meant for creation and can't be selected here.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top)
                
                List {
                    // Section 1: Installed Apps (via Picker)
                    Section {
                        Button(action: {
                            isPickerPresented = true
                        }) {
                            HStack {
                                Text("Select Installed Apps")
                                    .fontWeight(.medium)
                                Spacer()
                                // We can show a count if we have tokens, but opaque.
                                // FamilyActivitySelection has properties.
                                let count = screenTimeManager.creationSelection.applicationTokens.count +
                                            screenTimeManager.creationSelection.categoryTokens.count
                                if count > 0 {
                                    Text("\(count) selected")
                                        .foregroundColor(.secondary)
                                }
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    } header: {
                        Text("Installed Apps")
                    } footer: {
                        Text("Opens the system app picker to select your creation apps securely.")
                    }
                    
                    // Section 2: Recommendations
                    Section(header: Text("Need ideas for creation apps?")) {
                        ForEach(AppConfig.recommendedCreationApps) { app in
                            HStack {
                                Text(app.name) // In real app, fetch icon via URL or bundle
                                Spacer()
                                Text(app.category)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Button("Get") {
                                    if let url = URL(string: "https://apps.apple.com/app/id\(app.storeId)") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .font(.caption)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
                // Sticky Footer Button
                VStack {
                    Button(action: {
                        currentStep += 1
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue) // Or brand color
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .background(Color(.systemBackground))
            }
            .navigationBarHidden(true)
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $screenTimeManager.creationSelection)
        }
    }
}
