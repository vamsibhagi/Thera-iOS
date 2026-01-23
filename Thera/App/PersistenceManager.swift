import Foundation
import SwiftUI
import Combine
import FamilyControls
import ManagedSettings

class PersistenceManager: ObservableObject {
    static let shared = PersistenceManager()
    
    // Use App Group suite so Extensions can read this data
    private let userDefaults = UserDefaults(suiteName: "group.com.thera.app") ?? .standard
    
    // MARK: - Onboarding State
    @Published var hasCompletedOnboarding: Bool {
        didSet { userDefaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }
    
    // MARK: - V2 Data: Tasks
    @Published var userTasks: [TaskItem] = [] {
        didSet { save(userTasks, key: "UserTasks") }
    }
    
    @Published var completedTasks: [TaskItem] = [] {
        didSet { save(completedTasks, key: "CompletedTasks") }
    }
    
    // MARK: - V2 Data: Topics
    @Published var topics: [Topic] = [] {
        didSet { save(topics, key: "UserTopics") }
    }
    
    // MARK: - V2 Data: Limits
    // We store the mapping of Token -> Limit (Minutes)
    // Note: ApplicationToken isn't stable across installs/devices usually, but within app life it is necessary.
    // However, FamilyActivitySelection is the canonical source.
    // For V2: We map the selection to limits.
    // We'll store a simple dictionary of encoded tokens?
    // Actually, FamilyActivitySelection is stored in ScreenTimeManager.
    // Here we store the *Preferences* (Time limits per app).
    // Storing [ApplicationToken: Int] is tricky because ApplicationToken is not directly Codable as a Key (it is Codable, but maybe not Key).
    // We will use an array of `AppLimit` struct which is Codable.
    @Published var appLimits: [AppLimit] = [] {
        didSet { save(appLimits, key: "AppLimits") }
    }
    
    // MARK: - Preferences
    @Published var effortPreference: EffortPreference = .mixed {
        didSet { save(effortPreference, key: "EffortPreference") }
    }
    
    // MARK: - Statistics
    @Published var currentStreak: Int = 0 
    
    private init() {
        self.hasCompletedOnboarding = userDefaults.bool(forKey: "hasCompletedOnboarding")
        self.currentStreak = userDefaults.integer(forKey: "currentStreak")
        
        // Load Arrays
        self.userTasks = load(key: "UserTasks") ?? []
        self.completedTasks = load(key: "CompletedTasks") ?? []
        self.topics = load(key: "UserTopics") ?? []
        self.appLimits = load(key: "AppLimits") ?? []
        self.effortPreference = load(key: "EffortPreference") ?? .mixed
    }
    
    // Generic Save/Load
    private func save<T: Codable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            userDefaults.set(data, forKey: key)
        }
    }
    
    private func load<T: Codable>(key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - Actions
    func completeOnboarding() {
        self.hasCompletedOnboarding = true
    }
    
    func addTask(_ task: TaskItem) {
        userTasks.append(task)
    }
    
    func completeTask(_ task: TaskItem) {
        var completed = task
        completed.isCompleted = true
        completed.createdAt = Date() // Completed time
        
        // Remove from active list
        userTasks.removeAll { $0.id == task.id }
        // Add to completed
        completedTasks.insert(completed, at: 0)
    }
    
    func setLimit(for token: ApplicationToken, minutes: Int) {
        if let index = appLimits.firstIndex(where: { $0.token == token }) {
            appLimits[index].dailyLimitMinutes = minutes
        } else {
            appLimits.append(AppLimit(token: token, dailyLimitMinutes: minutes))
        }
    }
    
    func getLimit(for token: ApplicationToken) -> Int {
        return appLimits.first(where: { $0.token == token })?.dailyLimitMinutes ?? 15 // Default 15
    }
    
    // MARK: - Task Logic
    func hydrateSuggestions() {
        let maxSuggestions = 5
        let currentSuggestedCount = userTasks.filter { $0.isTheraSuggested && !$0.isCompleted }.count
        
        if currentSuggestedCount < maxSuggestions {
            let needed = maxSuggestions - currentSuggestedCount
            // Pick random tasks from DB that aren't already in userTasks or completedTasks
            let existingIds = Set(userTasks.map { $0.id } + completedTasks.map { $0.id })
            
            let candidates = TaskDatabase.allTasks.filter { !existingIds.contains($0.id) }
            
            let newTasks = candidates.shuffled().prefix(needed)
            for task in newTasks {
                // Assign a unique runtime ID if we re-use templates? 
                // DB IDs are "l1", "l2". If user completes "l1", we don't want to show it again immediately.
                // For MVP, we respect the filter above.
                // We create a copy to ensure date is fresh
                var item = task
                item.createdAt = Date()
                userTasks.append(item)
            }
        }
    }
    
    func removeTask(_ task: TaskItem) {
        userTasks.removeAll { $0.id == task.id }
        // If it was a thumbs down (rejected), maybe track it so we don't show again?
        // For MVP, removing it puts it outside the "Active" list. 
        // Logic for "Don't show for 3 days" is complex. We'll skip for now.
    }
}
