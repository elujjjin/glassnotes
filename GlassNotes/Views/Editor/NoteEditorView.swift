import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var tags: [CategoryTag]
    @Query private var configs: [SyncConfig]

    @State private var title: String
    @State private var content: String
    @State private var isPinned: Bool
    @State private var isLocked: Bool
    @State private var selectedTag: CategoryTag?
    @State private var isPreviewing = false
    @State private var syncStatus: String?
    @State private var isSendingTelegram = false
    @State private var persistedNote: Note?
    @State private var editorSelection = NSRange(location: 0, length: 0)
    @FocusState private var isEditorFocused: Bool

    private let note: Note?

    init(note: Note?) {
        self.note = note
        _title = State(initialValue: note?.title ?? "")
        _content = State(initialValue: note?.content ?? "")
        _isPinned = State(initialValue: note?.isPinned ?? false)
        _isLocked = State(initialValue: note?.isLocked ?? false)
        _selectedTag = State(initialValue: note?.tag)
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
        }
    }

    private var toolbar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
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

    private var optionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ToggleChip(
                    icon: "pin.fill",
                    title: isPinned ? "Pinned" : "Pin",
                    tint: .yellow,
                    isOn: isPinned
                ) {
                    isPinned.toggle()
                }

                ToggleChip(
                    icon: "lock.fill",
                    title: isLocked ? "Locked" : "Lock",
                    tint: .white,
                    isOn: isLocked
                ) {
                    isLocked.toggle()
                }

                Menu {
                    Button("No tag") { selectedTag = nil }
                    ForEach(tags) { tag in
                        Button {
                            selectedTag = tag
                        } label: {
                            Label(tag.name, systemImage: tag.iconName)
                        }
                    }
                } label: {
                    ToggleChip(
                        icon: selectedTag?.iconName ?? "tag",
                        title: selectedTag?.name ?? "Tag",
                        tint: selectedTag?.color ?? .white,
                        isOn: selectedTag != nil
                    ) {}
                }

                if let config = configs.first, !config.telegramBotToken.isEmpty {
                    ToggleChip(
                        icon: isSendingTelegram ? "ellipsis" : "paperplane",
                        title: isSendingTelegram ? "Sending…" : "Telegram",
                        tint: .white,
                        isOn: note?.telegramMessageId != nil
                    ) {
                        sendToTelegram(config)
                    }
                    .disabled(isSendingTelegram)
                    .opacity(isSendingTelegram ? 0.6 : 1)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var titleField: some View {
        VStack(spacing: 8) {
            TextField("Title", text: $title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)

            Divider()
                .overlay(.white.opacity(0.15))
                .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private var editor: some View {
        if isPreviewing {
            ScrollView {
                if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Nothing to preview.")
                        .font(.system(size: 16))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    MarkdownText(source: content, baseFont: .system(size: 16))
                }
            }
            .padding(.horizontal, 20)
        } else {
            VStack(spacing: 10) {
                // Grow to fill the available height so the formatting bar and the
                // word counter stay anchored at the bottom of the screen.
                MarkdownTextEditor(text: $content, selection: $editorSelection)
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
                    Text("\(content.count) characters")
                }
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 24)
            }
        }
    }

    private var wordCount: Int {
        content.split(whereSeparator: { $0.isWhitespace }).count
    }

    private func save() {
        // Refuse to create empty notes from a stray tap on Save.
        if title.isEmpty && content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            dismiss()
            return
        }

        if let note {
            let changed = note.title != title
                || note.content != content
                || note.isPinned != isPinned
                || note.isLocked != isLocked
                || note.tag?.id != selectedTag?.id

            note.title = title
            note.content = content
            note.isPinned = isPinned
            note.isLocked = isLocked
            note.tag = selectedTag
            // Only bump the timestamp when something actually changed, so an
            // open-then-close does not reorder the feed.
            if changed { note.updatedAt = Date() }
        } else {
            let created = Note(
                title: title,
                content: content,
                isPinned: isPinned,
                isLocked: isLocked,
                tag: selectedTag
            )
            context.insert(created)
            persistedNote = created
        }
        try? context.save()
        dismiss()
    }

    private func sendToTelegram(_ config: SyncConfig) {
        guard !isSendingTelegram else { return }

        isSendingTelegram = true
        syncStatus = "Sending…"

        Task {
            let service = TelegramSyncService()
            let messageId = await service.sendNoteToTelegram(
                botToken: config.telegramBotToken,
                chatId: config.telegramChatId,
                noteTitle: title.isEmpty ? "Quick note" : title,
                noteContent: content
            )
            isSendingTelegram = false
            syncStatus = service.statusMessage

            // Remember what was sent so a re-send can be recognised later.
            if let messageId {
                if let note {
                    note.telegramMessageId = messageId
                } else if let created = persistedNote {
                    created.telegramMessageId = messageId
                }
                try? context.save()
            }

            // Let the confirmation linger briefly, then fade it out.
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.easeInOut(duration: 0.2)) {
                if syncStatus == service.statusMessage { syncStatus = nil }
            }
        }
    }
}

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

