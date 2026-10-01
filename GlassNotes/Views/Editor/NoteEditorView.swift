import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appearance: AppearanceStore
    @Query private var tags: [CategoryTag]
    @Query private var folders: [Folder]
    @Query private var configs: [SyncConfig]

    @State private var title: String
    @State private var content: String
    @State private var isPinned: Bool
    @State private var isLocked: Bool
    @State private var selectedTags: Set<UUID>
    @State private var selectedFolderID: UUID?
    @State private var isPreviewing = false
    @State private var syncStatus: String?
    @State private var isSendingTelegram = false
    @State private var persistedNote: Note?
    @State private var editorSelection = NSRange(location: 0, length: 0)
    @FocusState private var isEditorFocused: Bool
    @State private var isShowingTagPicker = false
    @State private var autoSaveTask: Task<Void, Never>?
    @State private var draftSaved = false

    private let note: Note?
    /// The note as it was when the editor opened, so `save()` can tell whether
    /// the user actually changed anything (auto-save usually writes the new
    /// values first, which would make a naive comparison always say "unchanged").
    private let original: NoteSnapshot?
    private var config: SyncConfig? { configs.first }
    private var hapticsEnabled: Bool { config?.hapticsEnabled ?? true }
    private var fontSize: CGFloat { CGFloat(config?.editorFontSize ?? 16) }

    private struct NoteSnapshot {
        var title: String
        var content: String
        var isPinned: Bool
        var isLocked: Bool
        var tagIDs: Set<UUID>
        var folderID: UUID?
    }

    init(note: Note?) {
        self.note = note
        _title = State(initialValue: note?.title ?? "")
        _content = State(initialValue: note?.content ?? "")
        _isPinned = State(initialValue: note?.isPinned ?? false)
        _isLocked = State(initialValue: note?.isLocked ?? false)
        _selectedTags = State(initialValue: Set((note?.tags ?? []).map(\.id)))
        _selectedFolderID = State(initialValue: note?.folderID)
        original = note.map {
            NoteSnapshot(
                title: $0.title,
                content: $0.content,
                isPinned: $0.isPinned,
                isLocked: $0.isLocked,
                tagIDs: Set($0.tags.map(\.id)),
                folderID: $0.folderID
            )
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()

                VStack(spacing: 14) {
                    toolbar
                    optionBar
                    titleField
                    editor
                    Spacer(minLength: 0)
                }

                // Status toast (Telegram / draft saved)
                if let syncStatus {
                    VStack {
                        Spacer()
                        Text(syncStatus)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .liquidGlass(GlassConfig(cornerRadius: 999))
                            .padding(.bottom, 28)
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: syncStatus)
            .sheet(isPresented: $isShowingTagPicker) {
                TagPickerSheet(allTags: tags, selected: $selectedTags)
            }
        }
        .onChange(of: content) { _, _ in scheduleAutoSave() }
        .onChange(of: title)   { _, _ in scheduleAutoSave() }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(9)
                    .liquidGlass(GlassConfig(cornerRadius: 999, interactive: true))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")

            Spacer()

            Picker("Mode", selection: $isPreviewing) {
                Text("Write").tag(false)
                Text("Preview").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 132)

            Spacer()

            Button(action: save) {
                Text("Save")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .liquidGlass(GlassConfig(cornerRadius: 999, tint: .white, interactive: true))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Option bar

    private var optionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Pin
                ToggleChip(icon: "pin.fill", title: isPinned ? "Pinned" : "Pin",
                           tint: .yellow, isOn: isPinned) {
                    isPinned.toggle()
                    HapticsService.shared.impact(.light, enabled: hapticsEnabled)
                }

                // Lock
                ToggleChip(icon: "lock.fill", title: isLocked ? "Locked" : "Lock",
                           tint: .white, isOn: isLocked) {
                    isLocked.toggle()
                    HapticsService.shared.impact(.light, enabled: hapticsEnabled)
                }

                // Tags (multi)
                Button { isShowingTagPicker = true } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "tag")
                            .font(.system(size: 11, weight: .semibold))
                        let tagCount = selectedTags.count
                        Text(tagCount == 0 ? "Tags" : "\(tagCount) tag\(tagCount == 1 ? "" : "s")")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background {
                        Capsule().fill(selectedTags.isEmpty ? Color.white.opacity(0.06) : Color.blue.opacity(0.3))
                    }
                    .overlay {
                        Capsule().strokeBorder(.white.opacity(selectedTags.isEmpty ? 0.12 : 0.5), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)

                // Folder
                Menu {
                    Button("No folder") { selectedFolderID = nil }
                    ForEach(folders) { folder in
                        Button {
                            selectedFolderID = folder.id
                        } label: {
                            Label(folder.name, systemImage: folder.iconName)
                        }
                    }
                } label: {
                    let folderName = folders.first(where: { $0.id == selectedFolderID })?.name
                    ToggleChip(
                        icon: selectedFolderID == nil ? "folder" : "folder.fill",
                        title: folderName ?? "Folder",
                        tint: .white,
                        isOn: selectedFolderID != nil
                    ) {}
                }

                // Reading time
                let mins = max(1, wordCount / 200)
                ToggleChip(icon: "clock", title: "\(mins) min read", tint: .white, isOn: false) {}
                    .disabled(true)
                    .opacity(0.6)

                // Copy as Markdown
                Button {
                    UIPasteboard.general.string = content
                    showToast("Copied as Markdown")
                    HapticsService.shared.notification(.success, enabled: hapticsEnabled)
                } label: {
                    ToggleChip(icon: "doc.on.doc", title: "Copy MD", tint: .white, isOn: false) {}
                }
                .buttonStyle(.plain)

                // Telegram
                if let cfg = config, !cfg.telegramBotToken.isEmpty {
                    ToggleChip(
                        icon: isSendingTelegram ? "ellipsis" : "paperplane",
                        title: isSendingTelegram ? "Sending…" : "Telegram",
                        tint: .white,
                        isOn: note?.telegramMessageId != nil
                    ) { sendToTelegram(cfg) }
                    .disabled(isSendingTelegram)
                    .opacity(isSendingTelegram ? 0.6 : 1)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Title

    private var titleField: some View {
        VStack(spacing: 8) {
            HStack {
                TextField("Title", text: $title)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                // Markdown export
                ShareLink(
                    item: markdownExportFile,
                    preview: SharePreview("\(exportFilename).md", image: Image(systemName: "doc.text"))
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            Divider().overlay(.white.opacity(0.15)).padding(.horizontal, 20)
        }
    }

    // MARK: - Editor

    @ViewBuilder
    private var editor: some View {
        if isPreviewing {
            ScrollView {
                if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Nothing to preview.")
                        .font(.system(size: fontSize))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    MarkdownText(source: content, baseFont: .system(size: fontSize))
                }
            }
            .padding(.horizontal, 20)
        } else {
            VStack(spacing: 10) {
                MarkdownTextEditor(text: $content, selection: $editorSelection, fontSize: fontSize)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(12)
                    .liquidGlass(GlassConfig.field)
                    .padding(.horizontal, 20)

                FormattingBar(
                    text: $content,
                    selection: $editorSelection,
                    isEditorFocused: $isEditorFocused
                )
                .padding(.horizontal, 20)

                HStack {
                    Text("\(wordCount) words")
                    Spacer()
                    if draftSaved {
                        Label("Draft saved", systemImage: "checkmark.circle")
                            .foregroundStyle(.green.opacity(0.8))
                    }
                    Spacer()
                    Text("\(content.count) characters")
                }
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 24)
                .animation(.easeInOut, value: draftSaved)
            }
        }
    }

    // MARK: - Helpers

    private var wordCount: Int {
        content.split(whereSeparator: { $0.isWhitespace }).count
    }

    /// A filesystem-safe stem for the exported file. A title containing "/"
    /// would otherwise build a nested path that never gets written, leaving the
    /// share sheet with a stale or missing file.
    private var exportFilename: String {
        let base = title.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\n", with: " ")
        return base.isEmpty ? "Note" : String(base.prefix(80))
    }

    private var markdownExportFile: URL {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(exportFilename).md")
        let body = title.isEmpty ? content : "# \(title)\n\n\(content)"
        try? body.write(to: tmp, atomically: true, encoding: .utf8)
        return tmp
    }

    private func showToast(_ message: String) {
        syncStatus = message
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { if syncStatus == message { syncStatus = nil } }
        }
    }

    // MARK: - Auto-save

    private func scheduleAutoSave() {
        autoSaveTask?.cancel()
        autoSaveTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            performAutoSave()
        }
    }

    private func performAutoSave() {
        let hasContent = !title.isEmpty || !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        // Refuse to create an empty note, but keep persisting an existing note
        // whose text the user has cleared — otherwise that edit is dropped.
        guard hasContent || note != nil || persistedNote != nil else { return }
        let resolvedTags = tags.filter { selectedTags.contains($0.id) }
        if let note {
            note.title = title
            note.content = content
            note.isPinned = isPinned
            note.isLocked = isLocked
            note.tags = resolvedTags
            note.folderID = selectedFolderID
            note.isDraft = true
            try? context.save()
        } else if persistedNote == nil {
            let created = Note(title: title, content: content,
                               isPinned: isPinned, isLocked: isLocked,
                               tags: resolvedTags, folderID: selectedFolderID, isDraft: true)
            context.insert(created)
            try? context.save()
            persistedNote = created
        } else if let draft = persistedNote {
            draft.title = title
            draft.content = content
            draft.isPinned = isPinned
            draft.isLocked = isLocked
            draft.tags = resolvedTags
            draft.folderID = selectedFolderID
            draft.isDraft = true
            try? context.save()
        }
        draftSaved = true
        // Debounced by 2s, so this cannot fire per keystroke.
        WidgetDataWriter.shared.sync(context: context)
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { draftSaved = false }
        }
    }

    // MARK: - Save

    private func save() {
        let hasContent = !title.isEmpty || !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        // Only refuse to save when there is nothing to store *and* no existing
        // note to update. Clearing an existing note must not be silently
        // discarded on the way out.
        if !hasContent && note == nil && persistedNote == nil {
            dismiss(); return
        }
        autoSaveTask?.cancel()
        let resolvedTags = tags.filter { selectedTags.contains($0.id) }

        if let note {
            // Compare with the snapshot from init, not with `note` itself:
            // auto-save has usually already copied the edited values across, so
            // comparing with the live object reports "unchanged" and skips the
            // `updatedAt` bump that "Updated" sorting depends on.
            let changed = original.map {
                $0.title != title
                    || $0.content != content
                    || $0.isPinned != isPinned
                    || $0.isLocked != isLocked
                    || $0.tagIDs != selectedTags
                    || $0.folderID != selectedFolderID
            } ?? true
            note.title = title
            note.content = content
            note.isPinned = isPinned
            note.isLocked = isLocked
            note.tags = resolvedTags
            note.folderID = selectedFolderID
            note.isDraft = false
            if changed { note.updatedAt = Date() }
        } else if let draft = persistedNote {
            draft.title = title
            draft.content = content
            draft.isPinned = isPinned
            draft.isLocked = isLocked
            draft.tags = resolvedTags
            draft.folderID = selectedFolderID
            draft.isDraft = false
            draft.updatedAt = Date()
        } else {
            let created = Note(title: title, content: content,
                               isPinned: isPinned, isLocked: isLocked,
                               tags: resolvedTags, folderID: selectedFolderID, isDraft: false)
            context.insert(created)
        }
        try? context.save()
        WidgetDataWriter.shared.sync(context: context)
        HapticsService.shared.notification(.success, enabled: hapticsEnabled)
        dismiss()
    }

    // MARK: - Telegram

    private func sendToTelegram(_ cfg: SyncConfig) {
        guard !isSendingTelegram else { return }
        isSendingTelegram = true
        syncStatus = "Sending…"
        Task {
            let service = TelegramSyncService()
            let messageId = await service.sendNoteToTelegram(
                botToken: cfg.telegramBotToken,
                chatId: cfg.telegramChatId,
                noteTitle: title.isEmpty ? "Quick note" : title,
                noteContent: content
            )
            isSendingTelegram = false
            syncStatus = service.statusMessage
            if let messageId {
                (note ?? persistedNote)?.telegramMessageId = messageId
                try? context.save()
            }
            try? await Task.sleep(for: .seconds(3))
            withAnimation { if syncStatus == service.statusMessage { syncStatus = nil } }
        }
    }
}

// MARK: - ToggleChip

struct ToggleChip: View {
    let icon: String
    let title: String
    let tint: Color
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
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

// MARK: - TagPickerSheet

struct TagPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let allTags: [CategoryTag]
    @Binding var selected: Set<UUID>

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()
                List(allTags) { tag in
                    Button {
                        if selected.contains(tag.id) { selected.remove(tag.id) }
                        else { selected.insert(tag.id) }
                    } label: {
                        HStack {
                            Image(systemName: tag.iconName)
                                .foregroundStyle(tag.color)
                            Text(tag.name)
                                .foregroundStyle(.white)
                            Spacer()
                            if selected.contains(tag.id) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
