import SwiftUI
import SwiftData

struct FolderManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Folder.createdAt) private var folders: [Folder]
    @Query private var notes: [Note]

    @State private var newFolderName = ""
    @State private var newFolderColorHex = "#007AFF"
    @State private var folderPendingDeletion: Folder?

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        // Create folder
                        GlassCard(cornerRadius: 20) {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("New Folder", systemImage: "folder.badge.plus")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                HStack(spacing: 10) {
                                    TextField("Folder name", text: $newFolderName)
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
                                ColorPickerRow(selection: $newFolderColorHex)
                            }
                        }

                        // Existing folders
                        if !folders.isEmpty {
                            GlassCard(cornerRadius: 20) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("Folders", systemImage: "folder")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)
                                    ForEach(folders) { folder in
                                        HStack(spacing: 10) {
                                            Image(systemName: folder.iconName)
                                                .foregroundStyle(folder.color)
                                                .frame(width: 22)
                                            Text(folder.name)
                                                .font(.system(size: 14)).foregroundStyle(.white)
                                            Spacer()
                                            let count = notes.filter { $0.folderID == folder.id }.count
                                            Text("\(count) note\(count == 1 ? "" : "s")")
                                                .font(.system(size: 11)).foregroundStyle(.tertiary)
                                            Button { folderPendingDeletion = folder } label: {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 12)).foregroundStyle(.secondary)
                                            }.buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Folders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .confirmationDialog("Delete folder?",
            isPresented: Binding(get: { folderPendingDeletion != nil },
                                 set: { if !$0 { folderPendingDeletion = nil } }),
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

    private func addFolder() {
        let name = newFolderName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        context.insert(Folder(name: name, colorHex: newFolderColorHex))
        try? context.save(); newFolderName = ""
    }
}
