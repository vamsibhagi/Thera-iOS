import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), streak: 5, todayProgressMin: 0, goalMin: 15, isGoalMet: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Reload every 15 minutes or when app foregrounds (handled by app)
        let entry = loadEntry()
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
    
    // Helper to load data from Shared Defaults
    private func loadEntry() -> SimpleEntry {
        let defaults = UserDefaults(suiteName: "group.com.thera.app")
        let streak = defaults?.integer(forKey: "currentStreak") ?? 0
        let isGoalMet = defaults?.bool(forKey: "isDailyGoalMet") ?? false
        let goal = defaults?.integer(forKey: "dailyGoalMinutes") ?? 15
        
        // Note: Progress minutes are hard to track accurately without DeviceActivityReport in widget 
        // OR the app writing it periodically. 
        // For this MVP, we will assume the app writes it or we show "0" / "Met" status.
        // Actually, DeviceActivityMonitor can write progress? No, only threshold events.
        // ScreenTime API limitations: Real-time progress in widget is hard without Background Tasks.
        // We will show "Goal Met" status or "Streak" primarily.
        
        return SimpleEntry(date: Date(), streak: streak, todayProgressMin: isGoalMet ? goal : 0, goalMin: goal, isGoalMet: isGoalMet)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let todayProgressMin: Int
    let goalMin: Int
    let isGoalMet: Bool
}

struct TheraWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Thera")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
                if entry.isGoalMet {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Streak Big Number
            HStack(alignment: .lastTextBaseline) {
                Text("\(entry.streak)")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.primary)
                Text("day streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 6)
            }
            
            Spacer()
            
            // Progress Bar / Text
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(entry.isGoalMet ? Color.green : Color.blue)
                            .frame(width: entry.isGoalMet ? geometry.size.width : (CGFloat(entry.todayProgressMin) / CGFloat(entry.goalMin)) * geometry.size.width, height: 6)
                    }
                }
                .frame(height: 6)
                
                Text(entry.isGoalMet ? "Goal Met" : "Keep creating")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

@main
struct TheraWidget: Widget {
    let kind: String = "TheraWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TheraWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Thera Streak")
        .description("Keep your creation streak visible.")
        .supportedFamilies([.systemSmall])
    }
}
