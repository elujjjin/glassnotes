import SwiftUI
import SwiftData
import UIKit

@main
struct GlassNotesApp: App {
    @StateObject private var auth = BiometricAuthService()
    @StateObject private var appearance = AppearanceStore()
    @StateObject private var autoLock = AutoLockService()

    private let container: ModelContainer = {
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
    @EnvironmentObject private var appearance: AppearanceStore
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
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
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                NotificationCenter.default.post(
                    name: UIApplication.didEnterBackgroundNotification, object: nil)
            } else if phase == .active {
                NotificationCenter.default.post(
                    name: UIApplication.willEnterForegroundNotification, object: nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .autoLockCheck)) { note in
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
