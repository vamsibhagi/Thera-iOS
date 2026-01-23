import Foundation

struct TaskDatabase {
    static let allTasks: [TaskItem] = [
        // --- Light ---
        TaskItem(id: "l1", text: "Drink a glass of water", type: .light, category: "Health", url: nil, isTheraSuggested: true),
        TaskItem(id: "l2", text: "Stand up and stretch", type: .light, category: "Health", url: nil, isTheraSuggested: true),
        TaskItem(id: "l3", text: "Look out the window (20s)", type: .light, category: "Mindfulness", url: nil, isTheraSuggested: true),
        TaskItem(id: "l4", text: "Take 3 deep breaths", type: .light, category: "Mindfulness", url: nil, isTheraSuggested: true),
        TaskItem(id: "l5", text: "Clean your screen", type: .light, category: "Tidy", url: nil, isTheraSuggested: true),
        TaskItem(id: "l6", text: "Text a friend 'Hello'", type: .light, category: "Social", url: nil, isTheraSuggested: true),
        TaskItem(id: "l7", text: "Do 10 jumping jacks", type: .light, category: "Health", url: nil, isTheraSuggested: true),
        TaskItem(id: "l8", text: "Water a plant", type: .light, category: "Tidy", url: nil, isTheraSuggested: true),
        TaskItem(id: "l9", text: "Listen to one song", type: .light, category: "Relax", url: nil, isTheraSuggested: true),
        TaskItem(id: "l10", text: "Close your eyes for 1 min", type: .light, category: "Rest", url: nil, isTheraSuggested: true),
        
        // --- Focused ---
        TaskItem(id: "f1", text: "Read a graphical article", type: .focused, category: "Learning", url: "https://en.wikipedia.org/wiki/Special:Random", isTheraSuggested: true),
        TaskItem(id: "f2", text: "Learn one new word", type: .focused, category: "Learning", url: "https://www.merriam-webster.com/word-of-the-day", isTheraSuggested: true),
        TaskItem(id: "f3", text: "Plan tomorrow's meals", type: .focused, category: "Planning", url: nil, isTheraSuggested: true),
        TaskItem(id: "f4", text: "Write 3 gratitudes", type: .focused, category: "Journaling", url: nil, isTheraSuggested: true),
        TaskItem(id: "f5", text: "5 min Duolingo / Language", type: .focused, category: "Learning", url: nil, isTheraSuggested: true),
        TaskItem(id: "f6", text: "Organize photos for 5 mins", type: .focused, category: "Tidy", url: nil, isTheraSuggested: true),
        TaskItem(id: "f7", text: "Read 5 pages of a book", type: .focused, category: "Reading", url: nil, isTheraSuggested: true),
        TaskItem(id: "f8", text: "Sketch something nearby", type: .focused, category: "Creative", url: nil, isTheraSuggested: true),
        TaskItem(id: "f9", text: "Update your budget", type: .focused, category: "Admin", url: nil, isTheraSuggested: true),
        TaskItem(id: "f10", text: "Plan your weekend", type: .focused, category: "Planning", url: nil, isTheraSuggested: true)
    ]
}
