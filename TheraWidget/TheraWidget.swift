import WidgetKit
import SwiftUI

// MARK: - Shared Models (Duplicated for Extension Target Independence)
enum SuggestionCategory: String, Codable, CaseIterable {
    case onPhone = "on_phone"
    case offPhone = "off_phone"
}

struct TaskItem: Identifiable, Codable, Hashable {
    let id: String
    var text: String
    var suggestionCategory: SuggestionCategory
    var activityType: String
    var url: String?
    var isTheraSuggested: Bool
    var isCompleted: Bool = false
    var createdAt: Date = Date()
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), tasks: [
            TaskItem(id: "1", text: "Drink water", suggestionCategory: .offPhone, activityType: "Health", url: nil, isTheraSuggested: true),
            TaskItem(id: "2", text: "Duolingo lesson", suggestionCategory: .onPhone, activityType: "Learning", url: nil, isTheraSuggested: true)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = loadEntry()
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
    
    private func loadEntry() -> SimpleEntry {
        let defaults = UserDefaults(suiteName: "group.com.thera.app")
        guard let data = defaults?.data(forKey: "UserTasks"),
              let tasks = try? JSONDecoder().decode([TaskItem].self, from: data) else {
            return SimpleEntry(date: Date(), tasks: [])
        }
        
        let activeTasks = tasks.filter { !$0.isCompleted }.shuffled()
        return SimpleEntry(date: Date(), tasks: activeTasks)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let tasks: [TaskItem]
}

struct TheraWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
            
            switch family {
            case .accessoryRectangular:
                lockScreenView
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            case .systemLarge:
                largeView
            default:
                smallView
            }
        }
    }
    
    // MARK: - Views
    
    private var lockScreenView: some View {
        VStack(alignment: .leading) {
            Text("Try this now:")
                .font(.caption2)
                .fontWeight(.bold)
            if let task = entry.tasks.first {
                Text(task.text)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(2)
            }
        }
    }
    
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            Spacer()
            if let task = entry.tasks.first {
                suggestionRow(task)
            }
            Spacer()
        }
        .padding()
    }
    
    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            ForEach(entry.tasks.prefix(2)) { task in
                suggestionRow(task)
            }
        }
        .padding()
    }
    
    private var largeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            VStack(alignment: .leading, spacing: 12) {
                ForEach(entry.tasks.prefix(6)) { task in
                    suggestionRow(task)
                    if task.id != entry.tasks.prefix(6).last?.id {
                        Divider()
                    }
                }
            }
            Spacer()
        }
        .padding()
    }
    
    private var header: some View {
        Text("PURPOSEFUL PAUSE")
            .font(.caption2)
            .fontWeight(.black)
            .foregroundColor(.blue)
            .kerning(1)
    }
    
    private func suggestionRow(_ task: TaskItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: task.suggestionCategory == .onPhone ? "iphone" : "leaf.fill")
                .foregroundColor(task.suggestionCategory == .onPhone ? .blue : .green)
                .font(.system(size: 14))
            
            Text(task.text)
                .font(.system(size: 15, weight: .medium))
                .lineLimit(1)
            
            Spacer()
        }
    }
}

@main
struct TheraWidget: Widget {
    let kind: String = "TheraWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TheraWidgetEntryView(entry: entry)
                .widgetBackground(Color(UIColor.systemBackground))
        }
        .configurationDisplayName("Thera Thoughts")
        .description("Quick suggestions for your next break.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
    }
}

