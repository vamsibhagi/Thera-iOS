import SwiftUI
import FamilyControls
import DeviceActivity
import ManagedSettings

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var persistenceManager: PersistenceManager
    @EnvironmentObject var screenTimeManager: TheraScreenTimeManager
    
    @State private var isPickerPresented = false
    @State private var newLikeText = ""
    @State private var newDislikeText = ""
    
    var body: some View {
        Form {
            // MARK: - SECTION 1: DISTRACTING APPS
            Section(header: Text("Distracting Apps")) {
                Button(action: { isPickerPresented = true }) {
                    HStack {
                        Text("Edit App List")
                        Spacer()
                        Text("\(screenTimeManager.distractingSelection.applicationTokens.count) selected")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // MARK: - SECTION 2: TIME LIMITS
            Section(header: Text("Time Limits")) {
                if screenTimeManager.distractingSelection.applicationTokens.isEmpty {
                    Text("No apps selected")
                        .foregroundColor(.gray)
                } else {
                    ForEach(Array(screenTimeManager.distractingSelection.applicationTokens), id: \.self) { token in
                        SettingsAppLimitRow(token: token, limit: limitBinding(for: token))
                    }
                }
            }
            
            // MARK: - SECTION 3: TOPICS
            Section(header: Text("Topics"), footer: Text("We use this to suggest better tasks.")) {
                // Likes
                VStack(alignment: .leading) {
                    Text("Likes")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if persistenceManager.topics.filter({ $0.isLiked }).isEmpty {
                        Text("None yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        FlowLayout(items: persistenceManager.topics.filter { $0.isLiked }) { topic in
                            TopicBubble(topic: topic) {
                                persistenceManager.topics.removeAll { $0.id == topic.id }
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Add like...", text: $newLikeText)
                            .onSubmit { addTopic(isLiked: true) }
                        Button(action: { addTopic(isLiked: true) }) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newLikeText.isEmpty)
                    }
                }
                .padding(.vertical, 8)
                
                // Dislikes
                VStack(alignment: .leading) {
                    Text("Dislikes")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if persistenceManager.topics.filter({ !$0.isLiked }).isEmpty {
                        Text("None yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        FlowLayout(items: persistenceManager.topics.filter { !$0.isLiked }) { topic in
                            TopicBubble(topic: topic) {
                                persistenceManager.topics.removeAll { $0.id == topic.id }
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Add dislike...", text: $newDislikeText)
                            .onSubmit { addTopic(isLiked: false) }
                        Button(action: { addTopic(isLiked: false) }) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newDislikeText.isEmpty)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Settings")
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $screenTimeManager.distractingSelection)
        .onChange(of: screenTimeManager.distractingSelection) {
            save()
        }
        .onDisappear {
            save()
        }
    }
    
    func limitBinding(for token: ApplicationToken) -> Binding<Int> {
        return Binding(
            get: { persistenceManager.getLimit(for: token) },
            set: { persistenceManager.setLimit(for: token, minutes: $0) }
        )
    }
    
    func addTopic(isLiked: Bool) {
        let text = isLiked ? newLikeText : newDislikeText
        guard !text.isEmpty else { return }
        
        // Check duplication?
        let topic = Topic(text: text, isLiked: isLiked)
        persistenceManager.topics.append(topic)
        
        if isLiked { newLikeText = "" } else { newDislikeText = "" }
    }
    
    func save() {
        TheraScreenTimeManager.shared.saveSelectionsAndSchedule(appLimits: persistenceManager.appLimits)
    }
}

// Helper: Bubble UI
struct TopicBubble: View {
    let topic: Topic
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(topic.text)
                .font(.caption)
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(topic.isLiked ? Color.blue.opacity(0.1) : Color.red.opacity(0.1))
        .foregroundColor(topic.isLiked ? .blue : .red)
        .cornerRadius(12)
    }
}

// Helper: Flow Layout (Simple implementation)
struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let items: Data
    let content: (Data.Element) -> Content
    
    var body: some View {
        // Simple horizontal scroll for now
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(items) { item in
                    content(item)
                }
            }
        }
    }
}

// Helper: Limit Row
struct SettingsAppLimitRow: View {
    let token: ApplicationToken
    @Binding var limit: Int
    @State private var filter = DeviceActivityFilter()
    
    let allowedLimits = [5, 10, 15, 20, 25, 30, 45, 60, 75, 90, 105, 120]
    
    var body: some View {
        HStack {
            Label(token)
                .labelStyle(.iconOnly)
            
            VStack(alignment: .leading) {
                Label(token)
                    .labelStyle(.titleOnly)
                    .font(.body)
                
                // DeviceActivityReport(.miniUsage, filter: filter) // iOS 26: miniUsage removed
                //     .frame(height: 15)
            }
            
            Spacer()
            
            Menu {
                ForEach(allowedLimits, id: \.self) { val in
                    Button("\(val) min") {
                        limit = val
                    }
                }
            } label: {
                Text("\(limit) m")
                    .foregroundColor(.blue)
            }
        }
        .onAppear {
             filter = DeviceActivityFilter(
                segment: .daily(during: Calendar.current.dateInterval(of: .day, for: Date())!),
                users: .all,
                devices: .init([.iPhone, .iPad]),
                applications: Set([token]),
                categories: Set()
            )
        }
    }
}
