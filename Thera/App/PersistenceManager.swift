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
    @Published var suggestionPreference: SuggestionPreference = .mix {
        didSet { save(suggestionPreference, key: "SuggestionPreference") }
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
        self.suggestionPreference = load(key: "SuggestionPreference") ?? .mix
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
        if let index = appLimits.firstIndex(where: { areTokensEqual($0.token, token) }) {
            appLimits[index].dailyLimitMinutes = minutes
        } else {
            appLimits.append(AppLimit(token: token, dailyLimitMinutes: minutes))
        }
    }
    
    func getLimit(for token: ApplicationToken) -> Int {
        return appLimits.first(where: { areTokensEqual($0.token, token) })?.dailyLimitMinutes ?? 5 // Default 5
    }
    
    // Ensure appLimits contains entries for all selected apps
    func syncLimits(with selection: FamilyActivitySelection) {
        // 1. Add New
        for token in selection.applicationTokens {
            if !appLimits.contains(where: { areTokensEqual($0.token, token) }) {
                appLimits.append(AppLimit(token: token, dailyLimitMinutes: 5))
            }
        }
        
        // 2. Remove Unselected
        appLimits.removeAll { limit in
            !selection.applicationTokens.contains(where: { areTokensEqual($0, limit.token) })
        }
    }
    
    func areTokensEqual(_ lhs: ApplicationToken, _ rhs: ApplicationToken) -> Bool {
        // Safe comparison for iOS 26 ApplicationToken
        guard let lhsData = try? JSONEncoder().encode(lhs),
              let rhsData = try? JSONEncoder().encode(rhs) else {
            return false
        }
        return lhsData == rhsData
    }
    
    // MARK: - Task Logic
    func hydrateSuggestions() {
        // Legacy method no longer used in V3 Design
        // Retained to avoid breaking calls in Onboarding/Settings if any
    }
    
    func removeTask(_ task: TaskItem) {
        userTasks.removeAll { $0.id == task.id }
    }
}
