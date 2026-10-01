import SwiftUI
import SwiftData

struct LockView: View {
    @ObservedObject var authService: BiometricAuthService
    @Query private var configs: [SyncConfig]
    var onUnlock: () -> Void

    private var hapticsEnabled: Bool { configs.first?.hapticsEnabled ?? true }

    private var icon: String {
        switch authService.biometryType {
        case .touchID: return "touchid"
        default: return "faceid"
        }
    }

    var body: some View {
        ZStack {
            GlassBackground()

            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.white)
                    .frame(width: 78, height: 78)
                    .liquidGlass(GlassConfig(cornerRadius: 999))

                VStack(spacing: 6) {
                    Text("Locked")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Authenticate with \(authService.biometryName) to open your notes.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if let error = authService.authError {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                GlassButton(title: "Unlock", icon: icon, hapticsEnabled: hapticsEnabled) {
                    Task {
                        if await authService.authenticate() {
                            onUnlock()
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}
