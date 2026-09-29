import SwiftUI
import SwiftData

struct QuickStreamView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]
    @Query private var tags: [CategoryTag]

    @State private var searchText = ""
    @State private var selectedTag: CategoryTag?
    @State private var quickText = ""
    @State private var editingNote: Note?
    @State private var isComposing = false
    @State private var isShowingSettings = false

    private var visibleNotes: [Note] {
        notes
            .filter { !$0.isArchived }
            .filter { note in
                let matchesQuery = searchText.isEmpty
                    || note.title.localizedCaseInsensitiveContains(searchText)
                    || note.content.localizedCaseInsensitiveContains(searchText)
                let matchesTag = selectedTag.map { note.tag?.id == $0.id } ?? true
                return matchesQuery && matchesTag
            }
            .sorted { ($0.isPinned ? 1 : 0) > ($1.isPinned ? 1 : 0) }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                GlassBackground()

                VStack(spacing: 12) {
                    header
                    GlassSearchBar(text: $searchText, placeholder: "Search notes")
                    tagFilter
                    feed
                }

                composer
            }
            .navigationDestination(isPresented: $isComposing) {
                NoteEditorView(note: nil)
            }
            .sheet(item: $editingNote) { note in
                NoteEditorView(note: note)
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 1) {
                Text("GlassNotes")
                    .font(.system(size: 26, weight: .bold))
                Text("\(notes.filter { !$0.isArchived }.count) notes")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                isComposing = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 17, weight: .medium))
                    .padding(9)
                    .liquidGlass(GlassConfig(cornerRadius: 999, interactive: true))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("New note")

            Button {
                isShowingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 17, weight: .medium))
                    .padding(9)
                    .liquidGlass(GlassConfig(cornerRadius: 999, interactive: true))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var tagFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isOn: selectedTag == nil) {
                    selectedTag = nil
                }

                ForEach(tags) { tag in
                    FilterChip(
                        title: tag.name,
                        icon: tag.iconName,
                        tint: tag.color,
                        isOn: selectedTag?.id == tag.id
                    ) {
                        selectedTag = selectedTag?.id == tag.id ? nil : tag
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private var feed: some View {
        if visibleNotes.isEmpty {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(.tertiary)
                Text(searchText.isEmpty ? "Nothing here yet" : "No matches")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                if searchText.isEmpty {
                    Text("Type below to capture a thought, or tap compose to format it.")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(visibleNotes) { note in
                        NoteCardView(note: note) {
                            editingNote = note
                        }
                        .contextMenu {
                            Button {
                                note.isPinned.toggle()
                                try? context.save()
                            } label: {
                                Label(note.isPinned ? "Unpin" : "Pin", systemImage: "pin")
                            }
                            Button {
                                note.isLocked.toggle()
                                try? context.save()
                            } label: {
                                Label(note.isLocked ? "Unlock" : "Lock", systemImage: "lock")
                            }
                            Button(role: .destructive) {
                                context.delete(note)
                                try? context.save()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 96)
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Quick note", text: $quickText, axis: .vertical)
                .lineLimit(1...4)
                .textInputAutocapitalization(.sentences)
                .onSubmit(capture)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .liquidGlass(GlassConfig.field)

            Button(action: capture) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .liquidGlass(GlassConfig(cornerRadius: 999, tint: .white, interactive: true))
            }
            .buttonStyle(.plain)
            .disabled(quickText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Save note")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private func capture() {
        let text = quickText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let now = Date()
        context.insert(Note(content: text, createdAt: now, updatedAt: now))
        try? context.save()

        quickText = ""
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

struct FilterChip: View {
    let title: String
    var icon: String?
    var tint: Color = .white
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background {
                Capsule().fill(isOn ? tint.opacity(0.30) : Color.white.opacity(0.06))
            }
            .overlay {
                Capsule().strokeBorder(.white.opacity(isOn ? 0.5 : 0.12), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
