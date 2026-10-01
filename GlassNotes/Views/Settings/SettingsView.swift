import SwiftUI
import SwiftData
import PhotosUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appearance: AppearanceStore
    @EnvironmentObject private var auth: BiometricAuthService
    @Query private var configs: [SyncConfig]
    @Query private var tags: [CategoryTag]
    @Query private var folders: [Folder]
    @Query private var notes: [Note]

    @State private var botToken = ""
    @State private var chatId = ""
    @State private var isBiometricLockOn = false
    @State private var autoLockMinutes = 0
    @State private var hapticsEnabled = true
    @State private var searchUnlockedBody = false
    @State private var includeLockedNotes = false
    @State private var newTagName = ""
    @State private var newTagColorHex = TagPalette.defaults.first ?? "#007AFF"
    @State private var newFolderName = ""
    @State private var newFolderColorHex = TagPalette.defaults.first ?? "#007AFF"
    @State private var photoSelection: PhotosPickerItem?
    @State private var customAccent = Color(hex: "#007AFF")
    @State private var newPresetName = ""
    @State private var tagPendingDeletion: CategoryTag?
    @State private var folderPendingDeletion: Folder?

    private var config: SyncConfig? { configs.first }
    private let autoLockOptions = [0, 1, 5, 15, 30]

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        appearanceSection
                        hapticsSection
                        privacySection
                        telegramSection
                        tagsSection
                        foldersSection
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

    // MARK: - Appearance

    private var appearanceSection: some View {
        SettingsGroup(title: "Appearance", systemImage: "paintpalette") {
            // Wallpapers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(Wallpaper.allCases) { option in
                    Button { appearance.wallpaper = option } label: {
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

            // Photo picker
            HStack(spacing: 10) {
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
                    Button { appearance.clearPhoto() } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundStyle(.white)
                            .padding(10)
                            .liquidGlass(GlassConfig(cornerRadius: 12, interactive: true))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Accent color
            VStack(alignment: .leading, spacing: 8) {
                Text("Accent colour")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    ForEach(TagPalette.defaults, id: \.self) { hex in
                        Button {
                            appearance.accentColorHex = hex
                            saveAccentColor(hex)
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 26, height: 26)
                                .overlay {
                                    Circle().strokeBorder(.white,
                                        lineWidth: appearance.accentColorHex == hex ? 2.5 : 0)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
            }

            accentCustomSection

            // Font size
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Editor font size")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(appearance.editorFontSize)) pt")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $appearance.editorFontSize, in: 12...24, step: 1)
                    .tint(Color(hex: appearance.accentColorHex))
                    .onChange(of: appearance.editorFontSize) { _, size in
                        saveFontSize(size)
                    }
            }
        }
    }

    // MARK: - Custom accent colours

    private var accentCustomSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ColorPicker("", selection: $customAccent, supportsOpacity: false)
                    .labelsHidden()
                Text("Custom")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(customAccent.hexString())
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
                Button("Use") {
                    let hex = customAccent.hexString()
                    appearance.accentColorHex = hex
                    saveAccentColor(hex)
                }
                .font(.system(size: 12, weight: .semibold))
                .buttonStyle(.plain)
                .foregroundStyle(.white)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .liquidGlass(GlassConfig(cornerRadius: 12, interactive: true))

            // Name + save, so presets are recognisable rather than bare swatches.
            HStack(spacing: 10) {
                TextField("Preset name", text: $newPresetName)
                    .font(.system(size: 13))
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .liquidGlass(GlassConfig(cornerRadius: 12))
                Button(action: saveCustomPreset) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 38)
                        .liquidGlass(GlassConfig(cornerRadius: 12, interactive: true))
                }
                .buttonStyle(.plain)
                .disabled(newPresetName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if !appearance.accentPresets.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(appearance.accentPresets) { preset in
                            Button {
                                appearance.accentColorHex = preset.hex
                                saveAccentColor(preset.hex)
                            } label: {
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(Color(hex: preset.hex))
                                        .frame(width: 26, height: 26)
                                        .overlay {
                                            Circle().strokeBorder(
                                                .white,
                                                lineWidth: appearance.accentColorHex
                                                    .uppercased() == preset.hex.uppercased() ? 2.5 : 0
                                            )
                                        }
                                    Text(preset.name)
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                .frame(width: 52)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Delete", role: .destructive) {
                                    appearance.removePreset(hex: preset.hex)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func saveCustomPreset() {
        let name = newPresetName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        appearance.savePreset(named: name, hex: customAccent.hexString())
        newPresetName = ""
    }

    // MARK: - Haptics

    private var hapticsSection: some View {
        SettingsGroup(title: "Haptics", systemImage: "hand.tap") {
            Toggle(isOn: $hapticsEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Haptic feedback")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                    Text("Taps, swipes, and important actions")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Color(hex: appearance.accentColorHex))
            .onChange(of: hapticsEnabled) { _, on in saveHaptics(on) }
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        SettingsGroup(title: "Privacy & Security", systemImage: "lock.shield") {
            Toggle(isOn: $isBiometricLockOn) {
                Text("Require authentication to open")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
            }
            .tint(Color(hex: appearance.accentColorHex))
            .onChange(of: isBiometricLockOn) { _, enabled in setBiometricLock(enabled) }

            // Auto-lock timer
            if isBiometricLockOn {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Auto-lock")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Picker("Auto-lock", selection: $autoLockMinutes) {
                        Text("Never").tag(0)
                        Text("1 min").tag(1)
                        Text("5 min").tag(5)
                        Text("15 min").tag(15)
                        Text("30 min").tag(30)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: autoLockMinutes) { _, mins in saveAutoLock(mins) }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut, value: isBiometricLockOn)

                // Search locked body toggle — only useful once authenticated
                if auth.isUnlocked {
                    Toggle(isOn: $searchUnlockedBody) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Search locked note bodies")
                                .font(.system(size: 13))
                                .foregroundStyle(.white)
                            Text("When on, search can match inside locked notes.")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(Color(hex: appearance.accentColorHex))
                    .onChange(of: searchUnlockedBody) { _, on in saveSearchUnlocked(on) }
                }
            }
        }
    }

    // MARK: - Telegram

    private var telegramSection: some View {
        SettingsGroup(title: "Telegram", systemImage: "paperplane") {
            LabeledField(title: "Bot token", text: $botToken, placeholder: "123456:ABCdef")
            LabeledField(title: "Chat ID", text: $chatId, placeholder: "987654321",
                         keyboard: .numbersAndPunctuation)
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

    // MARK: - Tags

    private var tagsSection: some View {
        SettingsGroup(title: "Tags", systemImage: "tag") {
            HStack(spacing: 10) {
                TextField("New tag", text: $newTagName)
                    .font(.system(size: 14))
                    .padding(.horizontal, 12).padding(.vertical, 10)
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

            ColorPickerRow(selection: $newTagColorHex)

            ForEach(tags) { tag in
                HStack(spacing: 10) {
                    Image(systemName: tag.iconName).font(.system(size: 13)).foregroundStyle(tag.color).frame(width: 22)
                    Text(tag.name).font(.system(size: 14)).foregroundStyle(.white)
                    Spacer()
                    let noteCount = notes.filter { $0.tags.contains(where: { $0.id == tag.id }) }.count
                    if noteCount > 0 {
                        Text("\(noteCount)").font(.system(size: 11)).foregroundStyle(.tertiary)
                    }
                    Button { tagPendingDeletion = tag } label: {
                        Image(systemName: "trash").font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .confirmationDialog("Delete tag?",
            isPresented: Binding(get: { tagPendingDeletion != nil }, set: { if !$0 { tagPendingDeletion = nil } }),
            titleVisibility: .visible, presenting: tagPendingDeletion
        ) { tag in
            Button("Delete \"\(tag.name)\"", role: .destructive) {
                context.delete(tag); try? context.save(); tagPendingDeletion = nil
            }
            Button("Cancel", role: .cancel) { tagPendingDeletion = nil }
        } message: { tag in
            let count = notes.filter { $0.tags.contains(where: { $0.id == tag.id }) }.count
            Text(count == 0 ? "This tag is not in use."
                 : "\(count) note\(count == 1 ? "" : "s") will lose this tag.")
        }
    }

    // MARK: - Folders

    private var foldersSection: some View {
        SettingsGroup(title: "Folders", systemImage: "folder") {
            HStack(spacing: 10) {
                TextField("New folder", text: $newFolderName)
                    .font(.system(size: 14))
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .liquidGlass(GlassConfig(cornerRadius: 12))
                    .onSubmit(addFolder)
                Button(action: addFolder) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 38)
                        .liquidGlass(GlassConfig(cornerRadius: 12, interactive: true))
                }
                .buttonStyle(.plain)
                .disabled(newFolderName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            ForEach(folders) { folder in
                HStack(spacing: 10) {
                    Image(systemName: folder.iconName).font(.system(size: 13)).foregroundStyle(folder.color).frame(width: 22)
                    Text(folder.name).font(.system(size: 14)).foregroundStyle(.white)
                    Spacer()
                    let count = notes.filter { $0.folderID == folder.id }.count
                    if count > 0 {
                        Text("\(count)").font(.system(size: 11)).foregroundStyle(.tertiary)
                    }
                    Button { folderPendingDeletion = folder } label: {
                        Image(systemName: "trash").font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .confirmationDialog("Delete folder?",
            isPresented: Binding(get: { folderPendingDeletion != nil }, set: { if !$0 { folderPendingDeletion = nil } }),
            titleVisibility: .visible, presenting: folderPendingDeletion
        ) { folder in
            Button("Delete \"\(folder.name)\"", role: .destructive) {
                // `folderID` is a raw UUID, not a relationship, so deleting the
                // folder leaves it dangling unless the notes are cleared here.
                for note in notes where note.folderID == folder.id { note.folderID = nil }
                context.delete(folder); try? context.save(); folderPendingDeletion = nil
            }
            Button("Cancel", role: .cancel) { folderPendingDeletion = nil }
        } message: { folder in
            let count = notes.filter { $0.folderID == folder.id }.count
            Text(count == 0 ? "This folder is empty."
                 : "\(count) note\(count == 1 ? "" : "s") will be moved out of this folder.")
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        SettingsGroup(title: "Data", systemImage: "externaldrive") {
            HStack {
                Text("\(notes.count) notes stored on this device")
                    .font(.system(size: 13)).foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 8) {
                    // JSON export
                    ShareLink(item: jsonExportPayload, preview: SharePreview("GlassNotes.json")) {
                        Image(systemName: "curlybraces")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .padding(9)
                            .liquidGlass(GlassConfig(cornerRadius: 999, interactive: true))
                    }
                    .accessibilityLabel("Export notes as JSON")

                    // Markdown export (all notes as .md files in a zip)
                    ShareLink(item: markdownExportFile,
                              preview: SharePreview("GlassNotes.md")) {
                        Image(systemName: "doc.plaintext")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .padding(9)
                            .liquidGlass(GlassConfig(cornerRadius: 999, interactive: true))
                    }
                    .accessibilityLabel("Export notes as Markdown")
                }
            }

            Toggle(isOn: $includeLockedNotes) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Include locked notes in export")
                        .font(.system(size: 13)).foregroundStyle(.white)
                    Text(includeLockedNotes
                         ? "Locked note bodies will be exported in plain text."
                         : "Locked note bodies are redacted from the export.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
            .tint(Color(hex: appearance.accentColorHex))
        }
    }

    // MARK: - Export helpers

    private var jsonExportPayload: String {
        let payload = notes.sorted { $0.updatedAt > $1.updatedAt }
            .map { NoteRecord(note: $0, includeContent: includeLockedNotes || !$0.isLocked) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload) else { return "[]" }
        return String(decoding: data, as: UTF8.self)
    }

    private var markdownExportFile: URL {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("GlassNotes.md")
        let sorted = notes.sorted { $0.updatedAt > $1.updatedAt }
        var lines: [String] = []
        for note in sorted {
            if note.isLocked && !includeLockedNotes { continue }
            lines.append("# \(note.displayTitle)")
            lines.append("")
            lines.append(note.content)
            lines.append("")
            lines.append("---")
            lines.append("")
        }
        try? lines.joined(separator: "\n").write(to: tmp, atomically: true, encoding: .utf8)
        return tmp
    }

    // MARK: - Load / Save helpers

    private func load() {
        botToken = config?.telegramBotToken ?? ""
        chatId = config?.telegramChatId ?? ""
        isBiometricLockOn = config?.biometricLockEnabled ?? false
        autoLockMinutes = config?.autoLockMinutes ?? 0
        hapticsEnabled = config?.hapticsEnabled ?? true
        searchUnlockedBody = config?.searchUnlockedBody ?? false
    }

    private func ensureConfig() -> SyncConfig {
        if let c = config { return c }
        let c = SyncConfig(); context.insert(c); return c
    }

    private func saveTelegram() {
        let c = ensureConfig()
        c.telegramBotToken = botToken; c.telegramChatId = chatId
        try? context.save()
    }

    private func setBiometricLock(_ enabled: Bool) {
        let c = ensureConfig(); c.biometricLockEnabled = enabled; try? context.save()
    }

    private func saveAutoLock(_ mins: Int) {
        let c = ensureConfig(); c.autoLockMinutes = mins; try? context.save()
    }

    private func saveHaptics(_ on: Bool) {
        let c = ensureConfig(); c.hapticsEnabled = on; try? context.save()
    }

    private func saveSearchUnlocked(_ on: Bool) {
        let c = ensureConfig(); c.searchUnlockedBody = on; try? context.save()
    }

    private func saveAccentColor(_ hex: String) {
        let c = ensureConfig(); c.accentColorHex = hex; try? context.save()
    }

    private func saveFontSize(_ size: CGFloat) {
        let c = ensureConfig(); c.editorFontSize = Double(size); try? context.save()
    }

    private func addTag() {
        let name = newTagName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        context.insert(CategoryTag(name: name, colorHex: newTagColorHex))
        try? context.save(); newTagName = ""
    }

    private func addFolder() {
        let name = newFolderName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        context.insert(Folder(name: name, colorHex: newFolderColorHex))
        try? context.save(); newFolderName = ""
    }

    private func applyPhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        appearance.photo = UIImage(data: data)
    }
}

// MARK: - Supporting types (kept in same file for convenience)

struct NoteRecord: Encodable {
    let id: String; let title: String; let content: String
    let tags: [String]; let pinned: Bool; let locked: Bool
    let redacted: Bool; let createdAt: Date; let updatedAt: Date
    init(note: Note, includeContent: Bool) {
        id = note.id.uuidString; title = note.title
        content = includeContent ? note.content : ""
        tags = note.tags.map(\.name)
        pinned = note.isPinned; locked = note.isLocked
        redacted = !includeContent
        createdAt = note.createdAt; updatedAt = note.updatedAt
    }
}

struct SettingsGroup<Content: View>: View {
    let title: String; let systemImage: String
    @ViewBuilder let content: Content
    var body: some View {
        GlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Label(title, systemImage: systemImage)
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                content
            }
        }
    }
}

struct LabeledField: View {
    let title: String; @Binding var text: String
    let placeholder: String; var keyboard: UIKeyboardType = .default
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .font(.system(size: 14))
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .keyboardType(keyboard).padding(.horizontal, 12).padding(.vertical, 10)
                .liquidGlass(GlassConfig(cornerRadius: 12))
        }
    }
}

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
            Text("Colour").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(TagPalette.defaults, id: \.self) { hex in
                    Button { selection = hex } label: {
                        Circle().fill(Color(hex: hex)).frame(width: 24, height: 24)
                            .overlay { Circle().strokeBorder(.white, lineWidth: selection == hex ? 2.5 : 0) }
                            .overlay { Circle().strokeBorder(.black.opacity(0.25), lineWidth: 1) }
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }
        }
    }
}
