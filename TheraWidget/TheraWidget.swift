import WidgetKit
import SwiftUI
import FamilyControls

// Ensure Models are available. If Models.swift is added to target, this is fine.


struct Provider: TimelineProvider {
    // Shared SuggestionManager might not work if not in widget target, 
    // but the file is shared. We assume it compiles.
    @ObservedObject var manager = SuggestionManager.shared
    
    func placeholder(in context: Context) -> SimpleEntry {
        // Fallback for placeholder
        SimpleEntry(
            date: Date(),
            context: .bed,
            suggestions: [
                Suggestion(id: "1", context: .bed, mode: .offPhone, emoji: "📖", text: "Read a page"),
                Suggestion(id: "2", context: .bed, mode: .offPhone, emoji: "🧘", text: "Meditate")
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = getSmartEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        // Generate timeline
        let entry = getSmartEntry()
        
        // Refresh every 30 minutes to rotate suggestions/context
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
    
    private func getSmartEntry() -> SimpleEntry {
        // 1. Get Top Context (Based on Time/Day)
        let topContext = SuggestionContext.smartSort().first ?? .bed
        
        // 2. Load Top Preference
        // Read raw string from UserDefaults to avoid full PersistenceManager dependency if not shared
        var pref: SuggestionPreference = .mix
        if let defaults = UserDefaults(suiteName: "group.com.thera.app"),
           let data = defaults.data(forKey: "SuggestionPreference"),
           let decoded = try? JSONDecoder().decode(SuggestionPreference.self, from: data) {
            pref = decoded
        }
        
        // 3. Refresh Manager
        manager.refreshSuggestions(preference: pref)
        
        // 4. Grab suggestions for this context
        let candidates = manager.contextSuggestions[topContext] ?? []
        let selected = Array(candidates.prefix(2)) 
        
        return SimpleEntry(date: Date(), context: topContext, suggestions: selected)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let context: SuggestionContext
    let suggestions: [Suggestion]
}

struct TheraWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemBackground)
            
            VStack(alignment: .leading, spacing: 10) {
                // Header: "Suggestion for [Context]"
                HStack {
                    Text(headerText)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .textCase(.uppercase)
                    Spacer()
                }
                
                // Content
                contentView
                
                Spacer()
            }
            .padding()
        }
        .widgetBackground(Color(UIColor.systemBackground))
    }
    
    var headerText: String {
        switch family {
        case .systemSmall:
            return "Try this now"
        default:
            return "For \(entry.context.displayName)"
        }
    }
    
    @ViewBuilder
    var contentView: some View {
        switch family {
        case .systemSmall:
            if let first = entry.suggestions.first {
                VStack(alignment: .leading, spacing: 2) {
                    Spacer()
                    Text(first.emoji)
                        .font(.system(size: 28))
                        .padding(.bottom, 4)
                    
                    Text(first.text)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(3)
                        .minimumScaleFactor(0.8) // Shrink if needed
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true) // Allow growing vertically
                    Spacer()
                }
            } else {
                Text("Take a break")
            }
            
        case .systemMedium:
            HStack(alignment: .top, spacing: 12) {
                ForEach(entry.suggestions) { suggestion in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(suggestion.emoji)
                            .font(.title3)
                        Text(suggestion.text)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(3)
                            .minimumScaleFactor(0.85)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(10)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
            }
            
        default:
            Text("Size not optimized")
        }
    }
}

@main
struct TheraWidget: Widget {
    let kind: String = "TheraWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TheraWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Thera Suggestions")
        .description("Smart, context-aware suggestions for your breaks.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// Extension to allow widget background modifier
extension View {
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(color, for: .widget)
        } else {
            return background(color)
        }
    }
}
