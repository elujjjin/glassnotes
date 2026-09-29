import SwiftUI

struct NoteCardView: View {
    let note: Note
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            GlassCard(cornerRadius: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(note.displayTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .lineLimit(1)
                            .foregroundStyle(.white)

                        if note.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        if note.isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)
                    }

                    if note.isLocked {
                        Text("Locked — open to reveal")
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                    } else {
                        Text(note.snippet)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }

                    HStack(spacing: 6) {
                        if let tag = note.tag {
                            Label(tag.name, systemImage: tag.iconName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(tag.color)
                        }
                        Spacer()
                        Text(note.formattedDate)
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
