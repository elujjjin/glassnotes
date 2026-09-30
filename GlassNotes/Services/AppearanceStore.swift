import SwiftUI
import UIKit

enum Wallpaper: String, CaseIterable, Identifiable {
    case graphite
    case aurora
    case prism
    case grid
    case silk

    var id: String { rawValue }

    var label: String {
        switch self {
        case .graphite: return "Graphite"
        case .aurora: return "Aurora"
        case .prism: return "Prism"
        case .grid: return "Lattice"
        case .silk: return "Silk"
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

    private let defaults: UserDefaults

    private enum Keys {
        static let wallpaper = "appearance.wallpaper"
        static let photo = "appearance.photo"
        static let accentColor = "appearance.accentColor"
        static let editorFontSize = "appearance.editorFontSize"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.string(forKey: Keys.wallpaper) ?? ""
        self.wallpaper = Wallpaper(rawValue: stored) ?? .aurora
        self.photo = Self.loadPhoto()
        self.accentColorHex = defaults.string(forKey: Keys.accentColor) ?? "#007AFF"
        let storedSize = defaults.double(forKey: Keys.editorFontSize)
        self.editorFontSize = storedSize > 0 ? CGFloat(storedSize) : 16
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
