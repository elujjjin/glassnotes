import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Shared note data for the widget

struct WidgetNote: Codable {
    var title: String
    var snippet: String
    var updatedAt: Date
}

// MARK: - Timeline Provider

struct NoteWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> NoteWidgetEntry {
        NoteWidgetEntry(date: Date(), notes: [
            WidgetNote(title: "Meeting notes", snippet: "Discuss Q4 roadmap…", updatedAt: Date()),
            WidgetNote(title: "Ideas", snippet: "New app concept…", updatedAt: Date()),
            WidgetNote(title: "Journal", snippet: "Today was productive…", updatedAt: Date()),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (NoteWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NoteWidgetEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> NoteWidgetEntry {
        // Read from the shared App Group store.
        // If App Group hasn't been configured yet, fall back to sample data.
        let notes = readNotesFromSharedStore()
        return NoteWidgetEntry(date: Date(), notes: notes)
    }

    private func readNotesFromSharedStore() -> [WidgetNote] {
        // App Group container URL
        let decoder = JSONDecoder()
        // The writer uses `.iso8601`; the default strategy expects a numeric
        // timestamp, so without this every decode fails and the widget falls
        // back to the placeholder forever.
        decoder.dateDecodingStrategy = .iso8601
        guard let storeURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.glassnotes.app")?
            .appendingPathComponent("widget_notes.json"),
              let data = try? Data(contentsOf: storeURL),
              let decoded = try? decoder.decode([WidgetNote].self, from: data),
              !decoded.isEmpty
        else {
            // Return placeholder notes if widget data hasn't been written yet
            return [WidgetNote(title: "GlassNotes", snippet: "Open the app to see your notes.", updatedAt: Date())]
        }
        return decoded
    }
}

// MARK: - Entry

struct NoteWidgetEntry: TimelineEntry {
    let date: Date
    let notes: [WidgetNote]
}

// MARK: - Views

struct NoteWidgetSmallView: View {
    let entry: NoteWidgetEntry

    var body: some View {
        if let note = entry.notes.first {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "note.text")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(note.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text(note.snippet)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(12)
        }
    }
}

struct NoteWidgetMediumView: View {
    let entry: NoteWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("GlassNotes")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            ForEach(Array(entry.notes.prefix(3).enumerated()), id: \.offset) { _, note in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: 3)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(note.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(note.snippet)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(12)
    }
}

struct NoteWidgetAccessoryView: View {
    let entry: NoteWidgetEntry

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "note.text")
            Text("\(entry.notes.count)")
                .font(.system(size: 13, weight: .bold))
        }
    }
}

// MARK: - Widget

struct NoteWidget: Widget {
    let kind: String = "NoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NoteWidgetProvider()) { entry in
            NoteWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("GlassNotes")
        .description("See your most recent notes.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

struct NoteWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: NoteWidgetEntry

    var body: some View {
        switch family {
        case .systemMedium:
            NoteWidgetMediumView(entry: entry)
        case .accessoryCircular, .accessoryRectangular:
            NoteWidgetAccessoryView(entry: entry)
        default:
            NoteWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Bundle

@main
struct NoteWidgetBundle: WidgetBundle {
    var body: some Widget {
        NoteWidget()
    }
}
