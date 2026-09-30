import SwiftUI

struct GlassBackground: View {
    @EnvironmentObject private var appearance: AppearanceStore

    /// Overrides the stored wallpaper. `WallpaperPreview` passes a specific
    /// value so a thumbnail can render a wallpaper the user has not selected.
    /// `nil` means "use whatever is in `AppearanceStore`".
    var forcedWallpaper: Wallpaper?

    /// Thumbnails live inside a fixed frame, so they must not ignore the safe
    /// area or the wallpaper would spill over the grid cell.
    var ignoresSafeArea: Bool = true

    init(forcedWallpaper: Wallpaper? = nil, ignoresSafeArea: Bool = true) {
        self.forcedWallpaper = forcedWallpaper
        self.ignoresSafeArea = ignoresSafeArea
    }

    var body: some View {
        ZStack {
            if let photo = appearance.photo, forcedWallpaper == nil {
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
                layer(for: forcedWallpaper ?? appearance.wallpaper)
            }
        }
        .ignoresSafeArea(ignoresSafeArea)
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
        case .midnight: midnight
        case .parchment: parchment
        case .forest: forest
        case .ember: ember
        case .mono: mono
        case .floral: floral
        case .skull: skull
        case .cross: cross
        case .topo: topo
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

    // MARK: - Flat and patterned wallpapers

    private var midnight: some View {
        ZStack {
            Color(hex: "#0B1020")
            RadialGradient(
                colors: [Color(hex: "#2B3A67").opacity(0.55), .clear],
                center: UnitPoint(x: 0.2, y: 0.12),
                startRadius: 0,
                endRadius: 520
            )
        }
    }

    private var ember: some View {
        ZStack {
            Color(hex: "#160806")
            RadialGradient(
                colors: [Color(hex: "#FF6B2C").opacity(0.42), .clear],
                center: UnitPoint(x: 0.5, y: 1.0),
                startRadius: 0,
                endRadius: 620
            )
            RadialGradient(
                colors: [Color(hex: "#FFD166").opacity(0.20), .clear],
                center: UnitPoint(x: 0.3, y: 0.9),
                startRadius: 0,
                endRadius: 320
            )
        }
    }

    private var mono: some View {
        // Deliberately blank: a flat field is a legitimate wallpaper choice.
        Color(hex: "#101010")
    }

    private var parchment: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#2A2118"), Color(hex: "#17120C")],
                startPoint: .top,
                endPoint: .bottom
            )
            Canvas { context, size in
                // Faint fibre speckle, so it reads as paper rather than a fill.
                var dots = Path()
                var seed: UInt64 = 99
                for _ in 0..<420 {
                    seed = seed &* 6364136223846793005 &+ 1442695040888963407
                    let fx = CGFloat(seed % 10_000) / 10_000 * size.width
                    seed = seed &* 6364136223846793005 &+ 1442695040888963407
                    let fy = CGFloat(seed % 10_000) / 10_000 * size.height
                    dots.addEllipse(in: CGRect(x: fx, y: fy, width: 1.2, height: 1.2))
                }
                context.fill(dots, with: .color(.white.opacity(0.05)))
            }
        }
    }

    private var forest: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0C1A12"), Color(hex: "#050B08")],
                startPoint: .top,
                endPoint: .bottom
            )
            Canvas { context, size in
                // Staggered conifer silhouettes receding into the fog.
                let widths: [CGFloat] = [54, 40, 30, 22]
                let alphas: [Double] = [0.05, 0.08, 0.12, 0.18]
                for (row, width) in widths.enumerated() {
                    let baseY = size.height * (0.42 + CGFloat(row) * 0.16)
                    var path = Path()
                    var x: CGFloat = -width
                    while x < size.width + width {
                        path.move(to: CGPoint(x: x, y: baseY))
                        path.addLine(to: CGPoint(x: x + width / 2, y: baseY - width * 1.5))
                        path.addLine(to: CGPoint(x: x + width, y: baseY))
                        path.closeSubpath()
                        x += width
                    }
                    context.fill(path, with: .color(.green.opacity(alphas[row])))
                }
            }
            RadialGradient(
                colors: [Color(hex: "#9BE8B0").opacity(0.10), .clear],
                center: UnitPoint(x: 0.7, y: 0.08),
                startRadius: 0,
                endRadius: 420
            )
        }
    }

    private var floral: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1B1220"), Color(hex: "#0D0A12")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Canvas { context, size in
                let radius: CGFloat = 26
                let step: CGFloat = 96
                var row = 0
                var y: CGFloat = -40
                while y < size.height + 60 {
                    var x: CGFloat = row % 2 == 0 ? -40 : 8
                    while x < size.width + 60 {
                        let centre = CGPoint(x: x, y: y)
                        for i in 0..<5 {
                            let angle = Double(i) * 72 * .pi / 180
                            var petal = Path(ellipseIn: CGRect(
                                x: centre.x - radius, y: centre.y - radius,
                                width: radius * 2, height: radius * 2
                            ))
                            petal = petal.applying(
                                CGAffineTransform(translationX: centre.x, y: centre.y)
                                    .rotated(by: angle)
                                    .translatedBy(x: -centre.x, y: -centre.y)
                            )
                            context.fill(petal, with: .color(.white.opacity(0.045)))
                        }
                        x += step
                    }
                    y += step
                    row += 1
                }
            }
        }
    }

    private var skull: some View {
        ZStack {
            Color(hex: "#0A0A0C")
            Canvas { context, size in
                let step: CGFloat = 132
                var row = 0
                var y: CGFloat = 40
                while y < size.height + step {
                    var x: CGFloat = row % 2 == 0 ? 10 : 10 + step / 2
                    while x < size.width + step {
                        Self.skullGlyph(context: &context, centre: CGPoint(x: x, y: y))
                        x += step
                    }
                    y += step
                    row += 1
                }
            }
            RadialGradient(
                colors: [.clear, Color(hex: "#000000").opacity(0.6)],
                center: .center,
                startRadius: 180,
                endRadius: 700
            )
        }
    }

    /// A simple skull: cranium, two dark sockets, and a jaw block.
    ///
    /// Static because it only draws into the `Canvas`; it never reads view state.
    private static func skullGlyph(context: inout GraphicsContext, centre: CGPoint) {
        let w: CGFloat = 34, h: CGFloat = 38
        context.fill(
            Path(ellipseIn: CGRect(
                x: centre.x - w / 2, y: centre.y - h / 2,
                width: w, height: h * 0.72
            )),
            with: .color(.white.opacity(0.055))
        )
        let socketRadius = w * 0.17
        for dx in [-w * 0.19, w * 0.19] {
            context.fill(
                Path(ellipseIn: CGRect(
                    x: centre.x + dx - socketRadius,
                    y: centre.y - h * 0.06 - socketRadius,
                    width: socketRadius * 2,
                    height: socketRadius * 2
                )),
                with: .color(.black.opacity(0.55))
            )
        }
        context.fill(
            Path(roundedRect: CGRect(
                x: centre.x - w * 0.22, y: centre.y + h * 0.18,
                width: w * 0.44, height: h * 0.20
            ), cornerRadius: w * 0.08),
            with: .color(.white.opacity(0.055))
        )
    }

    private var cross: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#12131A"), Color(hex: "#08080C")],
                startPoint: .top,
                endPoint: .bottom
            )
            Canvas { context, size in
                let step: CGFloat = 104
                let arm = step * 0.26
                var row = 0
                var y: CGFloat = 30
                while y < size.height + step {
                    var x: CGFloat = row % 2 == 0 ? 20 : 20 + step / 2
                    while x < size.width + step {
                        var cross = Path()
                        cross.addRect(CGRect(x: x - arm / 2, y: y - step * 0.30,
                                             width: arm, height: step * 0.60))
                        cross.addRect(CGRect(x: x - step * 0.26, y: y - arm / 2,
                                             width: step * 0.52, height: arm))
                        context.fill(cross, with: .color(.white.opacity(0.04)))
                        x += step
                    }
                    y += step
                    row += 1
                }
            }
        }
    }

    private var topo: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0E1512"), Color(hex: "#060A08")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Canvas { context, size in
                // Concentric contours, offset and slightly rotated like a map.
                var seed: UInt64 = 7
                for ring in 0..<26 {
                    seed = seed &* 6364136223846793005 &+ 1442695040888963407
                    let jx = CGFloat(seed % 1_000) / 1_000 * 120 - 60
                    seed = seed &* 6364136223846793005 &+ 1442695040888963407
                    let jy = CGFloat(seed % 1_000) / 1_000 * 120 - 60
                    let radius = CGFloat(ring) * 44 + 26
                    let rect = CGRect(
                        x: size.width / 2 + jx - radius,
                        y: size.height / 2 + jy - radius * 0.82,
                        width: radius * 2,
                        height: radius * 1.64
                    )
                    var path = Path(ellipseIn: rect)
                    path = path.applying(
                        CGAffineTransform(translationX: size.width / 2, y: size.height / 2)
                            .rotated(by: 0.4)
                            .translatedBy(x: -size.width / 2, y: -size.height / 2)
                    )
                    context.stroke(path, with: .color(.green.opacity(0.07)), lineWidth: 1)
                }
            }
        }
    }
}

struct WallpaperPreview: View {
    let wallpaper: Wallpaper
    var isSelected: Bool

    var body: some View {
        ZStack {
            // Render the real wallpaper rather than a hand-written thumbnail, so
            // the preview can never drift from what the user actually gets and
            // new wallpapers need no matching preview case.
            GlassBackground(forcedWallpaper: wallpaper, ignoresSafeArea: false)

            RoundedRectangle(cornerRadius: 10)
                .stroke(.white.opacity(isSelected ? 0.9 : 0.18), lineWidth: isSelected ? 2 : 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


