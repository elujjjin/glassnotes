import SwiftUI
import SwiftData

public struct SyncSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var syncConfigs: [SyncConfig]
    @Query private var tags: [CategoryTag]
    @Query private var notes: [Note]
    
    @State private var botToken: String = ""
    @State private var chatId: String = ""
    @State private var enableBiometrics: Bool = false
    @State private var statusMsg: String? = nil
    
    // Tag Creator State
    @State private var newTagName: String = ""
    @State private var newTagColorHex: String = "#007AFF"
    @State private var newTagIcon: String = "tag.fill"
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            Text("Settings & Sync")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            Button("Done") { dismiss() }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.cyan)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        // Telegram Cross-Platform Sync Section
                        GlassCard(cornerRadius: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 8) {
                                    Image(systemName: "paperplane.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.cyan)
                                    Text("Telegram Scratchpad Sync")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Send notes directly between your iPhone and Telegram account for easy cross-platform notes.")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Bot Token").font(.system(size: 12, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                                    TextField("", text: $botToken, prompt: Text("e.g. 123456789:ABCdef...").foregroundColor(.white.opacity(0.35)))
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(10)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Chat ID / User ID").font(.system(size: 12, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                                    TextField("", text: $chatId, prompt: Text("e.g. 987654321").foregroundColor(.white.opacity(0.35)))
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(10)
                                }
                                
                                Button(action: saveSyncConfig) {
                                    Text("Save Telegram Credentials")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Capsule().fill(Color.cyan.opacity(0.6)))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Security Section
                        GlassCard(cornerRadius: 18) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "shield.fill")
                                        .foregroundColor(.green)
                                    Text("Biometric Security")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Toggle("Require Face ID / Touch ID", isOn: $enableBiometrics)
                                    .tint(.cyan)
                                    .foregroundColor(.white)
                                    .onChange(of: enableBiometrics) { newValue in
                                        saveSecurityConfig(newValue)
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Tag Category Manager
                        GlassCard(cornerRadius: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Image(systemName: "tag.fill")
                                        .foregroundColor(.purple)
                                    Text("Tag Categories")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                HStack {
                                    TextField("New tag name...", text: $newTagName)
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(10)
                                    
                                    Button("Add") {
                                        createTag()
                                    }
                                    .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(Color.purple.opacity(0.7)))
                                }
                                
                                ForEach(tags) { tag in
                                    HStack {
                                        Image(systemName: tag.iconName)
                                            .foregroundColor(tag.color)
                                        Text(tag.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Button(action: { modelContext.delete(tag) }) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 12))
                                                .foregroundColor(.red.opacity(0.8))
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Data Backup & Export Section
                        GlassCard(cornerRadius: 18) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up.fill")
                                        .foregroundColor(.orange)
                                    Text("Data Backup & Export")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Text("\(notes.count) total notes saved locally on device.")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                HStack(spacing: 10) {
                                    Button(action: exportNotesJSON) {
                                        Text("Export JSON")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .background(Capsule().fill(Color.white.opacity(0.15)))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .onAppear {
                if let config = syncConfigs.first {
                    botToken = config.telegramBotToken
                    chatId = config.telegramChatId
                    enableBiometrics = config.biometricLockEnabled
                }
            }
        }
    }
    
    private func saveSyncConfig() {
        if let config = syncConfigs.first {
            config.telegramBotToken = botToken
            config.telegramChatId = chatId
        } else {
            let newConfig = SyncConfig(telegramBotToken: botToken, telegramChatId: chatId)
            modelContext.insert(newConfig)
        }
        try? modelContext.save()
    }
    
    private func saveSecurityConfig(_ enabled: Bool) {
        if let config = syncConfigs.first {
            config.biometricLockEnabled = enabled
        } else {
            let newConfig = SyncConfig(biometricLockEnabled: enabled)
            modelContext.insert(newConfig)
        }
        try? modelContext.save()
    }
    
    private func createTag() {
        let name = newTagName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        
        let newTag = CategoryTag(name: name, colorHex: "#AF52DE", iconName: "tag.fill")
        modelContext.insert(newTag)
        try? modelContext.save()
        newTagName = ""
    }
    
    private func exportNotesJSON() {
        // Implementation for exporting notes as JSON payload
    }
}
