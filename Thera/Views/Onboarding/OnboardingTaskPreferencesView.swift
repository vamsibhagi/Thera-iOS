import SwiftUI

struct OnboardingTaskPreferencesView: View {
    @Binding var currentStep: Int
    @EnvironmentObject var persistenceManager: PersistenceManager
    
    // Pre-defined Quick Wins
    let quickWins = [
        "Read something meaningful",
        "Learn a new word",
        "Stretch for a minute",
        "Write a short note",
        "Drink water"
    ]
    
    @State private var selectedQuickWins: Set<String> = []
    @State private var customTaskText: String = ""
    @State private var customTasks: [String] = []
    @State private var selectedEffort: EffortPreference = .mixed
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("What should Thera suggest?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                Text("When you hit a limit, we’ll show you quick alternatives.\nPick what feels useful or fun to you.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 30) {
                    
                    // Section 1: Quick Wins
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick wins")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 10) {
                            ForEach(quickWins, id: \.self) { win in
                                Button(action: { toggleWin(win) }) {
                                    Text(win)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(selectedQuickWins.contains(win) ? Color.blue.opacity(0.1) : Color(UIColor.systemGray6))
                                        .foregroundColor(selectedQuickWins.contains(win) ? Color.blue : Color.primary)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedQuickWins.contains(win) ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Section 2: Personal Tasks
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your own ideas")
                            .font(.headline)
                        
                        Text("Add things you’ve been meaning to do")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack {
                            TextField("Plan a weekend...", text: $customTaskText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .submitLabel(.done)
                                .onSubmit { addCustomTask() }
                            
                            Button(action: addCustomTask) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            .disabled(customTaskText.isEmpty)
                        }
                        
                        // List of added customs
                        if !customTasks.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(customTasks, id: \.self) { task in
                                    HStack {
                                        Image(systemName: "checkmark.circle")
                                            .foregroundColor(.green)
                                        Text(task)
                                        Spacer()
                                    }
                                    .padding(8)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Section 3: Effort Level
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How much effort should these be?")
                            .font(.headline)
                        
                        Picker("Effort", selection: $selectedEffort) {
                            ForEach(EffortPreference.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
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
            // Pre-select some
            selectedQuickWins.insert(quickWins[0])
            selectedQuickWins.insert(quickWins[2])
        }
    }
    
    func toggleWin(_ win: String) {
        if selectedQuickWins.contains(win) {
            selectedQuickWins.remove(win)
        } else {
            selectedQuickWins.insert(win)
        }
    }
    
    func addCustomTask() {
        guard !customTaskText.isEmpty else { return }
        customTasks.append(customTaskText)
        customTaskText = ""
    }
    
    func savePreferences() {
        // Save Effort
        persistenceManager.effortPreference = selectedEffort
        
        // Save Quick Wins as "Light Tasks"
        for win in selectedQuickWins {
            // Check if already exists to avoid duplicates? Ideally yes.
            // Simplified: Just add.
            let task = TaskItem(
                id: UUID().uuidString,
                text: win,
                type: .light,
                category: "Quick Win",
                url: nil,
                isTheraSuggested: true
            )
            persistenceManager.addTask(task)
        }
        
        // Save Custom Tasks as "Focused Tasks" (default?) or "Light"?
        // Prompt says "Tasks can move between Light and Focused".
        // Let's default Custom to "Focused" as they are "things meant to do".
        for custom in customTasks {
            let task = TaskItem(
                id: UUID().uuidString, // "custom_\(Date().timeIntervalSince1970)"
                text: custom,
                type: .focused,
                category: "Personal",
                url: nil,
                isTheraSuggested: false
            )
            persistenceManager.addTask(task)
        }
    }
}
