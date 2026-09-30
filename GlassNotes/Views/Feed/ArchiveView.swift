import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Note> { $0.isArchived }, sort: \Note.updatedAt, order: .reverse)
    private var archivedNotes: [Note]

    @State private var editingNote: Note?

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()

                if archivedNotes.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(.tertiary)
                        Text("Archive is empty")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("Swipe a note left and tap Archive to move it here.")
                            .font(.system(size: 13))
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(archivedNotes) { note in
                                NoteCardView(note: note) { editingNote = note }
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button {
                                            note.isArchived = false
                                            try? context.save()
                                        } label: {
                                            Label("Unarchive", systemImage: "arrow.uturn.up")
                                        }
                                        .tint(.green)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
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
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Archive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $editingNote) { note in
                NoteEditorView(note: note)
            }
        }
    }
}
