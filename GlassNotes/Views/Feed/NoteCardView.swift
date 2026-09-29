import SwiftUI

public struct NoteCardView: View {
    public let note: Note
    public let onTap: () -> Void
    
    public init(note: Note, onTap: @escaping () -> Void) {
        self.note = note
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            GlassCard(cornerRadius: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        Text(note.displayTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if note.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.yellow)
                        }
                        
                        if note.isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.cyan)
                        }
                    }
                    
                    if note.isLocked {
                        HStack(spacing: 6) {
                            Image(systemName: "eye.slash.fill")
                            Text("Locked Note (Tap to unlock)")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.vertical, 4)
                    } else {
                        Text(note.snippet)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                    
                    HStack {
                        if let tag = note.tag {
                            HStack(spacing: 4) {
                                Image(systemName: tag.iconName)
                                Text(tag.name)
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(tag.color.opacity(0.3))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text(note.formattedDate)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
