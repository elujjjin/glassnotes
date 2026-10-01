import SwiftUI

struct GlassButton: View {
    let title: String
    var icon: String?
    var tint: Color = .white
    /// Should mirror `SyncConfig.hapticsEnabled`; the default keeps the button
    /// usable where no config is in scope.
    var hapticsEnabled: Bool = true
    let action: () -> Void

    init(
        title: String,
        icon: String? = nil,
        tint: Color = .white,
        hapticsEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.tint = tint
        self.hapticsEnabled = hapticsEnabled
        self.action = action
    }

    var body: some View {
        Button {
            HapticsService.shared.impact(.medium, enabled: hapticsEnabled)
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

