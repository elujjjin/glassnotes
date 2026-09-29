import SwiftUI
import SwiftData

@main
struct GlassNotesApp: App {
    @StateObject private var authService = BiometricAuthService()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Note.self,
            CategoryTag.self,
            SyncConfig.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Seed Default Tags if empty
            Task { @MainActor in
                let context = container.mainContext
                let descriptor = FetchDescriptor<CategoryTag>()
                if let count = try? context.fetchCount(descriptor), count == 0 {
                    let defaultTags = [
                        CategoryTag(name: "Ideas", colorHex: "#FF9500", iconName: "lightbulb.fill"),
                        CategoryTag(name: "Work", colorHex: "#007AFF", iconName: "briefcase.fill"),
                        CategoryTag(name: "Personal", colorHex: "#34C759", iconName: "person.fill"),
                        CategoryTag(name: "Scratchpad", colorHex: "#AF52DE", iconName: "bolt.fill"),
                        CategoryTag(name: "Secret", colorHex: "#FF3B30", iconName: "lock.fill")
                    ]
                    defaultTags.forEach { context.insert($0) }
                    try? context.save()
                }
            }
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainContentView()
                .environmentObject(authService)
        }
        .modelContainer(sharedModelContainer)
    }
}

struct MainContentView: View {
    @EnvironmentObject private var authService: BiometricAuthService
    @Query private var syncConfigs: [SyncConfig]
    
    private var isBiometricsRequired: Bool {
        syncConfigs.first?.biometricLockEnabled ?? false
    }
    
    var body: some View {
        Group {
            if isBiometricsRequired && !authService.isUnlocked {
                LockView(authService: authService) {
                    authService.isUnlocked = true
                }
            } else {
                QuickStreamView()
            }
        }
        .onAppear {
            if !isBiometricsRequired {
                authService.isUnlocked = true
            }
        }
    }
}
