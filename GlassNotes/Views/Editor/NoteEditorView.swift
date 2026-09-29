import SwiftUI
import SwiftData

public struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var tags: [CategoryTag]
    @Query private var syncConfigs: [SyncConfig]
    
    @State private var noteTitle: String = ""
    @State private var noteContent: String = ""
    @State private var isPinned: Bool = false
    @State private var isLocked: Bool = false
    @State private var selectedTag: CategoryTag? = nil
    @State private var isPreviewMode: Bool = false
    @State private var isSyncing: Bool = false
    @State private var syncStatus: String? = nil
    
    private var noteToEdit: Note?
    
    public init(note: Note?) {
        self.noteToEdit = note
        _noteTitle = State(initialValue: note?.title ?? "")
        _noteContent = State(initialValue: note?.content ?? "")
        _isPinned = State(initialValue: note?.isPinned ?? false)
        _isLocked = State(initialValue: note?.isLocked ?? false)
        _selectedTag = State(initialValue: note?.tag)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()
                
                VStack(spacing: 14) {
                    // Header Bar
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // Mode Switcher (Edit / Preview)
                        Picker("View Mode", selection: $isPreviewMode) {
                            Text("Edit").tag(false)
                            Text("Preview").tag(true)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 140)
                        
                        Spacer()
                        
                        Button(action: saveNote) {
                            Text("Save")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Options Pill Bar (Pin, Lock, Tag, Telegram Sync)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            Button(action: { isPinned.toggle() }) {
                                OptionPill(icon: "pin.fill", title: isPinned ? "Pinned" : "Pin", isActive: isPinned, activeColor: .yellow)
                            }
                            
                            Button(action: { isLocked.toggle() }) {
                                OptionPill(icon: "lock.fill", title: isLocked ? "Locked" : "Lock", isActive: isLocked, activeColor: .cyan)
                            }
                            
                            // Tag Selector Menu
                            Menu {
                                Button("None") { selectedTag = nil }
                                ForEach(tags) { tag in
                                    Button(action: { selectedTag = tag }) {
                                        Label(tag.name, systemImage: tag.iconName)
                                    }
                                }
                            } label: {
                                OptionPill(
                                    icon: selectedTag?.iconName ?? "tag",
                                    title: selectedTag?.name ?? "Tag",
                                    isActive: selectedTag != nil,
                                    activeColor: selectedTag?.color ?? .purple
                                )
                            }
                            
                            // Send to Telegram Action
                            if let config = syncConfigs.first, !config.telegramBotToken.isEmpty {
                                Button(action: sendToTelegram) {
                                    OptionPill(icon: "paperplane.fill", title: "Send Telegram", isActive: false, activeColor: .blue)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    if let syncStatus = syncStatus {
                        Text(syncStatus)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 20)
                    }
                    
                    // Main Title Field
                    TextField("", text: $noteTitle, prompt: Text("Title (Optional)").foregroundColor(.white.opacity(0.4)))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.horizontal, 20)
                    
                    // Body Content / Markdown Preview
                    if isPreviewMode {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(LocalizedStringKey(noteContent.isEmpty ? "*No markdown content to preview.*" : noteContent))
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                                    .tint(.cyan)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
                            )
                            .padding(.horizontal, 20)
                        }
                    } else {
                        VStack(spacing: 8) {
                            TextEditor(text: $noteContent)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
                                )
                                .padding(.horizontal, 20)
                            
                            FormattingBar(text: $noteContent)
                                .padding(.horizontal, 20)
                        }
                    }
                    
                    // Footer Info
                    HStack {
                        Text("\(wordCount(noteContent)) words • \(noteContent.count) characters")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }
            }
        }
    }
    
    private func wordCount(_ text: String) -> Int {
        text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    private func saveNote() {
        if let existing = noteToEdit {
            existing.title = noteTitle
            existing.content = noteContent
            existing.isPinned = isPinned
            existing.isLocked = isLocked
            existing.tag = selectedTag
            existing.updatedAt = Date()
        } else {
            let newNote = Note(
                title: noteTitle,
                content: noteContent,
                createdAt: Date(),
                updatedAt: Date(),
                isPinned: isPinned,
                isLocked: isLocked,
                tag: selectedTag
            )
            modelContext.insert(newNote)
        }
        
        try? modelContext.save()
        dismiss()
    }
    
    private func sendToTelegram() {
        guard let config = syncConfigs.first else { return }
        isSyncing = true
        syncStatus = "Sending to Telegram..."
        
        Task {
            let service = TelegramSyncService()
            let titleToUse = noteTitle.isEmpty ? "Quick Note" : noteTitle
            let success = await service.sendNoteToTelegram(
                botToken: config.telegramBotToken,
                chatId: config.telegramChatId,
                noteTitle: titleToUse,
                noteContent: noteContent
            )
            
            isSyncing = false
            syncStatus = service.statusMessage
        }
    }
}

struct OptionPill: View {
    let icon: String
    let title: String
    let isActive: Bool
    let activeColor: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(title)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isActive ? activeColor.opacity(0.8) : Color.white.opacity(0.12))
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
        )
    }
}
