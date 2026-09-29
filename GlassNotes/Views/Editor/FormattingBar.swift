import SwiftUI

public struct FormattingBar: View {
    @Binding public var text: String
    
    public init(text: Binding<String>) {
        self._text = text
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FormatButton(icon: "number", label: "Heading") { insert("# ") }
                FormatButton(icon: "bold", label: "Bold") { insertAround("**") }
                FormatButton(icon: "italic", label: "Italic") { insertAround("*") }
                FormatButton(icon: "list.bullet", label: "List") { insert("\n- ") }
                FormatButton(icon: "checkmark.square", label: "Task") { insert("\n- [ ] ") }
                FormatButton(icon: "chevron.left.forwardslash.chevron.right", label: "Code") { insertAround("`") }
                FormatButton(icon: "quote.opening", label: "Quote") { insert("\n> ") }
                FormatButton(icon: "link", label: "Link") { insert("[Title](url)") }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.2), lineWidth: 1))
        )
    }
    
    private func insert(_ string: String) {
        text.append(string)
    }
    
    private func insertAround(_ token: String) {
        text.append("\(token)text\(token)")
    }
}

struct FormatButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.12))
            .cornerRadius(8)
        }
    }
}
