import SwiftUI
import SwiftData

@main
struct GlassNotesApp: App {
    @StateObject private var auth = BiometricAuthService()
    @StateObject private var appearance = AppearanceStore()

    private let container: ModelContainer = {
        let schema = Schema([Note.self, CategoryTag.self, SyncConfig.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainContentView()
                .environmentObject(auth)
                .environmentObject(appearance)
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}

struct MainContentView: View {
    @EnvironmentObject private var auth: BiometricAuthService
    @Environment(\.modelContext) private var context
    @Query private var configs: [SyncConfig]
    @AppStorage("didSeedTags") private var didSeedTags = false

    private var isLocked: Bool {
        configs.first?.biometricLockEnabled ?? false
    }

    private let defaultTags: [(String, String, String)] = [
        ("Ideas", "#FF9500", "lightbulb.fill"),
        ("Work", "#007AFF", "briefcase.fill"),
        ("Personal", "#34C759", "person.fill"),
        ("Scratchpad", "#AF52DE", "bolt.fill"),
        ("Secret", "#FF3B30", "lock.fill")
    ]

    var body: some View {
        glassGroup {
            if isLocked && !auth.isUnlocked {
                LockView(authService: auth) { auth.isUnlocked = true }
            } else {
                QuickStreamView()
            }
        }
        .task { seedTagsIfNeeded() }
        .onAppear {
            if !isLocked {
                auth.isUnlocked = true
            }
        }
    }

    private func seedTagsIfNeeded() {
        guard !didSeedTags else { return }
        didSeedTags = true

        let existing = try? context.fetchCount(FetchDescriptor<CategoryTag>())
        guard existing == 0 else { return }

        for (name, hex, icon) in defaultTags {
            context.insert(CategoryTag(name: name, colorHex: hex, iconName: icon))
        }
        try? context.save()
    }
}

