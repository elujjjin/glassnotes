import SwiftUI

struct NoteCardView: View {
    let note: Note
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 6) {
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.yellow)
                    }
                    Text(cardTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    if note.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    if note.isDraft {
                        Text("Draft")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    Text(note.formattedDate)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }

                if !note.isLocked {
                    Text(note.snippet)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                // Multi-tag pills (up to 3 shown)
                if !note.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(note.tags.prefix(3)) { tag in
                            HStack(spacing: 3) {
                                Image(systemName: tag.iconName)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(tag.color)
                                Text(tag.name)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(tag.color.opacity(0.15))
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(tag.color.opacity(0.3), lineWidth: 0.5))
                        }
                        if note.tags.count > 3 {
                            Text("+\(note.tags.count - 3)")
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .padding(14)
            .liquidGlass(GlassConfig(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    /// A locked note must not leak its body. `displayTitle` falls back to the
    /// first line of the content, which is exactly what a locked note without a
    /// title would show on its card.
    private var cardTitle: String {
        let trimmedTitle = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if note.isLocked, trimmedTitle.isEmpty { return "Locked note" }
        return note.displayTitle
    }
}
