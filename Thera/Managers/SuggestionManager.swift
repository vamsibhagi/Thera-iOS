import Foundation
import Combine
import SwiftUI

class SuggestionManager: ObservableObject {
    static let shared = SuggestionManager()
    
    // MARK: - Publishers
    @Published var contextSuggestions: [SuggestionContext: [Suggestion]] = [:]
    
    // MARK: - Private State
    private var allSuggestions: [Suggestion] = []
    private var userVotes: [UserVote] = []
    private let userDefaults = UserDefaults(suiteName: "group.com.thera.app") ?? .standard
    private let votesKey = "UserVotes"
    private let customSuggestionsKey = "CustomSuggestions_V1" 
    
    // MARK: - Custom Suggestions State
    @Published var customSuggestions: [CustomSuggestion] = []
    
    // Config
    private let suggestionsPerContext = 4
    
    private init() {
        ensureAppGroupDirExists()
        loadVotes()
        loadSuggestions()
        loadCustomSuggestions()
    }
    
    // MARK: - Public API
    
    /// Call this every time the Home Screen appears or refreshes
    func refreshSuggestions(preference: SuggestionPreference) {
        var newGrouped: [SuggestionContext: [Suggestion]] = [:]
        
        let blockedIds = getBlockedSuggestionIds()
        
        for context in SuggestionContext.allCases {
            // Reverting to curated suggestions ONLY for the context sections on Home
            var candidates = allSuggestions.filter { $0.context == context }
            
            // Apply Mode Preference
            let modeVal: String
            switch preference {
            case .onPhone: modeVal = "on_phone"
            case .offPhone: modeVal = "off_phone"
            case .mix: modeVal = "mixed"
            }
            
            if modeVal != "mixed" {
                candidates = candidates.filter { $0.mode.rawValue == modeVal }
            }
            
            // Filter by Enabled state & Blocks
            candidates = candidates.filter { ($0.enabled ?? true) && !blockedIds.contains($0.id) }
            
            // Random Sample
            let selected = Array(candidates.shuffled().prefix(suggestionsPerContext))
            newGrouped[context] = selected
        }
        
        self.contextSuggestions = newGrouped
    }
    
    /// Handle User Vote
    func recordVote(suggestionId: String, voteType: VoteType) {
        let vote = UserVote(
            userId: getCurrentUserId(),
            suggestionId: suggestionId,
            voteType: voteType,
            timestamp: Date()
        )
        
        userVotes.append(vote)
        saveVotes()
        
        // If thumbs down, we should probably remove it immediately from the current view?
        // OR wait for next refresh.
    }
    
    // MARK: - Custom Suggestions API
    
    func addCustomSuggestion(text: String, emoji: String) {
        let newSuggestion = CustomSuggestion(
            id: UUID(),
            text: text,
            emoji: emoji
        )
        customSuggestions.append(newSuggestion)
        saveCustomSuggestions()
    }
    
    func deleteCustomSuggestion(id: UUID) {
        customSuggestions.removeAll { $0.id == id }
        saveCustomSuggestions()
    }
    
    private func loadCustomSuggestions() {
        // We use a shared file in App Group for Extension access
        guard let url = getSharedCustomSuggestionsURL() else { return }
        
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([CustomSuggestion].self, from: data) {
            self.customSuggestions = decoded
        }
    }
    
    private func saveCustomSuggestions() {
        guard let url = getSharedCustomSuggestionsURL() else { return }
        
        if let data = try? JSONEncoder().encode(customSuggestions) {
            try? data.write(to: url)
        }
    }
    
    private func getSharedCustomSuggestionsURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.thera.app")?
            .appendingPathComponent("Library/Application Support", isDirectory: true)
            .appendingPathComponent("custom_suggestions.json")
    }
    
    // Ensure the directory exists
    private func ensureAppGroupDirExists() {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.thera.app")?
            .appendingPathComponent("Library/Application Support", isDirectory: true) else { return }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    // Update init to ensure dir
    // (Already updated init to call load, but let's call ensure first)

    
    func isSuggestionBlocked(_ suggestionId: String) -> Bool {
        return getBlockedSuggestionIds().contains(suggestionId)
    }
    
    // MARK: - Data Loading
    
    private func loadSuggestions() {
        // We use "suggested_tasks" because it is already added to the Xcode project bundle.
        if let url = Bundle.main.url(forResource: "suggested_tasks", withExtension: "json") {
             do {
                 let data = try Data(contentsOf: url)
                 let decoded = try JSONDecoder().decode([Suggestion].self, from: data)
                 self.allSuggestions = decoded
                 print("DEBUG: Loaded \(decoded.count) suggestions from JSON.")
             } catch {
                 print("Error loading suggestions from JSON: \(error)")
                 self.allSuggestions = []
             }
         } else {
             print("Error: Could not find suggested_tasks.json in Bundle.")
             self.allSuggestions = []
         }
    }
    
    private func loadVotes() {
        if let data = userDefaults.data(forKey: votesKey) {
            if let decoded = try? JSONDecoder().decode([UserVote].self, from: data) {
                self.userVotes = decoded
                return
            }
        }
        self.userVotes = []
    }
    
    private func saveVotes() {
        if let data = try? JSONEncoder().encode(userVotes) {
            userDefaults.set(data, forKey: votesKey)
        }
    }
    
    // MARK: - Helpers
    
    private func getBlockedSuggestionIds() -> Set<String> {
        // IDs that have received a thumbs down
        let blocked = userVotes
            .filter { $0.voteType == .thumbsDown }
            .map { $0.suggestionId }
        return Set(blocked)
    }
    
    private func getCurrentUserId() -> String {
        // Simple persistent ID for this install
        let key = "TheraUserID"
        if let id = userDefaults.string(forKey: key) {
            return id
        }
        let newId = UUID().uuidString
        userDefaults.set(newId, forKey: key)
        return newId
    }
}
