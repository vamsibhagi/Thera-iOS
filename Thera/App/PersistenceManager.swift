import Foundation
import SwiftUI
import Combine

class PersistenceManager: ObservableObject {
    static let shared = PersistenceManager()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.thera.app") ?? .standard
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            userDefaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    @Published var dailyGoalMinutes: Int {
        didSet {
            userDefaults.set(dailyGoalMinutes, forKey: "dailyGoalMinutes")
        }
    }
    
    @Published var isDailyGoalMet: Bool = false
    @Published var currentStreak: Int = 0
    
    private init() {
        self.hasCompletedOnboarding = userDefaults.bool(forKey: "hasCompletedOnboarding")
        self.dailyGoalMinutes = userDefaults.integer(forKey: "dailyGoalMinutes")
        if self.dailyGoalMinutes == 0 { self.dailyGoalMinutes = 15 } // Default to 15 if not set
        
        // Load transient state
        self.isDailyGoalMet = userDefaults.bool(forKey: "isDailyGoalMet")
        self.currentStreak = userDefaults.integer(forKey: "currentStreak")
    }
    
    func setGoal(minutes: Int) {
        self.dailyGoalMinutes = minutes
    }
    
    func completeOnboarding() {
        self.hasCompletedOnboarding = true
    }
    
    func refreshData() {
        self.isDailyGoalMet = userDefaults.bool(forKey: "isDailyGoalMet")
        self.currentStreak = userDefaults.integer(forKey: "currentStreak")
    }
}
