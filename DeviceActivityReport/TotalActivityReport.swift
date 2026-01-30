import DeviceActivity
import SwiftUI
@preconcurrency import ManagedSettings
import ExtensionKit
import Charts

// Step 1: Define Contexts
extension DeviceActivityReport.Context {
    static let dailyProgress = Self("DailyProgress")
    static let activityBreakdown = Self("ActivityBreakdown")
    static let weeklyDelta = Self("WeeklyDelta")
}

// Step 2: Define Data Model
struct ActivityReport: Sendable {
    let context: DeviceActivityReport.Context
    let totalDuration: TimeInterval
    let apps: [AppReportItem]
}

struct AppReportItem: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let token: ApplicationToken? // Identifying for limit matching (optional as we only need name for display mostly) but useful if we could match. Actually we can't send Token out of sandbox easily?
    // We can't match Token to Limit inside Report Extension easily if we don't have the Limit map *inside* here.
    // We will load Limits *inside* makeConfiguration and match there.
    let duration: TimeInterval
    let limit: TimeInterval // in seconds
}

// Helper for Limits
struct AppLimit: Codable, Identifiable {
    var id: UUID = UUID()
    let token: ApplicationToken
    var dailyLimitMinutes: Int
}

// Step 3: Main Entry Point
@main
@MainActor
struct TheraReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        // We handle multiple contexts in the main entry point
        TotalActivityReport(context: .dailyProgress)
        ComparisonReport(context: .weeklyDelta)
    }
}

// Step 4: The Report Scene
@MainActor
struct TotalActivityReport: DeviceActivityReportScene {
    // Properties required by protocol
    let context: DeviceActivityReport.Context
    let content: (ActivityReport) -> TotalActivityView
    
    init(context: DeviceActivityReport.Context) {
        self.context = context
        self.content = { report in TotalActivityView(report: report) }
    }
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityReport {
        var totalDuration: TimeInterval = 0
        var appItems: [AppReportItem] = []
        
        // 1. Load Limits from Shared Defaults
        let defaults = UserDefaults(suiteName: "group.com.thera.app")
        let appLimits: [AppLimit]
        if let limitData = defaults?.data(forKey: "AppLimits"),
           let decoded = try? JSONDecoder().decode([AppLimit].self, from: limitData) {
            appLimits = decoded
        } else {
            appLimits = []
        }
        
        // Helper to find limit for a token
        func getLimit(for token: ApplicationToken) -> TimeInterval {
            // Compare tokens by encoding
            if let match = appLimits.first(where: {
                guard let d1 = try? JSONEncoder().encode($0.token),
                      let d2 = try? JSONEncoder().encode(token) else { return false }
                return d1 == d2
            }) {
                return TimeInterval(match.dailyLimitMinutes * 60)
            }
            return 5 * 60 // Default 5 mins (updated)
        }
        
        // Re-do aggregation with a Dictionary [String: (duration: TimeInterval, limit: TimeInterval, token: ApplicationToken?)]
        // Since Token isn't Hashable easily, we use [String: (Name, Duration, Limit)] where String is name?
        // Or just iterate again properly:
        
        var aggregated: [String: (duration: TimeInterval, limit: TimeInterval, token: ApplicationToken?)] = [:]
        
        for await activityData in data {
            for await activity in activityData.activitySegments {
                for await category in activity.categories {
                    for await app in category.applications {
                        let name = app.application.localizedDisplayName ?? "Unknown"
                        let duration = app.totalActivityDuration
                        let token = app.application.token
                        // Only fetch limit if we haven't set it, or just re-fetch (cheap)
                        let limit = getLimit(for: token!) // Force unwrap valid here?
                        
                        if let current = aggregated[name] {
                            aggregated[name] = (current.duration + duration, current.limit, current.token)
                        } else {
                            aggregated[name] = (duration, limit, token)
                        }
                        
                        totalDuration += duration
                    }
                }
            }
        }
        
        // Convert to Items
        appItems = aggregated.map { key, value in
            AppReportItem(name: key, token: value.token, duration: value.duration, limit: value.limit)
        }.sorted { $0.duration > $1.duration }
        
        return ActivityReport(context: context, totalDuration: totalDuration, apps: appItems)
    }

}

