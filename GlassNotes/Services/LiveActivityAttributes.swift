import Foundation
import ActivityKit

/// ActivityKit attributes for tracking a multi-part Telegram send from the Dynamic Island.
public struct TelegramSendAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var partsSent: Int
        public var totalParts: Int
        public var status: String

        public init(partsSent: Int, totalParts: Int, status: String) {
            self.partsSent = partsSent
            self.totalParts = totalParts
            self.status = status
        }
    }

    public var noteTitle: String

    public init(noteTitle: String) {
        self.noteTitle = noteTitle
    }
}

/// Drives the Live Activity shown while a long note is split across several
/// Telegram messages.
///
/// Every call is a no-op when Live Activities are unavailable (pre-iOS 16.1, no
/// ActivityKit authorisation, or the user switched them off in Settings), so
/// callers never need to check availability themselves.
@MainActor
enum TelegramSendActivity {
    /// iOS shows its own "Live Activity" toggle in Settings; without a matching
    /// `NSSupportsLiveActivities` key in Info.plist, `request` throws.
    private static var isEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    private static var activity: Activity<TelegramSendAttributes>?

    /// Starts (or replaces) the activity for a send of `totalParts` messages.
    static func start(noteTitle: String, totalParts: Int) {
        guard isEnabled else { return }
        let attributes = TelegramSendAttributes(noteTitle: noteTitle)
        let state = TelegramSendAttributes.ContentState(
            partsSent: 0, totalParts: totalParts, status: "Sending…"
        )
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            // A failed Live Activity must never break the send itself.
            activity = nil
        }
    }

    /// Reports progress after `partsSent` of `totalParts` have been delivered.
    static func update(partsSent: Int, totalParts: Int, status: String) {
        guard let activity else { return }
        let state = TelegramSendAttributes.ContentState(
            partsSent: partsSent, totalParts: totalParts, status: status
        )
        Task { await activity.update(.init(state: state, staleDate: nil)) }
    }

    /// Ends the activity, leaving it on screen briefly so the result is readable.
    static func finish(partsSent: Int, totalParts: Int, finalStatus: String) {
        guard let activity else { return }
        self.activity = nil
        let state = TelegramSendAttributes.ContentState(
            partsSent: partsSent, totalParts: totalParts, status: finalStatus
        )
        Task {
            await activity.end(
                .init(state: state, staleDate: nil),
                dismissalPolicy: .after(.now.addingTimeInterval(4))
            )
        }
    }
}
