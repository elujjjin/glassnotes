import ActivityKit
import Foundation

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
