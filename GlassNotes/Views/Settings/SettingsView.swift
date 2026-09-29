import SwiftUI
import SwiftData
import PhotosUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appearance: AppearanceStore
    @Query private var configs: [SyncConfig]
    @Query private var tags: [CategoryTag]
    @Query private var notes: [Note]

    @State private var botToken = ""
    @State private var chatId = ""
    @State private var isBiometricLockOn = false
    @State private var newTagName = ""
    @State private var photoSelection: PhotosPickerItem?
    @State private var includeLockedNotes = false
    @State private var tagPendingDeletion: CategoryTag?
    @State private var newTagColorHex = TagPalette.defaults.first ?? "#007AFF"

    private var config: SyncConfig? { configs.first }

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        appearanceSection
                        telegramSection
                        securitySection
                        tagsSection
                        dataSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { load() }
            .onChange(of: photoSelection) { _, item in
                Task { await applyPhotoSelection(item) }
            }
        }
    }

    private var appearanceSection: some View {
        SettingsGroup(title: "Background", systemImage: "photo.on.rectangle.angled") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(Wallpaper.allCases) { option in
                    Button {
                        appearance.wallpaper = option
                    } label: {
                        VStack(spacing: 5) {
                            WallpaperPreview(
                                wallpaper: option,
                                isSelected: !appearance.usesPhoto && appearance.wallpaper == option
                            )
                            .frame(height: 62)
                            Text(option.label)
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                // Read the flag here rather than inside the label closure, which
                // is @Sendable and cannot touch main-actor state.
                let photoButtonTitle = appearance.usesPhoto ? "Change photo" : "Choose photo"

                PhotosPicker(selection: $photoSelection, matching: .images, photoLibrary: .shared()) {
                    Label(photoButtonTitle, systemImage: "photo")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .liquidGlass(GlassConfig(cornerRadius: 12, interactive: true))
                }

                if appearance.usesPhoto {
                    Button {
                        appearance.clearPhoto()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundStyle(.white)
                            .padding(10)
                            .liquidGlass(GlassConfig(cornerRadius: 12, interactive: true))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var telegramSection: some View {
        SettingsGroup(title: "Telegram", systemImage: "paperplane") {
            LabeledField(title: "Bot token", text: $botToken, placeholder: "123456:ABCdef")
            LabeledField(title: "Chat ID", text: $chatId, placeholder: "987654321", keyboard: .numbersAndPunctuation)

            Button(action: saveTelegram) {
                Text("Save credentials")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .liquidGlass(GlassConfig(cornerRadius: 12, interactive: true))
            }
            .buttonStyle(.plain)
        }
    }

    private var securitySection: some View {
        SettingsGroup(title: "Security", systemImage: "lock.shield") {
            Toggle(isOn: $isBiometricLockOn) {
                Text("Require authentication")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
            }
            .onChange(of: isBiometricLockOn) { _, enabled in
                setBiometricLock(enabled)
            }
        }
    }

    private var tagsSection: some View {
        SettingsGroup(title: "Tags", systemImage: "tag") {
            HStack(spacing: 10) {
                TextField("New tag", text: $newTagName)
                    .font(.system(size: 14))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .liquidGlass(GlassConfig(cornerRadius: 12))
                    .onSubmit(addTag)

                Button(action: addTag) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 38)
                        .liquidGlass(GlassConfig(cornerRadius: 12, interactive: true))
                }
                .buttonStyle(.plain)
                .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            ForEach(tags) { tag in
                HStack(spacing: 10) {
                    Image(systemName: tag.iconName)
                        .font(.system(size: 13))
                        .foregroundStyle(tag.color)
                        .frame(width: 22)
                    Text(tag.name)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        tagPendingDeletion = tag
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete \(tag.name)")
                }
            }

            ColorPickerRow(selection: $newTagColorHex)
        }
        .confirmationDialog(
            "Delete tag?",
            isPresented: Binding(
                get: { tagPendingDeletion != nil },
                set: { if !$0 { tagPendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: tagPendingDeletion
        ) { tag in
            Button("Delete \"\(tag.name)\"", role: .destructive) {
                context.delete(tag)
                try? context.save()
                tagPendingDeletion = nil
            }
            Button("Cancel", role: .cancel) { tagPendingDeletion = nil }
        } message: { tag in
            let count = notes.filter { $0.tag?.id == tag.id }.count
            // `message:` is a ViewBuilder, so this must be a View, not a String.
            Text(count == 0
                 ? "This tag is not in use."
                 : "\(count) note\(count == 1 ? "" : "s") will lose this tag. The notes themselves are kept.")
                .font(.system(size: 13))
        }
    }

    private var dataSection: some View {
        SettingsGroup(title: "Data", systemImage: "externaldrive") {
            HStack {
                Text("\(notes.count) notes stored on this device")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Spacer()
                ShareLink(item: exportPayload, preview: SharePreview("GlassNotes.json")) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .padding(9)
                        .liquidGlass(GlassConfig(cornerRadius: 999, interactive: true))
                }
                .accessibilityLabel("Export notes as JSON")
            }

            Toggle(isOn: $includeLockedNotes) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Include locked notes")
                        .font(.system(size: 13))
                        .foregroundStyle(.white)
                    Text(includeLockedNotes
                         ? "Locked note bodies will be exported in plain text."
                         : "Locked note bodies are redacted from the export.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.accentColor)
        }
    }

    private var exportPayload: String {
        let payload = notes
            .sorted { $0.updatedAt > $1.updatedAt }
            .map { NoteRecord(note: $0, includeContent: includeLockedNotes || !$0.isLocked) }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(payload) else { return "[]" }
        return String(decoding: data, as: UTF8.self)
    }

    private func load() {
        botToken = config?.telegramBotToken ?? ""
        chatId = config?.telegramChatId ?? ""
        isBiometricLockOn = config?.biometricLockEnabled ?? false
    }

    private func saveTelegram() {
        let target = config ?? {
            let created = SyncConfig()
            context.insert(created)
            return created
        }()

        target.telegramBotToken = botToken
        target.telegramChatId = chatId
        try? context.save()
    }

    private func setBiometricLock(_ enabled: Bool) {
        let target = config ?? {
            let created = SyncConfig()
            context.insert(created)
            return created
        }()

        target.biometricLockEnabled = enabled
        try? context.save()
    }

    private func addTag() {
        let name = newTagName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        context.insert(CategoryTag(name: name, colorHex: newTagColorHex))
        try? context.save()
        newTagName = ""
    }

    private func applyPhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        appearance.photo = UIImage(data: data)
    }
}

struct NoteRecord: Encodable {
    let id: String
    let title: String
    let content: String
    let tag: String
    let pinned: Bool
    let locked: Bool
    let redacted: Bool
    let createdAt: Date
    let updatedAt: Date

    /// - Parameter includeContent: when `false` the body is replaced with a
    ///   placeholder so an export cannot leak a note the user chose to lock.
    init(note: Note, includeContent: Bool) {
        id = note.id.uuidString
        title = note.title
        content = includeContent ? note.content : ""
        tag = note.tag?.name ?? ""
        pinned = note.isPinned
        locked = note.isLocked
        redacted = !includeContent
        createdAt = note.createdAt
        updatedAt = note.updatedAt
    }
}


struct SettingsGroup<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        GlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Label(title, systemImage: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                content
            }
        }
    }
}

struct LabeledField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .font(.system(size: 14))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(keyboard)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .liquidGlass(GlassConfig(cornerRadius: 12))
        }
    }
}

/// Fixed palette used when creating tags. Keeping it curated (rather than a
/// free colour picker) means tag colours stay legible against every wallpaper.
enum TagPalette {
    static let defaults = [
        "#FF9500", "#007AFF", "#34C759", "#AF52DE",
        "#FF3B30", "#FF2D55", "#00C7BE", "#FFD60A",
    ]
}

struct ColorPickerRow: View {
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("New tag colour")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(TagPalette.defaults, id: \.self) { hex in
                    Button {
                        selection = hex
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 24, height: 24)
                            .overlay {
                                Circle().strokeBorder(.white, lineWidth: selection == hex ? 2.5 : 0)
                            }
                            .overlay {
                                Circle().strokeBorder(.black.opacity(0.25), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Tag colour \(hex)")
                    .accessibilityAddTraits(selection == hex ? [.isSelected] : [])
                }
                Spacer(minLength: 0)
            }
        }
    }
}
