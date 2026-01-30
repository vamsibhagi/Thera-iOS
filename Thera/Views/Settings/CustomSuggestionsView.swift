import SwiftUI

struct CustomSuggestionsView: View {
    @ObservedObject var suggestionManager = SuggestionManager.shared
    @State private var selectedContextForAdd: SuggestionContext?
    
    var body: some View {
        List {
            ForEach(SuggestionContext.allCases, id: \.self) { context in
                Section(header: contextHeader(context)) {
                    let suggestions = suggestionManager.customSuggestions.filter { $0.context == context }
                    
                    if suggestions.isEmpty {
                        Text("No custom suggestions for this moment yet.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(suggestions) { suggestion in
                            HStack {
                                Text(suggestion.emoji)
                                    .font(.title3)
                                VStack(alignment: .leading) {
                                    Text(suggestion.text)
                                        .font(.body)
                                    Text(suggestion.mode == .onPhone ? "On-phone" : "Off-phone")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    suggestionManager.deleteCustomSuggestion(id: suggestion.id)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red.opacity(0.8))
                                        .font(.subheadline)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("My Suggestions")
        .sheet(item: $selectedContextForAdd) { context in
            AddCustomSuggestionView(context: context)
        }
    }
    
    private func contextHeader(_ context: SuggestionContext) -> some View {
        HStack {
            Text(context.displayName)
            Spacer()
            Button(action: { selectedContextForAdd = context }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func deleteSuggestion(at offsets: IndexSet, in context: SuggestionContext) {
        let suggestionsForContext = suggestionManager.customSuggestions.filter { $0.context == context }
        for index in offsets {
            let suggestion = suggestionsForContext[index]
            suggestionManager.deleteCustomSuggestion(id: suggestion.id)
        }
    }
}

extension SuggestionContext: Identifiable {
    public var id: String { self.rawValue }
}
