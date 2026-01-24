import SwiftUI

struct OnboardingTaskPreferencesView: View {
    @Binding var currentStep: Int
    @EnvironmentObject var persistenceManager: PersistenceManager
    
    // Categorized Pre-defined Suggestions
    let phoneSuggestions = [
        "Learn a new word (Browser)",
        "Duolingo lesson",
        "Read a random article",
        "Check your calendar",
        "Write a quick note"
    ]
    
    let offPhoneSuggestions = [
        "Say hi to someone nearby",
        "Make a cup of tea",
        "Stretch for a minute",
        "Step outside for a minute",
        "Drink a glass of water"
    ]
    
    @State private var selectedSuggestions: Set<String> = []
    @State private var customTaskText: String = ""
    @State private var customTasks: [(text: String, isOnPhone: Bool)] = []
    @State private var selectedPreference: SuggestionPreference = .mix
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("How do you want to pause?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                Text("Thera will suggest quick alternatives to your phone habits.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 30) {
                    
                    // Section 1: Preference
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Where do you want to spend your time?")
                            .font(.headline)
                        
                        Picker("Preference", selection: $selectedPreference) {
                            ForEach(SuggestionPreference.allCases, id: \.self) { pref in
                                Text(pref.rawValue).tag(pref)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.horizontal)
                    
                    // Section 2: On-Phone Suggestions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("On-phone activities")
                            .font(.headline)
                        Text("Productive uses for your device")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        OnboardingFlowLayout(items: phoneSuggestions) { suggestion in
                            SuggestionToggle(text: suggestion, isSelected: selectedSuggestions.contains(suggestion)) {
                                toggleSuggestion(suggestion)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Section 3: Off-Phone Suggestions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Off-phone activities")
                            .font(.headline)
                        Text("Moments away from the screen")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        OnboardingFlowLayout(items: offPhoneSuggestions) { suggestion in
                            SuggestionToggle(text: suggestion, isSelected: selectedSuggestions.contains(suggestion)) {
                                toggleSuggestion(suggestion)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Section 4: Personal Ideas
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your own ideas")
                            .font(.headline)
                        
                        HStack {
                            TextField("Go for a run...", text: $customTaskText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button(action: { addCustomTask(isOnPhone: false) }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                        }
                        
                        if !customTasks.isEmpty {
                            ForEach(customTasks.indices, id: \.self) { index in
                                HStack {
                                    Text(customTasks[index].text)
                                    Spacer()
                                    Text(customTasks[index].isOnPhone ? "On-phone" : "Off-phone")
                                        .font(.caption2)
                                        .padding(4)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(4)
                                }
                                .padding(8)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            
            Spacer()
            
            // Continue Button
            Button(action: {
                savePreferences()
                currentStep += 1
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .onAppear {
            // Default selections
            selectedSuggestions.insert(offPhoneSuggestions[1]) // Tea
            selectedSuggestions.insert(phoneSuggestions[0]) // Word
        }
    }
    
    func toggleSuggestion(_ text: String) {
        if selectedSuggestions.contains(text) {
            selectedSuggestions.remove(text)
        } else {
            selectedSuggestions.insert(text)
        }
    }
    
    func addCustomTask(isOnPhone: Bool) {
        guard !customTaskText.isEmpty else { return }
        customTasks.append((text: customTaskText, isOnPhone: isOnPhone))
        customTaskText = ""
    }
    
    func savePreferences() {
        persistenceManager.suggestionPreference = selectedPreference
        
        // Save selected pre-defined tasks
        for text in selectedSuggestions {
            let isOnPhone = phoneSuggestions.contains(text)
            // Try to match with Database if possible, or create custom
            if let dbTask = TaskDatabase.allTasks.first(where: { $0.text == text }) {
                persistenceManager.addTask(dbTask)
            } else {
                let task = TaskItem(
                    id: UUID().uuidString,
                    text: text,
                    suggestionCategory: isOnPhone ? .onPhone : .offPhone,
                    activityType: "Onboarding Selection",
                    url: isOnPhone ? guessURL(for: text) : nil,
                    isTheraSuggested: true
                )
                persistenceManager.addTask(task)
            }
        }
        
        // Save custom tasks
        for custom in customTasks {
            let task = TaskItem(
                id: UUID().uuidString,
                text: custom.text,
                suggestionCategory: custom.isOnPhone ? .onPhone : .offPhone,
                activityType: "Personal",
                url: nil,
                isTheraSuggested: false
            )
            persistenceManager.addTask(task)
        }
    }
    
    func guessURL(for text: String) -> String? {
        if text.contains("Duolingo") { return "https://www.duolingo.com/" }
        if text.contains("Wikipedia") { return "https://en.wikipedia.org/wiki/Special:Random" }
        if text.contains("Calendar") { return "calshow://" }
        if text.contains("Note") { return "mobilenotes://" }
        return nil
    }
}

struct SuggestionToggle: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(UIColor.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct OnboardingFlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content
    
    var body: some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(items, id: \.self) { item in
                    content(item)
                        .padding([.horizontal, .vertical], 4)
                        .alignmentGuide(.leading, computeValue: { d in
                            if (abs(width - d.width) > geo.size.width) {
                                width = 0
                                height -= d.height
                            }
                            let result = width
                            if item == items.last {
                                width = 0 // last item
                            } else {
                                width -= d.width
                            }
                            return result
                        })
                        .alignmentGuide(.top, computeValue: { d in
                            let result = height
                            if item == items.last {
                                height = 0 // last item
                            }
                            return result
                        })
                }
            }
        }
        .frame(minHeight: 100) // Rough height estimate
    }
}

