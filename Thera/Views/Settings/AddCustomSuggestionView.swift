import SwiftUI

struct AddCustomSuggestionView: View {
    @Environment(\.dismiss) var dismiss
    let context: SuggestionContext
    
    @State private var text: String = ""
    @State private var emoji: String = "✨"
    @State private var mode: SuggestionMode = .offPhone
    
    // Simple emoji list for picker
    let commonEmojis = ["✨", "🧘", "🚶", "📚", "💧", "🍎", "✍️", "🎨", "🎸", "🌱", "🛌", "🧹", "💻", "📱"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details for \(context.displayName)")) {
                    Picker("Emoji", selection: $emoji) {
                        ForEach(commonEmojis, id: \.self) { e in
                            Text(e).tag(e)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    TextField("What should we suggest?", text: $text)
                        .autocorrectionDisabled()
                    
                    Picker("Activity Type", selection: $mode) {
                        Text("Off-phone").tag(SuggestionMode.offPhone)
                        Text("On-phone").tag(SuggestionMode.onPhone)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Add Suggestion")
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
            emoji: emoji,
            mode: mode,
            context: context
        )
    }
}
