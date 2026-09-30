import Foundation
import SwiftData
import SwiftUI

@Model
public final class CategoryTag {
    public var id: UUID
    public var name: String
    public var colorHex: String
    public var iconName: String
    
    /// Inverse of `Note.tags`, which declares the `@Relationship` and the
    /// `inverse:` for this pair. Deliberately a non-optional array: SwiftData
    /// cannot build a schema where an `inverse:` points at an optional
    /// to-many, and the resulting `ModelContainer` failure is fatal at launch.
    public var notes: [Note] = []
    
    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#007AFF",
        iconName: String = "tag.fill"
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.notes = []
    }
    
    public var color: Color {
        Color(hex: colorHex)
    }
}

extension Color {
    /// Builds a colour from a `#RGB`, `#RRGGBB` or `#AARRGGBB` string.
    /// Unparseable input falls back to white rather than a near-transparent
    /// black, so a malformed tag colour stays visible.
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int), !hex.isEmpty else {
            self = .white
            return
        }
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            self = .white
            return
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
