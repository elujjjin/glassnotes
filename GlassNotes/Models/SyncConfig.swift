import Foundation
import SwiftData

@Model
public final class SyncConfig {
    public var id: UUID
    public var telegramBotToken: String
    public var telegramChatId: String
    public var autoSyncEnabled: Bool
    public var biometricLockEnabled: Bool
    public var passcodePIN: String?
    public var lastSyncDate: Date?

    /// Minutes of background time before the app re-locks. 0 = never.
    public var autoLockMinutes: Int
    /// Whether haptic feedback is produced for actions.
    public var hapticsEnabled: Bool
    /// Base font size for the note editor (12–24 pt).
    public var editorFontSize: Double
    /// Hex string for the app accent colour.
    public var accentColorHex: String
    /// When true, search matches the body of locked notes once the app is authenticated.
    public var searchUnlockedBody: Bool

    public init(
        id: UUID = UUID(),
        telegramBotToken: String = "",
        telegramChatId: String = "",
        autoSyncEnabled: Bool = false,
        biometricLockEnabled: Bool = false,
        passcodePIN: String? = nil,
        lastSyncDate: Date? = nil,
        autoLockMinutes: Int = 0,
        hapticsEnabled: Bool = true,
        editorFontSize: Double = 16,
        accentColorHex: String = "#007AFF",
        searchUnlockedBody: Bool = false
    ) {
        self.id = id
        self.telegramBotToken = telegramBotToken
        self.telegramChatId = telegramChatId
        self.autoSyncEnabled = autoSyncEnabled
        self.biometricLockEnabled = biometricLockEnabled
        self.passcodePIN = passcodePIN
        self.lastSyncDate = lastSyncDate
        self.autoLockMinutes = autoLockMinutes
        self.hapticsEnabled = hapticsEnabled
        self.editorFontSize = editorFontSize
        self.accentColorHex = accentColorHex
        self.searchUnlockedBody = searchUnlockedBody
    }
}
