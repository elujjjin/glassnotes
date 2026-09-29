import SwiftUI

struct GlassBackground: View {
    @EnvironmentObject private var appearance: AppearanceStore

    var body: some View {
        ZStack {
            if let photo = appearance.photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .overlay {
                        LinearGradient(
                            colors: [.black.opacity(0.25), .clear, .black.opacity(0.35)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            } else {
                layer(for: appearance.wallpaper)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func layer(for wallpaper: Wallpaper) -> some View {
        switch wallpaper {
        case .graphite: graphite
        case .aurora: aurora
        case .prism: prism
        case .grid: lattice
        case .silk: silk
        }
    }

    private var graphite: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#2B2B30"), Color(hex: "#0A0A0C"), Color(hex: "#1C1C21")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            LinearGradient(
                colors: [.white.opacity(0.10), .clear],
                startPoint: .top,
                endPoint: .center
            )
        }
    }

    private var aurora: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#080D24"), Color(hex: "#101A38"), Color(hex: "#04161A")],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color(hex: "#2BD9C0").opacity(0.42), .clear],
                center: UnitPoint(x: 0.18, y: 0.14),
                startRadius: 0,
                endRadius: 520
            )
            RadialGradient(
                colors: [Color(hex: "#4B4BE0").opacity(0.46), .clear],
                center: UnitPoint(x: 0.88, y: 0.32),
                startRadius: 0,
                endRadius: 560
            )
            RadialGradient(
                colors: [Color(hex: "#C43C7A").opacity(0.30), .clear],
                center: UnitPoint(x: 0.42, y: 0.95),
                startRadius: 0,
                endRadius: 500
            )
        }
    }

    private var prism: some View {
        ZStack {
            Color(hex: "#07070C")
            AngularGradient(
                colors: [
                    Color(hex: "#FF5F6D"), Color(hex: "#FFC371"), Color(hex: "#3ED598"),
                    Color(hex: "#38A3F1"), Color(hex: "#8E5BF2"), Color(hex: "#FF5F6D")
                ],
                center: .center
            )
            .blur(radius: 110)
            .opacity(0.55)
            RadialGradient(
                colors: [.clear, Color(hex: "#07070C").opacity(0.75)],
                center: .center,
                startRadius: 120,
                endRadius: 700
            )
        }
    }

    private var lattice: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0C1220"), Color(hex: "#060810")],
                startPoint: .top,
                endPoint: .bottom
            )
            Canvas { context, size in
                let step: CGFloat = 26
                var lines = Path()
                var x: CGFloat = 0
                while x <= size.width {
                    lines.move(to: CGPoint(x: x, y: 0))
                    lines.addLine(to: CGPoint(x: x, y: size.height))
                    x += step
                }
                var y: CGFloat = 0
                while y <= size.height {
                    lines.move(to: CGPoint(x: 0, y: y))
                    lines.addLine(to: CGPoint(x: size.width, y: y))
                    y += step
                }
                context.stroke(lines, with: .color(.white.opacity(0.10)), lineWidth: 0.5)
            }
            RadialGradient(
                colors: [Color(hex: "#3A6BFF").opacity(0.22), .clear],
                center: UnitPoint(x: 0.5, y: 0.05),
                startRadius: 0,
                endRadius: 480
            )
        }
    }

    private var silk: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#141414"), Color(hex: "#000000")],
                startPoint: .top,
                endPoint: .bottom
            )
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.14), location: 0.00),
                    .init(color: .clear, location: 0.30),
                    .init(color: .white.opacity(0.10), location: 0.55),
                    .init(color: .clear, location: 0.78),
                    .init(color: .white.opacity(0.07), location: 1.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            LinearGradient(
                colors: [.clear, Color(hex: "#3A2E5A").opacity(0.35), .clear],
                startPoint: .bottomTrailing,
                endPoint: .topLeading
            )
        }
    }
}

struct WallpaperPreview: View {
    let wallpaper: Wallpaper
    var isSelected: Bool

    var body: some View {
        ZStack {
            switch wallpaper {
            case .graphite: graphitePreview
            case .aurora: auroraPreview
            case .prism: prismPreview
            case .grid: latticePreview
            case .silk: silkPreview
            }

            RoundedRectangle(cornerRadius: 10)
                .stroke(.white.opacity(isSelected ? 0.9 : 0.18), lineWidth: isSelected ? 2 : 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var graphitePreview: some View {
        LinearGradient(
            colors: [Color(hex: "#3A3A40"), Color(hex: "#101014")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var auroraPreview: some View {
        ZStack {
            Color(hex: "#0A1026")
            RadialGradient(
                colors: [Color(hex: "#2BD9C0").opacity(0.6), .clear],
                center: .topLeading, startRadius: 0, endRadius: 70
            )
            RadialGradient(
                colors: [Color(hex: "#4B4BE0").opacity(0.6), .clear],
                center: .trailing, startRadius: 0, endRadius: 80
            )
        }
    }

    private var prismPreview: some View {
        ZStack {
            Color(hex: "#07070C")
            AngularGradient(
                colors: [
                    Color(hex: "#FF5F6D"), Color(hex: "#3ED598"), Color(hex: "#38A3F1"),
                    Color(hex: "#8E5BF2"), Color(hex: "#FF5F6D")
                ],
                center: .center
            )
            .blur(radius: 20)
            .opacity(0.6)
        }
    }

    private var latticePreview: some View {
        ZStack {
            Color(hex: "#0A1020")
            Canvas { context, size in
                var lines = Path()
                var x: CGFloat = 0
                while x <= size.width {
                    lines.move(to: CGPoint(x: x, y: 0))
                    lines.addLine(to: CGPoint(x: x, y: size.height))
                    x += 9
                }
                var y: CGFloat = 0
                while y <= size.height {
                    lines.move(to: CGPoint(x: 0, y: y))
                    lines.addLine(to: CGPoint(x: size.width, y: y))
                    y += 9
                }
                context.stroke(lines, with: .color(.white.opacity(0.25)), lineWidth: 0.5)
            }
        }
    }

    private var silkPreview: some View {
        ZStack {
            Color(hex: "#0A0A0A")
            LinearGradient(
                colors: [.white.opacity(0.22), .clear, .white.opacity(0.14), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}


