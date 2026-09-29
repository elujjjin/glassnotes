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
    
    @Relationship(deleteRule: .nullify)
    public var tag: CategoryTag?
    
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
        tag: CategoryTag? = nil
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
        self.tag = tag
    }
    
    public var displayTitle: String {
        if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return title
        }
        let firstLine = content.components(separatedBy: .newlines).first ?? ""
        let cleaned = firstLine.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespaces)
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

    public var formattedDate: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(updatedAt) {
            formatter.dateFormat = "h:mm a"
        } else if Calendar.current.isDate(updatedAt, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMM d"
        } else {
            formatter.dateFormat = "MM/dd/yy"
        }
        return formatter.string(from: updatedAt)
    }
}
