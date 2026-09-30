import UIKit
import SwiftUI

/// Thin wrapper around UIKit feedback generators.
/// Callers should pass the result of `SyncConfig.hapticsEnabled`; when
/// `enabled` is false the call is a no-op.
@MainActor
final class HapticsService: ObservableObject {
    // Shared instance so views can access it without environment injection
    // in situations where EnvironmentObject isn't convenient.
    static let shared = HapticsService()

    private init() {}

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, enabled: Bool = true) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType, enabled: Bool = true) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    func selection(enabled: Bool = true) {
        guard enabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
