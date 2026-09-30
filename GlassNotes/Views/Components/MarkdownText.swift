import SwiftUI

// MARK: - Inline tokenizer

struct MarkdownInlineToken {
    var text: String
    var isBold = false
    var isItalic = false
    var isCode = false
    var isStrikethrough = false
    var linkDestination: String?
}

enum MarkdownInline {

    /// Tokenises inline span syntax: `**strong**`, `*emphasis*`, `` `code` ``,
    /// `~~struck~~` and `[label](url)`. Code spans win over everything else, and
    /// underscore emphasis is ignored mid-word so `snake_case` survives intact.
    static func tokenize(_ source: String) -> [MarkdownInlineToken] {
        let chars = Array(source)
        var tokens: [MarkdownInlineToken] = []
        var buffer = ""

        func flush() {
            guard !buffer.isEmpty else { return }
            tokens.append(MarkdownInlineToken(text: buffer))
            buffer = ""
        }

        var i = 0
        while i < chars.count {
            let char = chars[i]

            // Inline code — the payload is never parsed again.
            if char == "`", let close = closing(chars, from: i + 1, marker: "`"), close > i + 1 {
                flush()
                var token = MarkdownInlineToken(text: String(chars[(i + 1)..<close]))
                token.isCode = true
                tokens.append(token)
                i = close + 1
                continue
            }

            // Link
            if char == "[", let link = parseLink(chars, from: i) {
                flush()
                for token in tokenize(link.label) {
                    var copy = token
                    copy.linkDestination = link.destination
                    tokens.append(copy)
                }
                i = link.nextIndex
                continue
            }

            // Strikethrough
            if char == "~", i + 1 < chars.count, chars[i + 1] == "~",
               let close = closing(chars, from: i + 2, marker: "~~"), close > i + 2 {
                flush()
                for token in tokenize(String(chars[(i + 2)..<close])) {
                    var copy = token
                    copy.isStrikethrough = true
                    tokens.append(copy)
                }
                i = close + 2
                continue
            }

            // Strong
            if (char == "*" || char == "_"), i + 1 < chars.count, chars[i + 1] == char,
               canOpen(char, at: i, in: chars),
               let close = closing(chars, from: i + 2, marker: String(repeating: String(char), count: 2)),
               close > i + 2,
               canClose(char, at: close + 1, in: chars) {
                flush()
                for token in tokenize(String(chars[(i + 2)..<close])) {
                    var copy = token
                    copy.isBold = true
                    tokens.append(copy)
                }
                i = close + 2
                continue
            }

            // Emphasis
            if char == "*" || char == "_",
               canOpen(char, at: i, in: chars),
               let close = closing(chars, from: i + 1, marker: String(char)),
               close > i + 1,
               canClose(char, at: close, in: chars) {
                flush()
                for token in tokenize(String(chars[(i + 1)..<close])) {
                    var copy = token
                    copy.isItalic = true
                    tokens.append(copy)
                }
                i = close + 1
                continue
            }

            buffer.append(char)
            i += 1
        }

        flush()
        return tokens
    }

    // MARK: Helpers

    private static func closing(_ chars: [Character], from start: Int, marker: String) -> Int? {
        let needle = Array(marker)
        guard !needle.isEmpty else { return nil }

        var i = max(0, start)
        while i + needle.count <= chars.count {
            var matched = true
            for offset in 0..<needle.count {
                if chars[i + offset] != needle[offset] {
                    matched = false
                    break
                }
            }
            if matched { return i }
            i += 1
        }
        return nil
    }

    /// `_` only opens emphasis when it is not glued to the end of a word.
    private static func canOpen(_ char: Character, at index: Int, in chars: [Character]) -> Bool {
        guard char == "_", index > 0 else { return true }
        let previous = chars[index - 1]
        return !previous.isLetter && !previous.isNumber && previous != "_"
    }

    private static func canClose(_ char: Character, at lastIndex: Int, in chars: [Character]) -> Bool {
        guard char == "_" else { return true }
        let next = lastIndex + 1
        guard next < chars.count else { return true }
        let following = chars[next]
        return !following.isLetter && !following.isNumber && following != "_"
    }

    private static func parseLink(
        _ chars: [Character],
        from start: Int
    ) -> (label: String, destination: String, nextIndex: Int)? {
        var i = start + 1
        var label = ""
        var depth = 1

        while i < chars.count {
            let char = chars[i]
            if char == "[" {
                depth += 1
            } else if char == "]" {
                depth -= 1
                if depth == 0 { break }
            }
            label.append(char)
            i += 1
        }

        guard i < chars.count, i + 1 < chars.count, chars[i + 1] == "(" else { return nil }

        var j = i + 2
        var destination = ""
        while j < chars.count, chars[j] != ")" {
            destination.append(chars[j])
            j += 1
        }
        guard j < chars.count else { return nil }

        return (
            label,
            String(destination.trimmingCharacters(in: .whitespacesAndNewlines)),
            j + 1
        )
    }
}

