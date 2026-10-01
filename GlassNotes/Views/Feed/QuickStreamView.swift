import SwiftUI
import SwiftData

// MARK: - Sort order

enum NoteSort: String, CaseIterable, Identifiable {
    case updated = "Updated"
    case created = "Created"
    case alpha   = "A–Z"
    case words   = "Word count"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .updated: return "clock"
        case .created: return "calendar"
        case .alpha:   return "textformat.abc"
        case .words:   return "text.word.spacing"
        }
    }
}

// MARK: - QuickStreamView

struct QuickStreamView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var auth: BiometricAuthService
    @EnvironmentObject private var appearance: AppearanceStore
    @Query(sort: \Note.updatedAt, order: .reverse) private var allNotes: [Note]
    @Query private var tags: [CategoryTag]
    @Query private var folders: [Folder]
    @Query private var configs: [SyncConfig]

    @State private var searchText = ""
    @State private var selectedTags: Set<UUID> = []
    @State private var selectedFolder: Folder?
    @State private var sortOrder: NoteSort = .updated
    @State private var quickText = ""
    @State private var editingNote: Note?
    @State private var isComposing = false
    @State private var isShowingSettings = false
    @State private var isShowingArchive = false
    @State private var isShowingFolders = false

    private var config: SyncConfig? { configs.first }
    private var hapticsEnabled: Bool { config?.hapticsEnabled ?? true }

    private var visibleNotes: [Note] {
        let searchUnlocked = auth.isUnlocked && (config?.searchUnlockedBody ?? false)
        var result = allNotes
            .filter { !$0.isArchived }
            .filter { note in
                if let folder = selectedFolder {
                    guard note.folderID == folder.id else { return false }
                }
                if !selectedTags.isEmpty {
                    let noteTagIDs = Set(note.tags.map(\.id))
                    guard !selectedTags.isDisjoint(with: noteTagIDs) else { return false }
                }
                guard !searchText.isEmpty else { return true }
                let searchable: String
                if note.isLocked && !searchUnlocked {
                    searchable = note.title
                } else {
                    searchable = note.title + "\n" + note.content
                }
                return searchable.localizedCaseInsensitiveContains(searchText)
            }

        // Pinned always float to top, then sort within each group
        switch sortOrder {
        case .updated:
            result.sort { ($0.isPinned ? 1 : 0) == ($1.isPinned ? 1 : 0)
                ? $0.updatedAt > $1.updatedAt
                : ($0.isPinned ? 1 : 0) > ($1.isPinned ? 1 : 0) }
        case .created:
            result.sort { ($0.isPinned ? 1 : 0) == ($1.isPinned ? 1 : 0)
                ? $0.createdAt > $1.createdAt
                : ($0.isPinned ? 1 : 0) > ($1.isPinned ? 1 : 0) }
        case .alpha:
            result.sort { ($0.isPinned ? 1 : 0) == ($1.isPinned ? 1 : 0)
                ? $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending
                : ($0.isPinned ? 1 : 0) > ($1.isPinned ? 1 : 0) }
        case .words:
            result.sort { ($0.isPinned ? 1 : 0) == ($1.isPinned ? 1 : 0)
                ? $0.wordCount > $1.wordCount
                : ($0.isPinned ? 1 : 0) > ($1.isPinned ? 1 : 0) }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                GlassBackground()

                VStack(spacing: 12) {
                    header
                    GlassSearchBar(text: $searchText, placeholder: "Search notes")
                        .padding(.horizontal, 20)
                    tagFilter
                    feed
                }

                composer
            }
            .fullScreenCover(isPresented: $isComposing) {
                NoteEditorView(note: nil)
            }
            .sheet(item: $editingNote) { note in
                NoteEditorView(note: note)
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $isShowingArchive) {
                ArchiveView()
            }
            .sheet(isPresented: $isShowingFolders) {
                FolderManagerView()
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 1) {
                Text("GlassNotes")
                    .font(.system(size: 26, weight: .bold))
                HStack(spacing: 6) {
                    Text("\(allNotes.filter { !$0.isArchived }.count) notes")
                    if let folder = selectedFolder {
                        Text("·")
                        Image(systemName: folder.iconName)
                        Text(folder.name)
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Folder picker
            Menu {
                Button { selectedFolder = nil } label: {
                    Label("All Notes", systemImage: "tray.full")
                }
                Divider()
                ForEach(folders) { folder in
                    Button { selectedFolder = folder } label: {
                        Label(folder.name, systemImage: folder.iconName)
                    }
                }
                Divider()
                Button { isShowingFolders = true } label: {
                    Label("Manage Folders…", systemImage: "folder.badge.gear")
                }
            } label: {
                Image(systemName: selectedFolder == nil ? "tray.full" : "folder.fill")
                    .font(.system(size: 17, weight: .medium))
                    .padding(9)
                    .liquidGlass(GlassConfig(cornerRadius: 999, interactive: true))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)

            // Sort picker
            Menu {
                ForEach(NoteSort.allCases) { sort in
                    Button {
                        sortOrder = sort
                    } label: {
                        Label(sort.rawValue, systemImage: sort.icon)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 17, weight: .medium))
                    .padding(9)
                    .liquidGlass(GlassConfig(cornerRadius: 999, interactive: true))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)

            // New note
            Button { isComposing = true } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 17, weight: .medium))
                    .padding(9)
                    .liquidGlass(GlassConfig(cornerRadius: 999, interactive: true))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .accessibilityLabel("New note")

            // Settings + Archive
            Menu {
                Button { isShowingSettings = true } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                Button { isShowingArchive = true } label: {
                    Label("Archive", systemImage: "archivebox")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .medium))
                    .padding(9)
                    .liquidGlass(GlassConfig(cornerRadius: 999, interactive: true))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: Tag filter

    private var tagFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isOn: selectedTags.isEmpty) {
                    selectedTags.removeAll()
                }
                ForEach(tags) { tag in
                    FilterChip(
                        title: tag.name,
                        icon: tag.iconName,
                        tint: tag.color,
                        isOn: selectedTags.contains(tag.id)
                    ) {
                        if selectedTags.contains(tag.id) {
                            selectedTags.remove(tag.id)
                        } else {
                            selectedTags.insert(tag.id)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: Feed

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
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                note.isPinned.toggle()
                                try? context.save()
                                HapticsService.shared.impact(.light, enabled: hapticsEnabled)
                            } label: {
                                Label(note.isPinned ? "Unpin" : "Pin",
                                      systemImage: note.isPinned ? "pin.slash" : "pin")
                            }
                            .tint(.yellow)

                            Button {
                                note.isArchived = true
                                try? context.save()
                                WidgetDataWriter.shared.sync(context: context)
                                HapticsService.shared.impact(.medium, enabled: hapticsEnabled)
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            .tint(.indigo)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                context.delete(note)
                                try? context.save()
                                WidgetDataWriter.shared.sync(context: context)
                                HapticsService.shared.notification(.warning, enabled: hapticsEnabled)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button {
                                note.isPinned.toggle()
                                try? context.save()
                            } label: {
                                Label(note.isPinned ? "Unpin" : "Pin", systemImage: "pin")
                            }
                            Button {
                                note.isArchived = true
                                try? context.save()
                                WidgetDataWriter.shared.sync(context: context)
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            Button(role: .destructive) {
                                context.delete(note)
                                try? context.save()
                                WidgetDataWriter.shared.sync(context: context)
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

    // MARK: Quick capture

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Quick note", text: $quickText, axis: .vertical)
                .lineLimit(1...4)
                .textInputAutocapitalization(.sentences)
                .onSubmit(capture)
                // A vertical-axis TextField reports an ideal width based on its
                // longest line, which can widen this row and push the send button
                // off screen. Claim the available width so the text wraps instead.
                .frame(maxWidth: .infinity)
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
        let note = Note(content: text, createdAt: now, updatedAt: now,
                        folderID: selectedFolder?.id)
        context.insert(note)
        try? context.save()
        quickText = ""
        WidgetDataWriter.shared.sync(context: context)
        HapticsService.shared.impact(.light, enabled: hapticsEnabled)
    }
}

// MARK: - FilterChip

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
