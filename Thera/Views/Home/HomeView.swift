import SwiftUI
import DeviceActivity
import FamilyControls
import ManagedSettings

struct HomeView: View {
    @EnvironmentObject var persistenceManager: PersistenceManager
    @EnvironmentObject var screenTimeManager: TheraScreenTimeManager
    @State private var timeRange: TimeRange = .day
    
    // Filters for Report
    @State private var filter = DeviceActivityFilter(
        segment: .daily(during: Calendar.current.dateInterval(of: .day, for: Date())!)
    )
    
    // UI State for collapsing sections
    @State private var isOnPhoneExpanded = true
    @State private var isOffPhoneExpanded = true
    @State private var isCompletedExpanded = false
    
    // Inline add state
    @State private var isAddingOnPhone = false
    @State private var isAddingOffPhone = false
    @State private var newTaskText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - SECTION 1: PURPOSEFUL SUGGESTIONS
                    VStack(alignment: .leading, spacing: 16) {
                        // Subheader
                        Text(statusLine)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        // Diagnostics
                        VStack(alignment: .leading, spacing: 4) {
                            if UserDefaults(suiteName: "group.com.thera.app") == nil {
                                Label("App Group Connection: FAILED", systemImage: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            } else {
                                Label("App Group Connection: OK", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            
                            Text("Blocked Apps: \(screenTimeManager.distractingSelection.applicationTokens.count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .font(.caption2)
                        .padding(.horizontal)
                        
                        // On-Phone Suggestions
                        taskSection(
                            title: "On-Phone",
                            category: .onPhone,
                            isExpanded: $isOnPhoneExpanded,
                            isAdding: $isAddingOnPhone,
                            tasks: persistenceManager.userTasks.filter { $0.suggestionCategory == .onPhone && !$0.isCompleted }
                        )
                        
                        // Off-Phone Suggestions
                        taskSection(
                            title: "Off-Phone",
                            category: .offPhone,
                            isExpanded: $isOffPhoneExpanded,
                            isAdding: $isAddingOffPhone,
                            tasks: persistenceManager.userTasks.filter { $0.suggestionCategory == .offPhone && !$0.isCompleted }
                        )
                        
                        // Completed Tasks
                        completedSection
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // MARK: - SECTION 2: SCREEN TIME
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Screen Time")
                            .font(.title3)
                            .bold()
                            .padding(.horizontal)
                        
                        // Range Selector (Simple Segmented)
                        Picker("Range", selection: $timeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .onChange(of: timeRange) { updateFilter() }
                        
                        // Report
                        DeviceActivityReport(.dailyProgress, filter: filter)
                            .frame(height: 120)
                        
                        Text("Top Blocked Apps")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        DeviceActivityReport(.activityBreakdown, filter: filter)
                            .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Thera")
            .navigationBarItems(trailing: NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape")
            })
            .onAppear {
                persistenceManager.hydrateSuggestions()
                updateFilter()
            }
            .onChange(of: screenTimeManager.distractingSelection) {
                updateFilter()
            }
        }
    }
    
    var statusLine: String {
        let today = persistenceManager.completedTasks.filter { Calendar.current.isDateInToday($0.createdAt) }.count
        return "Today: \(today) purposeful pauses"
    }
    
    // MARK: - Task Sections
    func taskSection(title: String, category: SuggestionCategory, isExpanded: Binding<Bool>, isAdding: Binding<Bool>, tasks: [TaskItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Button(action: { withAnimation { isExpanded.wrappedValue.toggle() } }) {
                    HStack {
                        Text("\(title) (\(tasks.count))")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isExpanded.wrappedValue = true
                        isAdding.wrappedValue = true
                        isInputFocused = true
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if isExpanded.wrappedValue {
                // Inline Input
                if isAdding.wrappedValue {
                    HStack {
                        TextField("Add a \(title.lowercased()) suggestion...", text: $newTaskText)
                            .focused($isInputFocused)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit { submitTask(category: category, binding: isAdding) }
                        
                        Button("Add") { submitTask(category: category, binding: isAdding) }
                            .disabled(newTaskText.isEmpty)
                    }
                    .padding(.horizontal)
                }
                
                // Task Rows
                ForEach(tasks) { task in
                    TaskRowView(task: task)
                        .transition(.slide)
                }
            }
        }
    }
    
    var completedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation { isCompletedExpanded.toggle() } }) {
                HStack {
                    Text("Completed (\(persistenceManager.completedTasks.count))")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isCompletedExpanded ? 90 : 0))
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
            .padding(.horizontal)
            
            if isCompletedExpanded {
                ForEach(persistenceManager.completedTasks) { task in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(task.text)
                            .strikethrough()
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    func submitTask(category: SuggestionCategory, binding: Binding<Bool>) {
        guard !newTaskText.isEmpty else {
            binding.wrappedValue = false
            return
        }
        
        let newTask = TaskItem(
            id: UUID().uuidString,
            text: newTaskText,
            suggestionCategory: category,
            activityType: "User",
            url: nil,
            isTheraSuggested: false
        )
        persistenceManager.addTask(newTask)
        newTaskText = ""
        binding.wrappedValue = false
    }
    
    func updateFilter() {
        let calendar = Calendar.current
        let interval: DateInterval
        switch timeRange {
        case .day: interval = calendar.dateInterval(of: .day, for: Date())!
        case .week: interval = calendar.dateInterval(of: .weekOfYear, for: Date())!
        case .month: interval = calendar.dateInterval(of: .month, for: Date())!
        case .year: interval = calendar.dateInterval(of: .year, for: Date())!
        case .allTime: interval = DateInterval(start: Date.distantPast, end: Date())
        }
        
        // Filter for Distracting Apps
        let selection = screenTimeManager.distractingSelection
        print("DEBUG: Updating filter with \(selection.applicationTokens.count) apps")
        
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
    case year = "Year"
    case allTime = "All time"
}

// MARK: - Report Contexts
extension DeviceActivityReport.Context {
    static let dailyProgress = Self("DailyProgress")
    static let activityBreakdown = Self("ActivityBreakdown")
}
