import SwiftUI

public struct LockView: View {
    @ObservedObject public var authService: BiometricAuthService
    public var onUnlockSuccess: () -> Void
    
    public init(authService: BiometricAuthService, onUnlockSuccess: @escaping () -> Void) {
        self.authService = authService
        self.onUnlockSuccess = onUnlockSuccess
    }
    
    public var body: some View {
        ZStack {
            GlassBackground()
            
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: .cyan.opacity(0.5), radius: 20, x: 0, y: 10)
                
                VStack(spacing: 8) {
                    Text("GlassNotes Locked")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Authenticate using \(authService.biometryName) to access private notes.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                if let error = authService.authError {
                    Text(error)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red.opacity(0.8))
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                GlassButton(title: "Unlock with \(authService.biometryName)", icon: "faceid", color: .cyan) {
                    Task {
                        let success = await authService.authenticate()
                        if success {
                            onUnlockSuccess()
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}
