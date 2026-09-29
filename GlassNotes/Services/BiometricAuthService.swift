import Foundation
import LocalAuthentication
import Combine

@MainActor
public final class BiometricAuthService: ObservableObject {
    @Published public var isUnlocked: Bool = false
    @Published public var authError: String? = nil

    public var biometryType: LABiometryType {
        let context = LAContext()
        var error: NSError?
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return context.biometryType
    }
    
    public var biometryName: String {
        switch biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Passcode"
        }
    }
    
    public func authenticate(reason: String = "Authenticate to unlock private notes") async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            self.authError = error?.localizedDescription ?? "Biometric authentication not available"
            self.isUnlocked = false
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            self.isUnlocked = success
            if success {
                self.authError = nil
            }
            return success
        } catch {
            self.authError = error.localizedDescription
            self.isUnlocked = false
            return false
        }
    }
    
    public func lock() {
        self.isUnlocked = false
    }
}
