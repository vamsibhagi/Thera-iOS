import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    @EnvironmentObject var persistenceManager: PersistenceManager
    
    var body: some View {
        HStack {
            // Checkbox
            Button(action: {
                withAnimation {
                    persistenceManager.completeTask(task)
                }
            }) {
                Image(systemName: "circle")
                    .font(.title2)
                    .foregroundColor(task.suggestionCategory == .onPhone ? .blue : .green)
            }
            
            // Text + Link
            if let urlString = task.url, let url = URL(string: urlString) {
                Link(destination: url) {
                    Text(task.text)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
            } else {
                Text(task.text)
                    .font(.body)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Thumbs for Suggestions
            if task.isTheraSuggested {
                HStack(spacing: 12) {
                    Button(action: {
                        // Thumbs Up: Keep it (do nothing for now, maybe explicit "Keep" logic later)
                    }) {
                        Image(systemName: "hand.thumbsup")
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: {
                        withAnimation {
                            persistenceManager.removeTask(task)
                        }
                    }) {
                        Image(systemName: "hand.thumbsdown")
                            .foregroundColor(.gray)
                    }
                }
            } else {
                // Delete user task
                Button(action: {
                    withAnimation {
                        persistenceManager.removeTask(task)
                    }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