// Step 5: The View
struct TotalActivityView: View {
    let report: ActivityReport
    
    var body: some View {
        VStack(spacing: 16) {
            // 1. Total Time
            VStack {
                Text("Total Distraction Time")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(formatTime(report.totalDuration))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(.top)
            
            // 2. Chart Breakdown (Usage vs Limit)
            if #available(iOS 16.0, *) {
                Chart(report.apps) { item in
                    // Bar for Usage
                    BarMark(
                        x: .value("App", item.name),
                        y: .value("Minutes", item.duration / 60)
                    )
                    .foregroundStyle(isOverLimit(item) ? Color.red : Color.blue)
                    .cornerRadius(4)
                    
                    // Rule for Limit
                    RuleMark(
                        xStart: .value("App", item.name),
                        xEnd: .value("App", item.name),
                        y: .value("Limit", item.limit / 60)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .foregroundStyle(Color.gray)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 200)
                .padding()
            } else {
                // Fallback for older iOS (unlikely, but safe)
                VStack(spacing: 8) {
                    ForEach(report.apps.prefix(5)) { item in
                        HStack {
                            Text(item.name).font(.caption).frame(width: 80, alignment: .leading)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 8)
                                    Rectangle()
                                        .fill(isOverLimit(item) ? Color.red : Color.blue)
                                        .frame(width: min(geo.size.width * (item.duration / (item.limit > 0 ? item.limit * 1.5 : 1.0)), geo.size.width), height: 8)
                                }
                            }
                            Text("\(Int(item.duration/60))/\(Int(item.limit/60))m")
                                .font(.caption2)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    func isOverLimit(_ item: AppReportItem) -> Bool {
        return item.duration > item.limit
    }
    func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        let hours = minutes / 60
        if hours > 0 {
            return "\(hours)h \(minutes % 60)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Weekly Comparison Report
struct ComparisonData: Sendable {
    let thisWeekDuration: TimeInterval
    let lastWeekDuration: TimeInterval
    let delta: TimeInterval
}

struct ComparisonReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context
    let content: (ComparisonData) -> WeeklyDeltaView
    
    init(context: DeviceActivityReport.Context) {
        self.context = context
        self.content = { data in WeeklyDeltaView(data: data) }
    }
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ComparisonData {
        var thisWeek: TimeInterval = 0
        var lastWeek: TimeInterval = 0
        
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        
        for await activityData in data {
            // Check if this segment is in "this week" or "last week"
            // Wait, DeviceActivityData has an interval?
            // "data" is DeviceActivityResults, which is an interrogation of the filter.
            // The filter defines the interval. 
            // If the filter is "Last 14 days", we need to see the date of each activity segment.
            
            for await activity in activityData.activitySegments {
                let segmentStart = activity.dateInterval.start
                let isThisWeek = segmentStart >= sevenDaysAgo
                
                for await category in activity.categories {
                    for await app in category.applications {
                        let duration = app.totalActivityDuration
                        if isThisWeek {
                            thisWeek += duration
                        } else {
                            lastWeek += duration
                        }
                    }
                }
            }
        }
        
        return ComparisonData(
            thisWeekDuration: thisWeek,
            lastWeekDuration: lastWeek,
            delta: thisWeek - lastWeek
        )
    }
}

struct WeeklyDeltaView: View {
    let data: ComparisonData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Focus Trend")
                .font(.system(.caption, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text(formatDelta(data.delta))
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(data.delta <= 0 ? .green : .red)
            
            Text("vs last week")
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    func formatDelta(_ delta: TimeInterval) -> String {
        let absDelta = abs(delta)
        let minutes = Int(absDelta / 60)
        let hours = minutes / 60
        let sign = delta <= 0 ? "-" : "+"
        
        if hours > 0 {
            return "\(sign)\(hours)h \(minutes % 60)m"
        } else {
            return "\(sign)\(minutes)m"
        }
    }
}
