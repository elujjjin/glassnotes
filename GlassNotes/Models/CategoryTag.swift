import Foundation
import SwiftData
import SwiftUI
import UIKit

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

    /// The inverse of `init(hex:)`, used to turn a `ColorPicker` selection into
    /// a storable string.
    ///
    /// `ColorPicker` hands back a colour in an arbitrary colour space, so the
    /// components are read through `UIColor`, which converts for us. Alpha is
    /// deliberately dropped: the picker is configured without opacity support and
    /// `init(hex:)` treats a 6-digit value as fully opaque. Falls back to black if
    /// the colour cannot be decomposed.
    func hexString() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return "#000000"
        }

        func channel(_ value: CGFloat) -> Int {
            min(255, max(0, Int((value * 255).rounded())))
        }
        return String(format: "#%02X%02X%02X", channel(r), channel(g), channel(b))
    }
}
