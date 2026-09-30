import SwiftUI
import SwiftData

@main
struct GlassNotesApp: App {
    @StateObject private var auth = BiometricAuthService()
    @StateObject private var appearance = AppearanceStore()
    @StateObject private var autoLock = AutoLockService()

    /// `nil` only when even an in-memory store cannot be built, i.e. the schema
    /// itself is invalid. `storeError` then explains why, on screen.
    private let container: ModelContainer?
    private let storeError: String?

    private static func makeContainer() -> (ModelContainer?, String?) {
        let schema = Schema([Note.self, CategoryTag.self, SyncConfig.self, Folder.self])
        #if CLOUDKIT_ENABLED
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.glassnotes.app")
        )
        #else
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        #endif
        do {
            return (try ModelContainer(for: schema, configurations: [configuration]), nil)
        } catch {
            // Never `fatalError` here. This runs before `body`, so a trap kills
            // the app with no frame drawn and no usable diagnostic — which is
            // exactly how a schema mistake presents as an instant, silent crash.
            // Degrade to an in-memory store and report the reason instead.
            let message = String(describing: error)
            do {
                let inMemory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return (try ModelContainer(for: schema, configurations: [inMemory]), message)
            } catch {
                return (nil, message + "\n\n" + String(describing: error))
            }
        }
    }

    init() {
        let result = Self.makeContainer()
        self.container = result.0
        self.storeError = result.1
    }

    var body: some Scene {
        WindowGroup {
            MainContentView()
                .environmentObject(auth)
                .environmentObject(appearance)
                .preferredColorScheme(.dark)
                .modifier(OptionalModelContainer(container: container, storeError: storeError))
        }
    }
}

/// Applies the container when it built successfully, otherwise shows the error.
private struct OptionalModelContainer: ViewModifier {
    let container: ModelContainer?
    let storeError: String?

    func body(content: Content) -> some View {
        if let container {
            content.modelContainer(container)
        } else {
            StoreFailureView(message: storeError ?? "Unknown store error.")
        }
    }
}

private struct StoreFailureView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Text("GlassNotes could not open its database")
                .font(.system(size: 18, weight: .semibold))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .multilineTextAlignment(.leading)
        }
        .padding(24)
    }
}

struct MainContentView: View {
    @EnvironmentObject private var auth: BiometricAuthService
    @EnvironmentObject private var appearance: AppearanceStore
    @Environment(\.modelContext) private var context
    @Query private var configs: [SyncConfig]
    @AppStorage("didSeedTags") private var didSeedTags = false

    private var config: SyncConfig? { configs.first }
    private var isLocked: Bool { config?.biometricLockEnabled ?? false }

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
            if !isLocked { auth.isUnlocked = true }
            if let hex = config?.accentColorHex {
                appearance.accentColorHex = hex
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .autoLockCheck)) { note in
            // `AutoLockService` listens to UIKit's own lifecycle notifications,
            // so this view must not re-post them from `scenePhase`: doing so
            // delivered every background/foreground transition twice.
            guard let backgroundedAt = note.object as? Date,
                  let minutes = config?.autoLockMinutes,
                  minutes > 0 else { return }
            let elapsed = Date().timeIntervalSince(backgroundedAt) / 60
            if elapsed >= Double(minutes) { auth.lock() }
        }
    }

    private func seedTagsIfNeeded() {
        guard !didSeedTags else { return }
        let existing = (try? context.fetchCount(FetchDescriptor<CategoryTag>())) ?? 0
        guard existing == 0 else { didSeedTags = true; return }
        for (name, hex, icon) in defaultTags {
            context.insert(CategoryTag(name: name, colorHex: hex, iconName: icon))
        }
        do {
            try context.save()
            didSeedTags = true
        } catch {}
    }
}