// MARK: - Block parser

struct MarkdownBlock {
    enum Kind {
        case heading(level: Int)
        case paragraph
        case bullet(indent: Int, checked: Bool?)
        case ordered(indent: Int, marker: String)
        case quote(indent: Int)
        case rule
        case code
    }

    var kind: Kind
    var text: String
}

enum MarkdownBlockParser {

    static func blocks(_ source: String) -> [MarkdownBlock] {
        var result: [MarkdownBlock] = []
        var paragraph: [String] = []

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            result.append(MarkdownBlock(kind: .paragraph, text: paragraph.joined(separator: " ")))
            paragraph = []
        }

        var fencedLines: [String]?

        for rawLine in source.components(separatedBy: .newlines) {
            // Inside a fenced code block everything is literal.
            if fencedLines != nil {
                if rawLine.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    result.append(MarkdownBlock(kind: .code, text: fencedLines!.joined(separator: "\n")))
                    fencedLines = nil
                } else {
                    fencedLines!.append(rawLine)
                }
                continue
            }

            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                flushParagraph()
                fencedLines = []
                continue
            }

            guard !trimmed.isEmpty else {
                flushParagraph()
                continue
            }

            let indent = (rawLine.prefix(while: { $0 == " " }).count) / 2

            // ATX heading
            if trimmed.hasPrefix("#") {
                let hashes = trimmed.prefix(while: { $0 == "#" })
                let body = trimmed.dropFirst(hashes.count)
                    .trimmingCharacters(in: .whitespaces)
                if !body.isEmpty, hashes.count <= 6 {
                    flushParagraph()
                    result.append(
                        MarkdownBlock(kind: .heading(level: hashes.count), text: String(body))
                    )
                    continue
                }
            }

            // Thematic break
            if isThematicBreak(trimmed) {
                flushParagraph()
                result.append(MarkdownBlock(kind: .rule, text: ""))
                continue
            }

            // Block quote
            if trimmed.hasPrefix(">") {
                flushParagraph()
                let body = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                result.append(MarkdownBlock(kind: .quote(indent: indent), text: String(body)))
                continue
            }

            // Ordered list
            if let ordered = orderedMarker(trimmed) {
                flushParagraph()
                result.append(
                    MarkdownBlock(
                        kind: .ordered(indent: indent, marker: ordered.marker),
                        text: ordered.body
                    )
                )
                continue
            }

            // Bulleted list, including GitHub task lists
            if let bullet = bulletMarker(trimmed) {
                flushParagraph()
                result.append(
                    MarkdownBlock(
                        kind: .bullet(indent: indent, checked: bullet.checked),
                        text: bullet.body
                    )
                )
                continue
            }

            paragraph.append(trimmed)
        }

        // An unterminated fence still renders rather than vanishing.
        if let open = fencedLines {
            result.append(MarkdownBlock(kind: .code, text: open.joined(separator: "\n")))
        }
        flushParagraph()

        return result
    }

    private static func isThematicBreak(_ line: String) -> Bool {
        let stripped = line.replacingOccurrences(of: " ", with: "")
        guard stripped.count >= 3 else { return false }
        let first = stripped.first
        guard first == "-" || first == "*" || first == "_" else { return false }
        return stripped.allSatisfy { $0 == first }
    }

    private static func orderedMarker(_ line: String) -> (marker: String, body: String)? {
        let digits = line.prefix(while: { $0.isNumber })
        guard !digits.isEmpty else { return nil }
        let remainder = line.dropFirst(digits.count)
        guard remainder.hasPrefix(". ") || remainder.hasPrefix(") ") else { return nil }
        let body = remainder.dropFirst(2).trimmingCharacters(in: .whitespaces)
        return ("\(digits).", String(body))
    }

    private static func bulletMarker(_ line: String) -> (checked: Bool?, body: String)? {
        guard let first = line.first, first == "-" || first == "*" || first == "+",
              line.dropFirst().first == " " else { return nil }

        var remainder = line.dropFirst(2)
        var checked: Bool?

        // `- [ ]` / `- [x]` task markers.
        if remainder.hasPrefix("["), remainder.count >= 4 {
            let flag = remainder.dropFirst().first
            if (flag == " " || flag == "x" || flag == "X"),
               remainder.dropFirst(2).first == "]" {
                checked = (flag != " ")
                remainder = remainder.dropFirst(3)
            }
        }

        let body = remainder.trimmingCharacters(in: .whitespaces)
        return (checked, String(body))
    }
}


