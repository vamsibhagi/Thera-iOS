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
    
    // Filter for 14-day comparison (Report extension handles the split)
    var comparisonFilter: DeviceActivityFilter {
        let now = Date()
        let interval = DateInterval(start: Calendar.current.date(byAdding: .day, value: -14, to: now)!, end: now)
        return DeviceActivityFilter(
            segment: .daily(during: interval),
            applications: screenTimeManager.distractingSelection.applicationTokens,
            categories: screenTimeManager.distractingSelection.categoryTokens
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - METRICS HEADER (Removed)
                    
                    // MARK: - SECTION 1: CONTEXTUAL SUGGESTIONS
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header / Greeting?
                        // Optional: "What context are you in?" or just show sections.
                        // Requirement: "Context-based sections shown together on one screen"
                        // Smart Sort: Orders sections based on time of day
                        
                        // MARK: - MY LIST SECTION
                        MyListHeader(isShowingAddSheet: $isShowingAddSheet)
                        
                        Text("Your personal habits and ideas will appear here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        if !suggestionManager.customSuggestions.isEmpty {
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
                        // Header for Thera Suggestions
                        Text("Thera Suggestions")
                            .font(.title3)
                            .bold()
                            .padding(.horizontal)
                            .padding(.top, 16)
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
                        
                        // FOCUS TREND (Moved Here)
                        DeviceActivityReport(.weeklyDelta, filter: comparisonFilter)
                            .frame(height: 100)
                            .padding(.horizontal)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
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
                suggestionManager.refreshSuggestions(preference: persistenceManager.suggestionPreference)
                updateFilter()
                runDiagnostics()
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
    
    func runDiagnostics() {
        print("======== THERA DIAGNOSTICS ========")
        let groupID = "group.com.thera.app"
        
        // 1. Check Container URL
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
            print("✅ App Group Container URL: \(url.path)")
            
            // 1b. Hard File Test
            let testFileURL = url.appendingPathComponent("diag_test.txt")
            let testString = "Disk write test: \(Date())"
            do {
                try testString.write(to: testFileURL, atomically: true, encoding: .utf8)
                let readBack = try String(contentsOf: testFileURL, encoding: .utf8)
                print("✅ Direct File Write/Read successful: \(readBack)")
            } catch {
                print("❌ FAILED: Direct File Write Error: \(error.localizedDescription)")
            }
        } else {
            print("❌ FAILED: App Group Container URL is NIL. Entitlements issue likely.")
        }
        
        // 2. Check Shared UserDefaults
        let defaults = UserDefaults(suiteName: groupID)
        if let defaults = defaults {
            print("✅ Shared UserDefaults initialized for \(groupID)")
            
            // Test Write/Read
            let testKey = "diag_test_\(Int.random(in: 0...999))"
            defaults.set("HELLO", forKey: testKey)
            if defaults.string(forKey: testKey) == "HELLO" {
                print("✅ Write/Read test successful")
            } else {
                print("❌ FAILED: Write/Read test failed. UserDefaults is not persisting.")
            }
            
            // 3. Extension Pings
            if let configPing = defaults.object(forKey: "shieldConfigPing") as? Date {
                print("✅ Shield Configuration Extension last ran at: \(configPing)")
            } else {
                print("⚠️  Shield Configuration Extension has NEVER reported in. Code in createShield is not running.")
            }
            
            if let actionPing = defaults.object(forKey: "shieldActionPing") as? Date {
                print("✅ Shield Action Extension last ran at: \(actionPing)")
            } else {
                print("⚠️  Shield Action Extension has NEVER reported in. Unlock handlers are not running.")
            }
            
            // 4. Counts
            print("📊 Current Counts: Shown=\(defaults.integer(forKey: "shieldShownCount")), Unlocked=\(defaults.integer(forKey: "shieldUnlockedCount"))")
        } else {
            print("❌ FAILED: Could not initialize UserDefaults suite \(groupID)")
        }
        print("===================================")
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
    static let weeklyDelta = Self("WeeklyDelta")
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
