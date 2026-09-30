import Foundation
import SwiftData
import SwiftUI

@Model
public final class Folder {
    public var id: UUID
    public var name: String
    public var colorHex: String
    public var iconName: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#007AFF",
        iconName: String = "folder.fill",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.createdAt = createdAt
    }

    public var color: Color { Color(hex: colorHex) }
}
