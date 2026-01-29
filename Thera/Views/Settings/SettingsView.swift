import SwiftUI
import FamilyControls
import DeviceActivity
import ManagedSettings

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var persistenceManager: PersistenceManager
    @EnvironmentObject var screenTimeManager: TheraScreenTimeManager
    
    @State private var isPickerPresented = false
    
    var body: some View {
        Form {
            // MARK: - SECTION 1: DISTRACTING APPS
            Section(header: Text("Distracting Apps")) {
                Button(action: { isPickerPresented = true }) {
                    HStack {
                        Text("Edit App List")
                        Spacer()
                        Text("\(screenTimeManager.distractingSelection.applicationTokens.count) selected")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // MARK: - SECTION 1.5: SUGGESTION PREFERENCE
            Section(header: Text("Suggestions"), footer: Text("Choose where you want Thera to encourage your focus.")) {
                Picker("Pause Model", selection: $persistenceManager.suggestionPreference) {
                    ForEach(SuggestionPreference.allCases, id: \.self) { pref in
                        Text(pref.rawValue).tag(pref)
                    }
                }
            }

            
            // MARK: - SECTION 2: TIME LIMITS
            Section(header: Text("Time Limits")) {
                if screenTimeManager.distractingSelection.applicationTokens.isEmpty {
                    Text("No apps selected")
                        .foregroundColor(.gray)
                } else {
                    ForEach(Array(screenTimeManager.distractingSelection.applicationTokens), id: \.self) { token in
                        SettingsAppLimitRow(token: token, limit: limitBinding(for: token))
                    }
                }
            }
            
            
            // Topics section removed as requested.
        }
        .navigationTitle("Settings")
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $screenTimeManager.distractingSelection)
        .onChange(of: screenTimeManager.distractingSelection) {
            save()
        }
        .onDisappear {
            save()
        }
    }
    
    func limitBinding(for token: ApplicationToken) -> Binding<Int> {
        return Binding(
            get: { persistenceManager.getLimit(for: token) },
            set: { 
                persistenceManager.setLimit(for: token, minutes: $0)
                // Force immediate schedule update when limit changes
                save()
            }
        )
    }
    
    // addTopic removed

    
    func save() {
        // Sync any newly selected apps to ensure they have default limits/entries
        persistenceManager.syncLimits(with: screenTimeManager.distractingSelection)
        TheraScreenTimeManager.shared.saveSelectionsAndSchedule(appLimits: persistenceManager.appLimits)
    }
}

// Helper: Bubble UI
// Helper: Limit Row
struct SettingsAppLimitRow: View {
    let token: ApplicationToken
    @Binding var limit: Int
    @State private var filter = DeviceActivityFilter()
    
    let allowedLimits = [1, 5, 10, 15, 20, 25, 30, 45, 60, 75, 90, 105, 120]
    
    var body: some View {
        HStack {
            Label(token)
                .labelStyle(.iconOnly)
            
            VStack(alignment: .leading) {
                Label(token)
                    .labelStyle(.titleOnly)
                    .font(.body)
                
                // DeviceActivityReport(.miniUsage, filter: filter) // iOS 26: miniUsage removed
                //     .frame(height: 15)
            }
            
            Spacer()
            
            Menu {
                ForEach(allowedLimits, id: \.self) { val in
                    Button("\(val) min") {
                        limit = val
                    }
                }
            } label: {
                Text("\(limit) m")
                    .foregroundColor(.blue)
            }
        }
        .onAppear {
             filter = DeviceActivityFilter(
                segment: .daily(during: Calendar.current.dateInterval(of: .day, for: Date())!),
                users: .all,
                devices: .init([.iPhone, .iPad]),
                applications: Set([token]),
                categories: Set()
            )
        }
    }
}
