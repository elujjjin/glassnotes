import SwiftUI

struct FormattingBar: View {
    @Binding var text: String

    private let tools: [(icon: String, label: String, snippet: String, isBlock: Bool)] = [
        ("number", "Heading", "# ", false),
        ("bold", "Bold", "****", false),
        ("italic", "Italic", "**", false),
        ("list.bullet", "List", "- ", true),
        ("checkmark.square", "Task", "- [ ] ", true),
        ("chevron.left.forwardslash.chevron.right", "Code", "``", false),
        ("quote.opening", "Quote", "> ", true),
        ("link", "Link", "[text](url)", false)
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(tools, id: \.label) { tool in
                    Button {
                        insert(tool.snippet, isBlock: tool.isBlock)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: tool.icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(tool.label)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.07))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .liquidGlass(GlassConfig(cornerRadius: 14))
    }

    private func insert(_ snippet: String, isBlock: Bool) {
        if isBlock, !text.isEmpty, !text.hasSuffix("\n") {
            text.append("\n")
        }
        text.append(snippet)
    }
}
