import DeviceActivity
import SwiftUI
import ManagedSettings
import ExtensionKit

// Step 1: Define Contexts
extension DeviceActivityReport.Context {
    static let dailyProgress = Self("DailyProgress")
    static let activityBreakdown = Self("ActivityBreakdown")
    static let miniUsage = Self("MiniUsage")
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
    let duration: TimeInterval
}

// Step 3: Main Entry Point
@main
@MainActor
struct TheraReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        // Define a scene for the Progress Context
        TotalActivityReport(context: .dailyProgress)
        
        // Define a scene for the Breakdown Context
        TotalActivityReport(context: .activityBreakdown)
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
        var appDurations: [String: TimeInterval] = [:]
        
        for await activityData in data {
            for await activity in activityData.activitySegments {
                for await category in activity.categories {
                    for await app in category.applications {
                        let name = app.application.localizedDisplayName ?? "Unknown App"
                        let duration = app.totalActivityDuration
                        totalDuration += duration
                        appDurations[name, default: 0] += duration
                    }
                }
            }
        }
        
        // Convert to AppReportItem and sort
        let appItems = appDurations.map { AppReportItem(name: $0.key, duration: $0.value) }
            .sorted { $0.duration > $1.duration }
        
        return ActivityReport(context: context, totalDuration: totalDuration, apps: appItems)
    }

}

// Step 5: The View that switches based on context
struct TotalActivityView: View {
    let report: ActivityReport
    
    var body: some View {
        switch report.context {
        case .dailyProgress:
            ProgressReportView(report: report)
        case .activityBreakdown:
            BreakdownReportView(report: report)
        default:
            Text("Unknown Context")
        }
    }
}


// Step 6: Subviews
struct MiniUsageView: View {
    let report: ActivityReport
    
    var body: some View {
        // We expect this filter to target a single app, so totalDuration is the app's duration.
        // Or we just show the first app item.
        let duration = report.totalDuration
        Text("Avg: \(formatTime(duration))/day")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        return "\(minutes) min"
    }
}

struct ProgressReportView: View {
    let report: ActivityReport
    @State private var goalMinutes: Int = 15
    
    var body: some View {
        let progress = goalMinutes > 0 ? min(report.totalDuration / (Double(goalMinutes) * 60), 1.0) : 0
        let totalMinutes = Int(report.totalDuration / 60)
        
        HStack {
            Spacer()
            ZStack {
                Circle()
                    .stroke(lineWidth: 8)
                    .opacity(0.3)
                    .foregroundColor(Color.blue)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(progress))
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color.blue)
                    .rotationEffect(Angle(degrees: 270.0))
            }
            .frame(width: 80, height: 80)
            
            VStack(alignment: .leading) {
                Text("\(totalMinutes) min")
                    .font(.title2)
                    .bold()
                Text("of \(goalMinutes) min goal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.leading)
            Spacer()
        }
        .onAppear {
            if let defaults = UserDefaults(suiteName: "group.com.thera.app") {
                let savedGoal = defaults.integer(forKey: "dailyGoalMinutes")
                self.goalMinutes = savedGoal > 0 ? savedGoal : 15
            }
        }
    }
}

struct BreakdownReportView: View {
    let report: ActivityReport
    
    var body: some View {
        VStack {
            if report.apps.isEmpty {
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(report.apps.prefix(5)) { app in
                    HStack {
                        Text(app.name)
                            .lineLimit(1)
                            .font(.caption)
                        Spacer()
                        Text(formatTime(app.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                    Divider()
                }
            }
        }
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
