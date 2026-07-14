import SwiftUI

enum OrbitTheme {
    static let nebula = Color(red: 0.07, green: 0.04, blue: 0.18)
    static let nebulaMid = Color(red: 0.12, green: 0.06, blue: 0.28)
    static let nebulaDark = Color(red: 0.02, green: 0.01, blue: 0.08)
    static let cyan = Color(red: 0.35, green: 0.92, blue: 0.98)
    static let aqua = Color(red: 0.45, green: 0.78, blue: 1.0)
    static let violet = Color(red: 0.55, green: 0.35, blue: 0.95)
    static let magenta = Color(red: 0.85, green: 0.35, blue: 0.75)
    static let star = Color.white.opacity(0.92)
    static let glass = Color.white.opacity(0.07)
    static let glassStroke = Color.white.opacity(0.18)
    static let hudRing = Color(red: 0.4, green: 0.85, blue: 1.0).opacity(0.55)
    static let display = Font.system(.title2, design: .rounded).weight(.semibold)
    static let mono = Font.system(.caption, design: .monospaced)
    static let sans = Font.system(.body, design: .rounded)
    static let title = Font.system(.title3, design: .rounded).weight(.bold)

    static func sectorColor(hue: Double, unlocked: Bool) -> Color {
        Color(hue: hue, saturation: unlocked ? 0.55 : 0.2, brightness: unlocked ? 0.55 : 0.25)
    }

    @ViewBuilder
    static var screenBackground: some View {
        RadialGradient(
            colors: [nebulaMid, nebula, nebulaDark],
            center: .center,
            startRadius: 20,
            endRadius: 520
        )
        .ignoresSafeArea()
    }
}

struct OrbitBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            OrbitTheme.screenBackground
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(OrbitTheme.nebulaDark)
    }
}

extension View {
    func orbitBackground() -> some View {
        modifier(OrbitBackgroundModifier())
    }

    func orbitScreenStyle() -> some View {
        self
            .scrollContentBackground(.hidden)
            .toolbarBackground(OrbitTheme.nebula, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .orbitBackground()
    }
}

struct NebulaGlassPanel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(OrbitTheme.glass)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                AngularGradient(
                                    colors: [OrbitTheme.cyan.opacity(0.5), OrbitTheme.violet.opacity(0.35), OrbitTheme.magenta.opacity(0.4), OrbitTheme.cyan.opacity(0.5)],
                                    center: .center
                                ),
                                lineWidth: 1
                            )
                    }
            }
    }
}

struct RadialHUDBadge: View {
    let label: String
    let value: String
    let progress: Double

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(OrbitTheme.glassStroke, lineWidth: 3)
                Circle()
                    .trim(from: 0, to: min(max(progress, 0), 1))
                    .stroke(
                        AngularGradient(colors: [OrbitTheme.cyan, OrbitTheme.aqua, OrbitTheme.violet], center: .center),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text(value)
                    .font(OrbitTheme.mono.weight(.bold))
                    .foregroundStyle(OrbitTheme.cyan)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(6)
            }
            .frame(width: 54, height: 54)
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(OrbitTheme.star.opacity(0.65))
        }
    }
}
