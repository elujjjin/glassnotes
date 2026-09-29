import SwiftUI

public struct GlassSearchBar: View {
    @Binding public var text: String
    public var placeholder: String = "Search notes..."
    
    public init(text: Binding<String>, placeholder: String = "Search notes...") {
        self._text = text
        self.placeholder = placeholder
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.7))
                .font(.system(size: 17, weight: .medium))
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.45)))
                .foregroundColor(.white)
                .accentColor(.cyan)
            
            if !$text.wrappedValue.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        )
    }
}
