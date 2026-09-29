import SwiftUI
import SwiftData

public struct QuickStreamView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]
    @Query private var tags: [CategoryTag]
    
    @State private var searchText: String = ""
    @State private var selectedTag: CategoryTag? = nil
    @State private var quickText: String = ""
    @State private var activeNoteForEdit: Note? = nil
    @State private var showNewNoteEditor: Bool = false
    @State private var showSettings: Bool = false
    
    public init() {}
    
    public var filteredNotes: [Note] {
        notes.filter { note in
            let matchesSearch = searchText.isEmpty ||
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText)
            let matchesTag = selectedTag == nil || note.tag?.id == selectedTag?.id
            return matchesSearch && matchesTag && !note.isArchived
        }
        .sorted { ($0.isPinned ? 1 : 0) > ($1.isPinned ? 1 : 0) }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()
                
                VStack(spacing: 12) {
                    // Header Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("GlassNotes")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            Text("Private Scratchpad & Vault")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(10)
                                .background(.thinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Search Bar
                    GlassSearchBar(text: $searchText, placeholder: "Search private notes...")
                        .padding(.horizontal, 20)
                    
                    // Tag Category Scroll Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            TagPill(title: "All", icon: "sparkles", isSelected: selectedTag == nil) {
                                selectedTag = nil
                            }
                            
                            ForEach(tags) { tag in
                                TagPill(title: tag.name, icon: tag.iconName, isSelected: selectedTag?.id == tag.id, color: tag.color) {
                                    if selectedTag?.id == tag.id {
                                        selectedTag = nil
                                    } else {
                                        selectedTag = tag
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Notes List Stream
                    if filteredNotes.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "note.text.badge.plus")
                                .font(.system(size: 54))
                                .foregroundColor(.white.opacity(0.3))
                            Text("No notes found")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            Text("Type below for instant scratchpad dumping or tap +")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(filteredNotes) { note in
                                    NoteCardView(note: note) {
                                        activeNoteForEdit = note
                                    }
                                    .contextMenu {
                                        Button(action: { togglePin(note) }) {
                                            Label(note.isPinned ? "Unpin" : "Pin Note", systemImage: "pin")
                                        }
                                        Button(action: { toggleLock(note) }) {
                                            Label(note.isLocked ? "Unlock Note" : "Lock Note", systemImage: "lock")
                                        }
                                        Button(role: .destructive, action: { deleteNote(note) }) {
                                            Label("Delete Note", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 90)
                        }
                    }
                }
                
                // Telegram-Style Instant Quick Scratchpad Input Bar at Bottom
                VStack {
                    Spacer()
                    
                    HStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.yellow)
                            
                            TextField("Quick note stream...", text: $quickText)
                                .foregroundColor(.white)
                                .accentColor(.cyan)
                                .onSubmit { sendQuickNote() }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        Button(action: sendQuickNote) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
                                )
                                .shadow(color: .cyan.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .disabled(quickText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
            }
            .navigationDestination(isPresented: $showNewNoteEditor) {
                NoteEditorView(note: nil)
            }
            .sheet(item: $activeNoteForEdit) { note in
                NoteEditorView(note: note)
            }
            .sheet(isPresented: $showSettings) {
                SyncSettingsView()
            }
        }
    }
    
    private func sendQuickNote() {
        let text = quickText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let newNote = Note(
            title: "",
            content: text,
            createdAt: Date(),
            updatedAt: Date()
        )
        modelContext.insert(newNote)
        try? modelContext.save()
        quickText = ""
        
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    
    private func togglePin(_ note: Note) {
        note.isPinned.toggle()
        try? modelContext.save()
    }
    
    private func toggleLock(_ note: Note) {
        note.isLocked.toggle()
        try? modelContext.save()
    }
    
    private func deleteNote(_ note: Note) {
        modelContext.delete(note)
        try? modelContext.save()
    }
}

struct TagPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var color: Color = .cyan
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.8) : Color.white.opacity(0.12))
                    .overlay(
                        Capsule().stroke(isSelected ? Color.white.opacity(0.6) : Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }
}
