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
                    ToggleChip(icon: "paperplane", title: "Telegram", tint: .white, isOn: false) {
                        sendToTelegram(config)
                    }
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
                Text(LocalizedStringKey(content.isEmpty ? "Nothing to preview." : content))
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .liquidGlass(GlassConfig.field)
                    .padding(.horizontal, 20)
            }
        } else {
            VStack(spacing: 10) {
                TextEditor(text: $content)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .liquidGlass(GlassConfig.field)
                    .padding(.horizontal, 20)

                FormattingBar(text: $content)
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
        if let note {
            note.title = title
            note.content = content
            note.isPinned = isPinned
            note.isLocked = isLocked
            note.tag = selectedTag
            note.updatedAt = Date()
        } else {
            context.insert(
                Note(
                    title: title,
                    content: content,
                    isPinned: isPinned,
                    isLocked: isLocked,
                    tag: selectedTag
                )
            )
        }
        try? context.save()
        dismiss()
    }

    private func sendToTelegram(_ config: SyncConfig) {
        syncStatus = "Sending…"
        let heading = title.isEmpty ? "Quick note" : title
        let body = content

        Task {
            let service = TelegramSyncService()
            _ = await service.sendNoteToTelegram(
                botToken: config.telegramBotToken,
                chatId: config.telegramChatId,
                noteTitle: heading,
                noteContent: body
            )
            syncStatus = service.statusMessage
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

