import Foundation
import WidgetKit

/// Writes a snapshot of recent non-locked notes to the App Group container so the
/// WidgetKit extension can display them without accessing the SwiftData store directly.
///
/// Call `sync(notes:)` from wherever notes are saved — e.g. after context.save() in
/// QuickStreamView capture or NoteEditorView save.
@MainActor
final class WidgetDataWriter {
    static let shared = WidgetDataWriter()
    private init() {}

    private var appGroupURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.glassnotes.app")?
            .appendingPathComponent("widget_notes.json")
    }

    struct WidgetNote: Codable {
        var title: String
        var snippet: String
        var updatedAt: Date
    }

    func sync(notes: [Note]) {
        guard let url = appGroupURL else { return }

        let recent = notes
            .filter { !$0.isArchived && !$0.isLocked }
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(5)
            .map { WidgetNote(title: $0.displayTitle, snippet: $0.snippet, updatedAt: $0.updatedAt) }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(Array(recent)) else { return }
        try? data.write(to: url, options: .atomic)

        // Reload all widgets after writing
        WidgetCenter.shared.reloadAllTimelines()
    }
}
