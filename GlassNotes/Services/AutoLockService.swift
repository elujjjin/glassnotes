import Foundation
import Combine
import UIKit

/// Watches app-lifecycle notifications and locks the auth service after
/// the user-configured idle timeout.
@MainActor
final class AutoLockService: ObservableObject {
    private var backgroundedAt: Date?
    private var cancellables: Set<AnyCancellable> = []

    init() {
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.backgroundedAt = Date()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.checkAutoLock()
            }
            .store(in: &cancellables)
    }

    /// Hands the background timestamp to the view layer, which owns the
    /// configured timeout (it lives in SwiftData, not here), then clears it.
    ///
    /// Clearing is essential: without it the first recorded timestamp is never
    /// replaced, so the elapsed time is measured from the *first* backgrounding
    /// of the session rather than the most recent one, and the app re-locks
    /// earlier than the user asked for.
    private func checkAutoLock() {
        // The foreground notification fires before the view hierarchy updates,
        // so post a deferred notification for the view layer to handle.
        NotificationCenter.default.post(name: .autoLockCheck, object: backgroundedAt)
        backgroundedAt = nil
    }
}

extension Notification.Name {
    static let autoLockCheck = Notification.Name("com.glassnotes.autoLockCheck")
}
