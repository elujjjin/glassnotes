import SwiftUI

/// Markdown toolbar for the note editor.
///
/// Formatting is applied at the caret rather than appended to the end of the
/// document, and wrapping toggles are aware of the current selection: tapping
/// "Bold" around already-bold text removes the markers.
struct FormattingBar: View {
    @Binding var text: String
    @Binding var selection: NSRange
    @FocusState.Binding var isEditorFocused: Bool

    private struct Tool {
        let icon: String
        let label: String
        let snippet: String
        let kind: Kind

        enum Kind {
            case block
            case wrap
            case link
        }
    }

    private let tools: [Tool] = [
        Tool(icon: "number", label: "Heading", snippet: "# ", kind: .block),
        Tool(icon: "bold", label: "Bold", snippet: "**", kind: .wrap),
        Tool(icon: "italic", label: "Italic", snippet: "*", kind: .wrap),
        Tool(icon: "list.bullet", label: "List", snippet: "- ", kind: .block),
        Tool(icon: "checkmark.square", label: "Task", snippet: "- [ ] ", kind: .block),
        Tool(icon: "chevron.left.forwardslash.chevron.right", label: "Code", snippet: "`", kind: .wrap),
        Tool(icon: "quote.opening", label: "Quote", snippet: "> ", kind: .block),
        Tool(icon: "link", label: "Link", snippet: "[](url)", kind: .link)
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(tools, id: \.label) { tool in
                    Button {
                        apply(tool)
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
                    .accessibilityLabel(tool.label)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .liquidGlass(GlassConfig(cornerRadius: 14))
    }

    // MARK: - Editing

    private func apply(_ tool: Tool) {
        let ns = text as NSString
        let length = text.utf16.count
        let caret = min(max(0, selection.location), length)
        // Clamp the selected span so a stale range can never index out of bounds.
        let span = min(max(0, selection.length), length - caret)

        switch tool.kind {
        case .block:
            insertBlock(tool.snippet, at: caret, ns: ns)
        case .wrap:
            toggleWrap(tool.snippet, at: caret, span: span, ns: ns)
        case .link:
            insertLink(at: caret, span: span, ns: ns)
        }

        // Keep the keyboard up so formatting can be applied repeatedly.
        isEditorFocused = true
    }

    /// Prefixes the current line with a block marker such as `# ` or `- `.
    private func insertBlock(_ snippet: String, at caret: Int, ns: NSString) {
        let lineRange = ns.lineRange(for: NSRange(location: caret, length: 0))
        let lineStart = lineRange.location

        // If the caret is not already at the start of its line, open a new one
        // so the block marker does not attach to the preceding text.
        if caret > lineStart {
            let insertion = "\n" + snippet
            text = ns.replacingCharacters(in: NSRange(location: caret, length: 0), with: insertion)
            selection = NSRange(location: caret + insertion.utf16.count, length: 0)
        } else {
            text = ns.replacingCharacters(in: NSRange(location: caret, length: 0), with: snippet)
            selection = NSRange(location: caret + snippet.utf16.count, length: 0)
        }
    }

    /// Wraps the selection, or the word under the caret, in a span marker.
    /// Applying it to already-wrapped text removes the markers.
    private func toggleWrap(_ marker: String, at caret: Int, span: Int, ns: NSString) {
        if span > 0 {
            let chosen = ns.substring(with: NSRange(location: caret, length: span))
            let alreadyWrapped = chosen.hasPrefix(marker)
                && chosen.hasSuffix(marker)
                && chosen.utf16.count > marker.utf16.count * 2

            let replacement = alreadyWrapped
                ? String(chosen.dropFirst(marker.count).dropLast(marker.count))
                : marker + chosen + marker

            text = ns.replacingCharacters(in: NSRange(location: caret, length: span), with: replacement)
            selection = NSRange(location: caret, length: replacement.utf16.count)
            return
        }

        // Otherwise toggle around the word under the caret, if it is already
        // wrapped; if it is not, insert an empty pair and place the caret inside.
        let wordRange = ns.paragraphRange(for: NSRange(location: caret, length: 0))
        let line = ns.substring(with: wordRange)
        let offsetInLine = caret - wordRange.location
        let words = line.split(separator: " ", omittingEmptySubsequences: false)
        var cursorInLine = 0
        for word in words {
            let wordStart = cursorInLine
            let wordEnd = cursorInLine + word.utf16.count
            if offsetInLine >= wordStart && offsetInLine <= wordEnd {
                let text0 = String(word)
                if text0.hasPrefix(marker) && text0.hasSuffix(marker) && text0.count > marker.count * 2 {
                    let unwrapped = String(text0.dropFirst(marker.count).dropLast(marker.count))
                    text = ns.replacingCharacters(
                        in: NSRange(location: wordRange.location + wordStart, length: text0.utf16.count),
                        with: unwrapped
                    )
                    selection = NSRange(location: wordRange.location + wordStart, length: 0)
                } else {
                    let wrapped = marker + text0 + marker
                    text = ns.replacingCharacters(
                        in: NSRange(location: wordRange.location + wordStart, length: text0.utf16.count),
                        with: wrapped
                    )
                    selection = NSRange(location: wordRange.location + wordStart + marker.utf16.count, length: text0.utf16.count)
                }
                return
            }
            cursorInLine = wordEnd + 1
        }

        let insertion = marker + marker
        text = ns.replacingCharacters(in: NSRange(location: caret, length: 0), with: insertion)
        selection = NSRange(location: caret + marker.utf16.count, length: 0)
    }

    private func insertLink(at caret: Int, span: Int, ns: NSString) {
        let chosen = span > 0 ? ns.substring(with: NSRange(location: caret, length: span)) : ""
        let replacement: String
        let newCaretOffset: Int

        if chosen.isEmpty {
            replacement = "[text](url)"
            // Park the caret over "text" so it can be typed over immediately.
            newCaretOffset = caret + "[text]".utf16.count
        } else {
            replacement = "[\(chosen)](url)"
            newCaretOffset = caret + replacement.utf16.count
        }

        text = ns.replacingCharacters(
            in: NSRange(location: caret, length: chosen.utf16.count),
            with: replacement
        )
        selection = NSRange(location: newCaretOffset, length: 0)
    }
}


