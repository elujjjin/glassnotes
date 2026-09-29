import SwiftUI

struct GlassConfig {
    var cornerRadius: CGFloat = 20
    var tint: Color?
    var interactive: Bool = false
}

extension GlassConfig {
    static let card = GlassConfig(cornerRadius: 20)
    static let field = GlassConfig(cornerRadius: 18)
    static let capsule = GlassConfig(cornerRadius: 999)
}

extension View {
    @ViewBuilder
    func liquidGlass(_ config: GlassConfig) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            let base = config.tint.map { Glass.regular.tint($0) } ?? .regular
            let shape = RoundedRectangle(cornerRadius: config.cornerRadius)
            if config.interactive {
                glassEffect(base.interactive(), in: shape)
            } else {
                glassEffect(base, in: shape)
            }
        } else {
            refractiveSurface(cornerRadius: config.cornerRadius, tint: config.tint)
        }
        #else
        refractiveSurface(cornerRadius: config.cornerRadius, tint: config.tint)
        #endif
    }

    private func refractiveSurface(cornerRadius: CGFloat, tint: Color?) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)

        return self
            .background {
                ZStack {
                    shape
                        .fill(Color.black.opacity(0.5))
                        .blur(radius: 16)
                        .offset(y: 10)
                        .padding(-8)

                    if let tint {
                        shape.fill(tint.opacity(0.16))
                    } else {
                        shape.fill(
                            LinearGradient(
                                colors: [.white.opacity(0.10), .white.opacity(0.02), .black.opacity(0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }

                    shape
                        .inset(by: 1.5)
                        .fill(
                            AngularGradient(
                                colors: [.white.opacity(0.18), .clear, .clear, .white.opacity(0.09)],
                                center: .center
                            )
                        )
                        .blur(radius: 5)
                }
            }
            .overlay {
                shape.stroke(.white.opacity(0.10), lineWidth: 0.5)
                shape
                    .inset(by: 0.75)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.50), .white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.4
                    )
            }
    }
}

extension View {
    @ViewBuilder
    func glassGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 14, content: content)
        } else {
            content()
        }
        #else
        content()
        #endif
    }
}
