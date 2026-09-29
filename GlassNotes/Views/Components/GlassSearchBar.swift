import SwiftUI

struct GlassSearchBar: View {
    @Binding var text: String
    var placeholder = "Search notes..."

    init(text: Binding<String>, placeholder: String = "Search notes...") {
        self._text = text
        self.placeholder = placeholder
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 15, weight: .medium))

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .liquidGlass(GlassConfig.field)
    }
}