// MARK: - Rendering

/// A dependency-free Markdown renderer for note previews.
///
/// Supports headings, paragraphs, bulleted/ordered/task lists, block quotes,
/// thematic breaks, fenced code, and inline span syntax. Unrecognised input
/// falls through to plain text, so arbitrary note content always renders.
struct MarkdownText: View {
    let source: String
    var baseFont: Font = .system(size: 16)
    var color: Color = .white

    private var blocks: [MarkdownBlock] { MarkdownBlockParser.blocks(source) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Index into `blocks` rather than using `\.offset` on an enumerated
            // tuple: key paths to tuple elements are not valid Swift.
            ForEach(blocks.indices, id: \.self) { index in
                view(for: blocks[index])
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func view(for block: MarkdownBlock) -> some View {
        switch block.kind {
        case .heading(let level):
            inline(block.text, baseFontOverride: headingFont(level))
                .padding(.top, level <= 2 ? 4 : 0)

        case .paragraph:
            inline(block.text)

        case .bullet(let indent, let checked):
            row(indent: indent) {
                bulletGlyph(checked: checked)
            } content: {
                inline(block.text, forceStrikethrough: checked == true)
            }

        case .ordered(let indent, let marker):
            row(indent: indent) {
                Text(marker)
                    .font(baseFont)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 22, alignment: .trailing)
            } content: {
                inline(block.text)
            }

        case .quote(let indent):
            HStack(alignment: .top, spacing: 10) {
                Capsule()
                    .fill(Color.accentColor.opacity(0.7))
                    .frame(width: 3)
                inline(block.text, forceItalic: true)
            }
            .padding(.leading, CGFloat(indent) * 16)

        case .rule:
            Rectangle()
                .fill(.white.opacity(0.12))
                .frame(height: 1)

        case .code:
            ScrollView(.horizontal, showsIndicators: false) {
                Text(block.text)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.black.opacity(0.28))
            }
        }
    }

    // MARK: Pieces

    /// Lays out a list row: an optional leading marker beside the content.
    ///
    /// Both slots are passed as closures to a single argument so the call
    /// sites stay unambiguous under result-builder inference.
    private func row<Leading: View, Content: View>(
        indent: Int,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            leading()
            content()
        }
        .padding(.leading, CGFloat(indent) * 20)
    }

    @ViewBuilder
    private func bulletGlyph(checked: Bool?) -> some View {
        if let checked {
            Image(systemName: checked ? "checkmark.square.fill" : "square")
                .font(.system(size: 13))
                .foregroundStyle(checked ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.secondary))
        } else {
            Circle()
                .fill(.secondary)
                .frame(width: 5, height: 5)
                .padding(.bottom, 1)
        }
    }

    /// Builds one `AttributedString` from the inline tokens, so a single `Text`
    /// renders mixed styles and keeps real links tappable.
    ///
    /// - Parameter baseFontOverride: the font to build from. Headings pass their
    ///   own font here rather than applying `.font()` to the returned `Text`,
    ///   because a run-level `font` attribute in an `AttributedString` takes
    ///   precedence over any view-level font and would silently win.
    private func inline(
        _ text: String,
        baseFontOverride: Font? = nil,
        forceItalic: Bool = false,
        forceStrikethrough: Bool = false
    ) -> Text {
        let effectiveFont = baseFontOverride ?? baseFont
        var result = AttributedString()

        for token in MarkdownInline.tokenize(text) {
            var piece = AttributedString(token.text)
            let strike = token.isStrikethrough || forceStrikethrough

            if token.isCode {
                piece.font = .system(size: 15, design: .monospaced)
                piece.backgroundColor = .white.opacity(0.10)
                piece.foregroundColor = .white.opacity(0.92)
            } else {
                var font: Font = effectiveFont
                if forceItalic { font = font.italic() }
                if token.isBold { font = font.bold() }
                if token.isItalic { font = font.italic() }
                piece.font = font
            }

            if strike { piece.strikethroughStyle = .single }

            if let destination = token.linkDestination,
               let url = URL(string: destination) {
                piece.link = url
                piece.foregroundColor = Color.accentColor
                piece.underlineStyle = .single
            }

            if piece.foregroundColor == nil {
                piece.foregroundColor = color
            }

            result.append(piece)
        }

        if result.characters.isEmpty {
            return Text("")
        }
        return Text(result)
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .system(size: 24, weight: .bold)
        case 2: return .system(size: 20, weight: .bold)
        case 3: return .system(size: 18, weight: .semibold)
        default: return .system(size: 16, weight: .semibold)
        }
    }
}

