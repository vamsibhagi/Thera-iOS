import SwiftUI
import DeviceActivity
import FamilyControls
import ManagedSettings

struct HomeView: View {
    @EnvironmentObject var persistenceManager: PersistenceManager
    @EnvironmentObject var screenTimeManager: TheraScreenTimeManager
    @ObservedObject var suggestionManager = SuggestionManager.shared
    
    @State private var timeRange: TimeRange = .day
    @State private var isShowingAddSheet = false
    
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
                        
                        // MARK: - MY LIST SECTION
                        MyListHeader(isShowingAddSheet: $isShowingAddSheet)
                        
                        if suggestionManager.customSuggestions.isEmpty {
                            Text("Your personal habits and ideas will appear here.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(suggestionManager.customSuggestions) { custom in
                                    // Convert to Suggestion for the bubble view
                                    let suggestion = Suggestion(id: custom.id.uuidString, context: .bed, mode: .offPhone, emoji: custom.emoji, text: custom.text, tags: [], enabled: true)
                                    SuggestionBubbleView(suggestion: suggestion, isCustom: true)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // MARK: - CONTEXTUAL SECTIONS
                        ForEach(SuggestionContext.smartSort(), id: \.self) { context in
                            if let suggestions = suggestionManager.contextSuggestions[context], !suggestions.isEmpty {
                                ContextSectionView(context: context, suggestions: suggestions)
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
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("TheraLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 32)
                }
            }
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
            .sheet(isPresented: $isShowingAddSheet) {
                AddCustomSuggestionView()
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

struct MyListHeader: View {
    @Binding var isShowingAddSheet: Bool
    
    var body: some View {
        HStack {
            Text("My List")
                .font(.title3)
                .bold()
            Spacer()
            Button(action: { isShowingAddSheet = true }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
        }
        .padding(.horizontal)
    }
}
