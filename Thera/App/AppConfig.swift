import Foundation

struct AppConfig {
    static let recommendedCreationApps: [RecommendedApp] = [
        RecommendedApp(name: "Apple Notes", storeId: "com.apple.mobilenotes", category: "Productivity", isSystem: true),
        RecommendedApp(name: "Obsidian", storeId: "1557175442", category: "Productivity"),
        RecommendedApp(name: "Duolingo", storeId: "57006003", category: "Education"),
        RecommendedApp(name: "Figma", storeId: "1510441995", category: "Graphics & Design"),
        RecommendedApp(name: "Procreate", storeId: "425073498", category: "Graphics & Design"),
        RecommendedApp(name: "GarageBand", storeId: "408709785", category: "Music"),
        RecommendedApp(name: "GitHub", storeId: "1477376905", category: "Developer Tools"),
        RecommendedApp(name: "Swift Playgrounds", storeId: "908519492", category: "Education"),
        RecommendedApp(name: "Kindle", storeId: "302584613", category: "Books")
    ]
    
    // Default consumption apps to pre-select
    static let defaultConsumptionApps: [String] = [
        "TikTok", "Instagram", "Snapchat", "YouTube", "Facebook", "X", "Twitter", "Reddit", "Netflix", "Hulu", "Disney+"
    ]
    
    // Bundle IDs if known, or heuristic matching for the configuration
    // Since we rely on FamilyActivityPicker for REAL selection, this list is primarily for 
    // "Pre-selected" UI logic if we can match them, or guiding the user.
    // Note: In Family Controls, we can't "auto-select" by name easily without user interaction 
    // unless we have their tokens saved. 
    // The "Hard-selected" requirement in onboarding Screen 6 implies we need to guide users 
    // to select these or show them as "Recommended to Block".
}

struct RecommendedApp: Identifiable {
    let id = UUID()
    let name: String
    let storeId: String
    let category: String
    var isSystem: Bool = false
}
