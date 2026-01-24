import Foundation

struct TaskDatabase {
    static let allTasks: [TaskItem] = [
        // --- Off-Phone ---
        TaskItem(id: "off1", text: "Drink a glass of water", emoji: "💧", suggestionCategory: .offPhone, activityType: "Health", url: nil, isTheraSuggested: true),
        TaskItem(id: "off2", text: "Stand up and stretch", emoji: "🧍", suggestionCategory: .offPhone, activityType: "Health", url: nil, isTheraSuggested: true),
        TaskItem(id: "off3", text: "Say hi to someone nearby", emoji: "👋", suggestionCategory: .offPhone, activityType: "Social", url: nil, isTheraSuggested: true),
        TaskItem(id: "off4", text: "Take 3 deep breaths", emoji: "🧘", suggestionCategory: .offPhone, activityType: "Mindfulness", url: nil, isTheraSuggested: true),
        TaskItem(id: "off5", text: "Step outside for a minute", emoji: "🌳", suggestionCategory: .offPhone, activityType: "Nature", url: nil, isTheraSuggested: true),
        TaskItem(id: "off6", text: "Make a cup of tea", emoji: "🍵", suggestionCategory: .offPhone, activityType: "Health", url: nil, isTheraSuggested: true),
        TaskItem(id: "off7", text: "Do 10 jumping jacks", emoji: "🏃", suggestionCategory: .offPhone, activityType: "Health", url: nil, isTheraSuggested: true),
        TaskItem(id: "off8", text: "Water a plant", emoji: "🪴", suggestionCategory: .offPhone, activityType: "Tidy", url: nil, isTheraSuggested: true),
        TaskItem(id: "off9", text: "Listen to one song (speaker)", emoji: "🎵", suggestionCategory: .offPhone, activityType: "Relax", url: nil, isTheraSuggested: true),
        TaskItem(id: "off10", text: "Close your eyes for 1 min", emoji: "😌", suggestionCategory: .offPhone, activityType: "Rest", url: nil, isTheraSuggested: true),
        
        // --- On-Phone ---
        TaskItem(id: "on1", text: "Do a short Duolingo lesson", emoji: "🦉", suggestionCategory: .onPhone, activityType: "Learning", url: "https://www.duolingo.com/", isTheraSuggested: true),
        TaskItem(id: "on2", text: "Read a random Wikipedia article", emoji: "🌏", suggestionCategory: .onPhone, activityType: "Learning", url: "https://en.wikipedia.org/wiki/Special:Random", isTheraSuggested: true),
        TaskItem(id: "on3", text: "Write a quick note for tomorrow", emoji: "📝", suggestionCategory: .onPhone, activityType: "Planning", url: "mobilenotes://", isTheraSuggested: true),
        TaskItem(id: "on4", text: "Check your calendar for the week", emoji: "📅", suggestionCategory: .onPhone, activityType: "Planning", url: "calshow://", isTheraSuggested: true),
        TaskItem(id: "on5", text: "Learn the word of the day", emoji: "📖", suggestionCategory: .onPhone, activityType: "Learning", url: "https://www.merriam-webster.com/word-of-the-day", isTheraSuggested: true),
        TaskItem(id: "on6", text: "Organize 5 photos", emoji: "🖼️", suggestionCategory: .onPhone, activityType: "Tidy", url: "photos-redirect://", isTheraSuggested: true),
        TaskItem(id: "on7", text: "Read an article on Pocket", emoji: "📑", suggestionCategory: .onPhone, activityType: "Reading", url: "pocket://", isTheraSuggested: true),
        TaskItem(id: "on8", text: "Sketch something on Notes", emoji: "✏️", suggestionCategory: .onPhone, activityType: "Creative", url: "mobilenotes://", isTheraSuggested: true),
        TaskItem(id: "on9", text: "Review your budget app", emoji: "💰", suggestionCategory: .onPhone, activityType: "Admin", url: nil, isTheraSuggested: true),
        TaskItem(id: "on10", text: "Plan a weekend trip", emoji: "✈️", suggestionCategory: .onPhone, activityType: "Planning", url: nil, isTheraSuggested: true)
    ]
}
