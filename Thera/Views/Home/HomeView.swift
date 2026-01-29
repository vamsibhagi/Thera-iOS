import SwiftUI
import DeviceActivity
import FamilyControls
import ManagedSettings

struct HomeView: View {
    @EnvironmentObject var persistenceManager: PersistenceManager
    @EnvironmentObject var screenTimeManager: TheraScreenTimeManager
    @ObservedObject var suggestionManager = SuggestionManager.shared
    
    @State private var timeRange: TimeRange = .day
    
    // Filters for Report
    @State private var filter = DeviceActivityFilter(
        segment: .daily(during: Calendar.current.dateInterval(of: .day, for: Date())!)
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - SECTION 1: CONTEXTUAL SUGGESTIONS
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header / Greeting?
                        // Optional: "What context are you in?" or just show sections.
                        // Requirement: "Context-based sections shown together on one screen"
                        // Smart Sort: Orders sections based on time of day
                        
                        ForEach(SuggestionContext.smartSort(), id: \.self) { context in
                            if let suggestions = suggestionManager.contextSuggestions[context], !suggestions.isEmpty {
                                ContextSectionView(context: context, suggestions: suggestions)
                            } else {
                                // Fallback if data is missing or loading? 
                                // Ideally shouldn't happen if JSON is correct.
                                // Don't show empty section to keep UI clean.
                            }
                        }
                    }
                    .padding(.top)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // MARK: - SECTION 2: SCREEN TIME (Existing)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Screen Time")
                            .font(.title3)
                            .bold()
                            .padding(.horizontal)
                        
                        // Range Selector
                        Picker("Range", selection: $timeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .onChange(of: timeRange) { updateFilter() }
                        
                        // Report (New Chart Design)
                        DeviceActivityReport(.dailyProgress, filter: filter)
                            .frame(height: 300) // Taller for Chart
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Thera")
            .navigationBarItems(trailing: NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape")
            })
            .onAppear {
                // Refresh suggestions on every view appearance
                // Requirement: "Every time the user opens the home screen, generate a new set of bubbles"
                suggestionManager.refreshSuggestions(preference: persistenceManager.suggestionPreference)
                updateFilter()
            }
            .onChange(of: screenTimeManager.distractingSelection) {
                updateFilter()
            }
        }
    }
    
    func updateFilter() {
        let calendar = Calendar.current
        let interval: DateInterval
        switch timeRange {
        case .day: interval = calendar.dateInterval(of: .day, for: Date())!
        case .week: interval = calendar.dateInterval(of: .weekOfYear, for: Date())!
        case .month: interval = calendar.dateInterval(of: .month, for: Date())!
        }
        
        let selection = screenTimeManager.distractingSelection
        
        filter = DeviceActivityFilter(
            segment: .daily(during: interval),
            users: .all,
            devices: .init([.iPhone, .iPad]),
            applications: selection.applicationTokens,
            categories: selection.categoryTokens
        )
    }
}

enum TimeRange: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

// MARK: - Report Contexts
extension DeviceActivityReport.Context {
    static let dailyProgress = Self("DailyProgress")
    static let activityBreakdown = Self("ActivityBreakdown")
}
