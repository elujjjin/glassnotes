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

    /// Called with the current config whenever the user changes the timer.
    func checkAutoLock(autoLockMinutes: Int = 0, auth: BiometricAuthService) {
        guard autoLockMinutes > 0, let bg = backgroundedAt else { return }
        let elapsed = Date().timeIntervalSince(bg) / 60
        if elapsed >= Double(autoLockMinutes) {
            auth.lock()
        }
        backgroundedAt = nil
    }

    private func checkAutoLock() {
        // The foreground notification fires before the view hierarchy updates,
        // so post a deferred notification for the view layer to handle.
        NotificationCenter.default.post(name: .autoLockCheck, object: backgroundedAt)
    }
}

extension Notification.Name {
    static let autoLockCheck = Notification.Name("com.glassnotes.autoLockCheck")
}
