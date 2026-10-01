import SwiftUI
import UIKit

enum Wallpaper: String, CaseIterable, Identifiable {
    case graphite
    case aurora
    case prism
    case grid
    case silk
    // Added later: flat colours and simple pattern work, not just gradients.
    case midnight
    case parchment
    case forest
    case ember
    case mono
    case floral
    case skull
    case cross
    case topo

    var id: String { rawValue }

    var label: String {
        switch self {
        case .graphite: return "Graphite"
        case .aurora: return "Aurora"
        case .prism: return "Prism"
        case .grid: return "Lattice"
        case .silk: return "Silk"
        case .midnight: return "Midnight"
        case .parchment: return "Parchment"
        case .forest: return "Forest"
        case .ember: return "Ember"
        case .mono: return "Mono"
        case .floral: return "Floral"
        case .skull: return "Skull"
        case .cross: return "Crosses"
        case .topo: return "Topo"
        }
    }
}

@MainActor
final class AppearanceStore: ObservableObject {
    @Published var wallpaper: Wallpaper {
        didSet { defaults.set(wallpaper.rawValue, forKey: Keys.wallpaper) }
    }

    @Published var photo: UIImage? {
        didSet { persistPhoto() }
    }

    @Published var accentColorHex: String {
        didSet { defaults.set(accentColorHex, forKey: Keys.accentColor) }
    }

    @Published var editorFontSize: CGFloat {
        didSet { defaults.set(Double(editorFontSize), forKey: Keys.editorFontSize) }
    }

    /// User-saved accent colours, newest last. Persisted so custom palettes
    /// survive relaunch; the built-in `TagPalette.defaults` are not stored here
    /// because they ship with the app.
    @Published var accentPresets: [AccentPreset] {
        didSet { persistPresets() }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let wallpaper = "appearance.wallpaper"
        static let photo = "appearance.photo"
        static let accentColor = "appearance.accentColor"
        static let editorFontSize = "appearance.editorFontSize"
        static let accentPresets = "appearance.accentPresets"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.string(forKey: Keys.wallpaper) ?? ""
        self.wallpaper = Wallpaper(rawValue: stored) ?? .aurora
        self.photo = Self.loadPhoto()
        self.accentColorHex = defaults.string(forKey: Keys.accentColor) ?? "#007AFF"
        let storedSize = defaults.double(forKey: Keys.editorFontSize)
        self.editorFontSize = storedSize > 0 ? CGFloat(storedSize) : 16
        self.accentPresets = Self.loadPresets(from: defaults)
    }

    /// Saves a preset: adds it, or refreshes the name if that colour is already
    /// stored. Saving the same name twice keeps the preset — the "+" button must
    /// never delete something the user just asked to save.
    ///
    /// A colour already in the list has its name refreshed rather than
    /// producing a duplicate swatch.
    func savePreset(named name: String, hex: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalised = hex.uppercased()
        let label = trimmed.isEmpty ? normalised : trimmed

        if let index = accentPresets.firstIndex(where: { $0.hex.uppercased() == normalised }) {
            accentPresets[index] = AccentPreset(name: label, hex: normalised)
            return
        }

        accentPresets.append(AccentPreset(name: label, hex: normalised))
        // Keep the list bounded; the oldest entries fall off the end.
        if accentPresets.count > Self.maxPresets {
            accentPresets.removeFirst(accentPresets.count - Self.maxPresets)
        }
    }

    /// Removes the preset stored under `hex`, if any.
    func removePreset(hex: String) {
        let normalised = hex.uppercased()
        accentPresets.removeAll { $0.hex.uppercased() == normalised }
    }

    private static let maxPresets = 24

    private func persistPresets() {
        guard let data = try? JSONEncoder().encode(accentPresets) else { return }
        defaults.set(data, forKey: Keys.accentPresets)
    }

    private static func loadPresets(from defaults: UserDefaults) -> [AccentPreset] {
        guard let data = defaults.data(forKey: Keys.accentPresets),
              let decoded = try? JSONDecoder().decode([AccentPreset].self, from: data)
        else { return [] }
        return decoded
    }

    var usesPhoto: Bool { photo != nil }

    func clearPhoto() {
        photo = nil
    }

    private static var photoURL: URL? {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("wallpaper.jpg")
    }

    private static func loadPhoto() -> UIImage? {
        guard let url = photoURL, let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private func persistPhoto() {
        guard let url = Self.photoURL else { return }
        if let photo, let data = photo.jpegData(compressionQuality: 0.9) {
            try? FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? data.write(to: url, options: .atomic)
        } else {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

/// A named accent colour the user saved.
struct AccentPreset: Codable, Identifiable, Hashable {
    var name: String
    var hex: String
    var id: String { hex.uppercased() }
}
