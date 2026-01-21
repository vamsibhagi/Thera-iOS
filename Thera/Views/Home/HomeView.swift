import SwiftUI
import DeviceActivity
import FamilyControls

struct HomeView: View {
    @EnvironmentObject var persistenceManager: PersistenceManager
    @State private var selectedRange: TimeRange = .day
    
    // Contexts for reports
    @State private var progressContext: DeviceActivityReport.Context = .init(rawValue: "DailyProgress")
    @State private var breakdownContext: DeviceActivityReport.Context = .init(rawValue: "ActivityBreakdown")
    
    // Filters for the reports
    @State private var creationFilter = DeviceActivityFilter(
        segment: .daily(during: Calendar.current.dateInterval(of: .day, for: Date())!)
    )
    @State private var consumptionFilter = DeviceActivityFilter(
        segment: .daily(during: Calendar.current.dateInterval(of: .day, for: Date())!)
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Top Stats Row
                    HStack(spacing: 16) {
                        // Progress Card (Report - Filtered by Creation Apps)
                        VStack {
                            Text("Today's Creation")
                                .font(.caption)
                                .foregroundColor(.gray)
                            // This view is rendered by the extension
                            DeviceActivityReport(progressContext, filter: creationFilter)
                                .frame(height: 120)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        
                        // Streak Card (Native)
                        VStack(spacing: 8) {
                            Text("\(persistenceManager.currentStreak) days")
                                .font(.system(size: 32, weight: .bold))
                            Text("Current Streak")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 150) // Match height roughly
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    
                    // Time Range Selector
                    Picker("Time Range", selection: $selectedRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: selectedRange) { oldValue, newValue in
                        updateFilters(for: newValue)
                    }
                    
                    // Detailed Breakdown (Report - Consumption)
                    VStack(alignment: .leading) {
                        Text("Consumption Breakdown")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        DeviceActivityReport(breakdownContext, filter: consumptionFilter)
                            .frame(height: 300)
                    }
                    
                    // Detailed Breakdown (Report - Creation)
                    VStack(alignment: .leading) {
                        Text("Creation Breakdown")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        DeviceActivityReport(breakdownContext, filter: creationFilter)
                            .frame(height: 300)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
            .onAppear {
                persistenceManager.refreshData()
                updateFilters(for: selectedRange)
            }
        }
    }
    
    private func updateFilters(for range: TimeRange) {
        let calendar = Calendar.current
        let now = Date()
        var interval: DateInterval?
        
        switch range {
        case .day:
            interval = calendar.dateInterval(of: .day, for: now)
        case .week:
            interval = calendar.dateInterval(of: .weekOfYear, for: now)
        case .month:
            interval = calendar.dateInterval(of: .month, for: now)
        case .year:
            interval = calendar.dateInterval(of: .year, for: now)
        case .allTime:
            interval = DateInterval(start: Date.distantPast, end: now)
        }
        
        if let interval = interval {
            // Creation Filter
            let creationSelection = TheraScreenTimeManager.shared.creationSelection
            creationFilter = DeviceActivityFilter(
                segment: .daily(during: interval),
                users: .all,
                devices: .init([.iPhone, .iPad]),
                applications: creationSelection.applicationTokens,
                categories: creationSelection.categoryTokens
            )
            
            // Consumption Filter
            let consumptionSelection = TheraScreenTimeManager.shared.consumptionSelection
            consumptionFilter = DeviceActivityFilter(
                segment: .daily(during: interval),
                users: .all,
                devices: .init([.iPhone, .iPad]),
                applications: consumptionSelection.applicationTokens,
                categories: consumptionSelection.categoryTokens
            )
        }
    }
}

enum TimeRange: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case allTime = "All time"
}
