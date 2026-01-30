import SwiftUI

struct AddCustomSuggestionView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var text: String = ""
    @State private var emoji: String = "✨"
    
    // Simple emoji list for picker
    let commonEmojis = ["✨", "🧘", "🚶", "📚", "💧", "🍎", "✍️", "🎨", "🎸", "🌱", "🛌", "🧹", "💻", "📱"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("New Idea")) {
                    Picker("Emoji", selection: $emoji) {
                        ForEach(commonEmojis, id: \.self) { e in
                            Text(e).tag(e)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    TextField("What should we suggest?", text: $text)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Add to My List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func save() {
        SuggestionManager.shared.addCustomSuggestion(
            text: text,
            emoji: emoji
        )
    }
}
