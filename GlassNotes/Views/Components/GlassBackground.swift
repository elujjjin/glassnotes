import SwiftUI

public struct GlassBackground: View {
    @State private var animateGradient: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Dynamic Mesh Orbs
            LinearGradient(
                colors: animateGradient
                    ? [Color(hex: "#5B2476"), Color(hex: "#1B2735"), Color(hex: "#09203F")]
                    : [Color(hex: "#1A0033"), Color(hex: "#00223E"), Color(hex: "#1D976C")],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .animation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true), value: animateGradient)
            .ignoresSafeArea()
            
            // Glowing Ambient Light Blobs
            Circle()
                .fill(Color.cyan.opacity(0.35))
                .blur(radius: 70)
                .offset(x: animateGradient ? -100 : 120, y: animateGradient ? -150 : 100)
            
            Circle()
                .fill(Color.purple.opacity(0.35))
                .blur(radius: 80)
                .offset(x: animateGradient ? 130 : -90, y: animateGradient ? 180 : -120)
            
            Circle()
                .fill(Color.indigo.opacity(0.3))
                .blur(radius: 60)
                .offset(x: animateGradient ? 50 : -50, y: animateGradient ? -80 : 80)
        }
        .onAppear {
            animateGradient = true
        }
    }
}
