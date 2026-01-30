import Foundation
import SwiftUI
import Combine
import FamilyControls
import ManagedSettings
import WidgetKit

class PersistenceManager: ObservableObject {
    static let shared = PersistenceManager()
    
    // Use App Group suite so Extensions can read this data
    private let userDefaults = UserDefaults(suiteName: "group.com.thera.app") ?? .standard
    
    // MARK: - Onboarding State
    @Published var hasCompletedOnboarding: Bool {
        didSet { userDefaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }
    
    // MARK: - Legacy Cleanup
    // Formerly V2 Data: Tasks, Topics were here. Removed for V3.
    
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
    
    @Published var categoryLimits: [CategoryLimit] = [] {
        didSet { save(categoryLimits, key: "CategoryLimits") }
    }
    
    // MARK: - Preferences
    @Published var suggestionPreference: SuggestionPreference = .mix {
        didSet {
            save(suggestionPreference, key: "SuggestionPreference")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // MARK: - Statistics
    @Published var currentStreak: Int = 0 
    
    private init() {
        self.hasCompletedOnboarding = userDefaults.bool(forKey: "hasCompletedOnboarding")
        self.currentStreak = userDefaults.integer(forKey: "currentStreak")
        
        // Load Arrays
        self.appLimits = load(key: "AppLimits") ?? []
        self.categoryLimits = load(key: "CategoryLimits") ?? []
        self.suggestionPreference = load(key: "SuggestionPreference") ?? .mix
    }
    
    // MARK: - Helpers
    
    private func save<T: Encodable>(_ value: T, key: String) {
        if let encoded = try? JSONEncoder().encode(value) {
            userDefaults.set(encoded, forKey: key)
        }
    }
    
    private func load<T: Decodable>(key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Actions
    func completeOnboarding() {
        self.hasCompletedOnboarding = true
    }
    
    func setLimit(for token: ApplicationToken, minutes: Int) {
        if let index = appLimits.firstIndex(where: { areTokensEqual($0.token, token) }) {
            appLimits[index].dailyLimitMinutes = minutes
        } else {
            appLimits.append(AppLimit(token: token, dailyLimitMinutes: minutes))
        }
    }
    
    func setCategoryLimit(for token: ActivityCategoryToken, minutes: Int) {
        if let index = categoryLimits.firstIndex(where: { $0.token == token }) {
            categoryLimits[index].dailyLimitMinutes = minutes
        } else {
            categoryLimits.append(CategoryLimit(token: token, dailyLimitMinutes: minutes))
        }
    }
    
    func getLimit(for token: ApplicationToken) -> Int {
        return appLimits.first(where: { areTokensEqual($0.token, token) })?.dailyLimitMinutes ?? 5 // Default 5
    }
    
    func getCategoryLimit(for token: ActivityCategoryToken) -> Int {
        return categoryLimits.first(where: { $0.token == token })?.dailyLimitMinutes ?? 5
    }
    
    // Ensure appLimits/categoryLimits contains entries for all selected items
    func syncLimits(with selection: FamilyActivitySelection) {
        // 1. App Tokens
        for token in selection.applicationTokens {
            if !appLimits.contains(where: { areTokensEqual($0.token, token) }) {
                appLimits.append(AppLimit(token: token, dailyLimitMinutes: 5))
            }
        }
        
        appLimits.removeAll { limit in
            !selection.applicationTokens.contains(where: { areTokensEqual($0, limit.token) })
        }
        
        // 2. Category Tokens
        for token in selection.categoryTokens {
             if !categoryLimits.contains(where: { $0.token == token }) {
                 categoryLimits.append(CategoryLimit(token: token, dailyLimitMinutes: 5))
             }
        }
        
        categoryLimits.removeAll { limit in
            !selection.categoryTokens.contains { $0 == limit.token }
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
    
}
