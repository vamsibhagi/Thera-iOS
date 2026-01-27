import Foundation
import Combine

class SuggestionManager: ObservableObject {
    static let shared = SuggestionManager()
    
    // MARK: - Publishers
    @Published var contextSuggestions: [SuggestionContext: [Suggestion]] = [:]
    
    // MARK: - Private State
    private var allSuggestions: [Suggestion] = []
    private var userVotes: [UserVote] = []
    private let userDefaults = UserDefaults(suiteName: "group.com.thera.app") ?? .standard
    private let votesKey = "UserVotes"
    
    // Config
    private let suggestionsPerContext = 4
    
    private init() {
        loadVotes()
        loadSuggestions()
    }
    
    // MARK: - Public API
    
    /// Call this every time the Home Screen appears or refreshes
    func refreshSuggestions(preference: SuggestionPreference) {
        var newGrouped: [SuggestionContext: [Suggestion]] = [:]
        
        let blockedIds = getBlockedSuggestionIds()
        
        for context in SuggestionContext.allCases {
            // 1. Filter by Context
            var candidates = allSuggestions.filter { $0.context == context }
            
            // 2. Filter by Preference
            switch preference {
            case .onPhone:
                candidates = candidates.filter { $0.mode == .onPhone }
            case .offPhone:
                candidates = candidates.filter { $0.mode == .offPhone }
            case .mix:
                break // No mode filter
            }
            
            // 3. Filter by Enabled state & Blocks
            candidates = candidates.filter { ($0.enabled ?? true) && !blockedIds.contains($0.id) }
            
            // 4. Random Sample
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
        // For now, let's just save. The UI might want to hide it immediately.
    }
    
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
