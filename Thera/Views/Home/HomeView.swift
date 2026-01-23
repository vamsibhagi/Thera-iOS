import SwiftUI
import DeviceActivity
import FamilyControls

struct HomeView: View {
    @EnvironmentObject var persistenceManager: PersistenceManager
    @State private var timeRange: TimeRange = .day
    
    // Filters for Report
    @State private var filter = DeviceActivityFilter(
        segment: .daily(during: Calendar.current.dateInterval(of: .day, for: Date())!)
    )
    
    // UI State for collapsing sections
    @State private var isLightExpanded = true
    @State private var isFocusedExpanded = true
    @State private var isCompletedExpanded = false
    
    // Inline add state
    // We can use a simple sheet or inline field. Prompt says "Inline text input row directly under the header".
    @State private var isAddingLight = false
    @State private var isAddingFocused = false
    @State private var newTaskText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - SECTION 1: TASKS
                    VStack(alignment: .leading, spacing: 16) {
                        // Subheader
                        Text(statusLine)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        // Light Tasks
                        taskSection(
                            title: "Light",
                            type: .light,
                            isExpanded: $isLightExpanded,
                            isAdding: $isAddingLight,
                            tasks: persistenceManager.userTasks.filter { $0.type == .light && !$0.isCompleted }
                        )
                        
                        // Focused Tasks
                        taskSection(
                            title: "Focused",
                            type: .focused,
                            isExpanded: $isFocusedExpanded,
                            isAdding: $isAddingFocused,
                            tasks: persistenceManager.userTasks.filter { $0.type == .focused && !$0.isCompleted }
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
                        // We use the Breakdown context to show list of usage
                        // DeviceActivityReport(.activityBreakdown, filter: filter) // iOS 26: Removed
                        //    .frame(height: 300)
                        //    .padding(.horizontal)
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
        }
    }
    
    var statusLine: String {
        let today = persistenceManager.completedTasks.filter { Calendar.current.isDateInToday($0.createdAt) }.count
        // Calculation for week/month omitted for brevity, using static for now or just daily
        return "Today: \(today) done"
    }
    
    // MARK: - Task Sections
    func taskSection(title: String, type: TaskType, isExpanded: Binding<Bool>, isAdding: Binding<Bool>, tasks: [TaskItem]) -> some View {
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
                        TextField("Add a \(title.lowercased()) task...", text: $newTaskText)
                            .focused($isInputFocused)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit { submitTask(type: type, binding: isAdding) }
                        
                        Button("Add") { submitTask(type: type, binding: isAdding) }
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
    
    func submitTask(type: TaskType, binding: Binding<Bool>) {
        guard !newTaskText.isEmpty else {
            binding.wrappedValue = false
            return
        }
        
        let newTask = TaskItem(
            id: UUID().uuidString,
            text: newTaskText,
            type: type,
            category: "User",
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
        
        // Filter for Distracting Apps only? Prompt says "Shows aggregated time for selected distracting apps".
        let selection = TheraScreenTimeManager.shared.distractingSelection
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
