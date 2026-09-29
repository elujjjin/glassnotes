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
    
    public init(
        id: UUID = UUID(),
        telegramBotToken: String = "",
        telegramChatId: String = "",
        autoSyncEnabled: Bool = false,
        biometricLockEnabled: Bool = false,
        passcodePIN: String? = nil,
        lastSyncDate: Date? = nil
    ) {
        self.id = id
        self.telegramBotToken = telegramBotToken
        self.telegramChatId = telegramChatId
        self.autoSyncEnabled = autoSyncEnabled
        self.biometricLockEnabled = biometricLockEnabled
        self.passcodePIN = passcodePIN
        self.lastSyncDate = lastSyncDate
    }
}
