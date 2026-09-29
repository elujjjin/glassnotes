import SwiftUI

struct GlassButton: View {
    let title: String
    var icon: String?
    var tint: Color = .white
    let action: () -> Void

    init(title: String, icon: String? = nil, tint: Color = .white, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .liquidGlass(GlassConfig(cornerRadius: 16, tint: tint, interactive: true))
        }
        .buttonStyle(.plain)
    }
}

