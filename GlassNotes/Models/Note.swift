import Foundation
import SwiftData

@Model
public final class Note {
    public var id: UUID
    public var title: String
    public var content: String
    public var createdAt: Date
    public var updatedAt: Date
    public var isPinned: Bool
    public var isFavorite: Bool
    public var isArchived: Bool
    public var isLocked: Bool
    public var telegramMessageId: Int64?
    
    @Relationship(deleteRule: .nullify, inverse: \CategoryTag.notes)
    public var tags: [CategoryTag]
    
    /// UUID of the `Folder` this note belongs to, or `nil` for no folder.
    /// Stored as a raw UUID to avoid a CloudKit-incompatible inverse relationship.
    public var folderID: UUID?

    /// `true` while auto-save has written unsaved changes.
    public var isDraft: Bool

    public init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPinned: Bool = false,
        isFavorite: Bool = false,
        isArchived: Bool = false,
        isLocked: Bool = false,
        telegramMessageId: Int64? = nil,
        tags: [CategoryTag] = [],
        folderID: UUID? = nil,
        isDraft: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.isFavorite = isFavorite
        self.isArchived = isArchived
        self.isLocked = isLocked
        self.telegramMessageId = telegramMessageId
        self.tags = tags
        self.folderID = folderID
        self.isDraft = isDraft
    }
    
    public var displayTitle: String {
        if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return title
        }
        let firstLine = content.components(separatedBy: .newlines).first ?? ""
        // Strip only leading heading markers. Removing every "#" would turn
        // "C# notes" into "C notes".
        var cleaned = firstLine.trimmingCharacters(in: .whitespaces)
        while cleaned.hasPrefix("#") { cleaned = String(cleaned.dropFirst()) }
        cleaned = cleaned.trimmingCharacters(in: .whitespaces)
        return cleaned.isEmpty ? "Untitled Note" : cleaned
    }
    
    public var snippet: String {
        let body = content
            .components(separatedBy: .newlines)
            .dropFirst()
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        return body.isEmpty ? content : body
    }

    public var wordCount: Int {
        content.split(whereSeparator: { $0.isWhitespace }).count
    }

    /// Cached because a `DateFormatter` is expensive to create and this runs
    /// once per visible card on every table refresh.
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter
    }()

    public var formattedDate: String {
        if Calendar.current.isDateInToday(updatedAt) {
            return Self.timeFormatter.string(from: updatedAt)
        }
        if Calendar.current.isDate(updatedAt, equalTo: Date(), toGranularity: .year) {
            return Self.monthFormatter.string(from: updatedAt)
        }
        return Self.yearFormatter.string(from: updatedAt)
    }
}
