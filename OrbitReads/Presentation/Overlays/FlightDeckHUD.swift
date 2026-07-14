import SwiftUI

struct FlightDeckHUD: View {
    let deck: FlightDeckSnapshot?
    let onRoute: () -> Void
    let onTrajectory: () -> Void
    let onScan: () -> Void
    let onSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("ORBIT")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(OrbitTheme.cyan)
                Spacer(minLength: 0)
                metric("FUEL", "\(deck?.totalFuel ?? 0)")
                metric("LY", String(format: "%.1f", deck?.lightYears ?? 0))
                metric("WARP", "\(deck?.warpJumps ?? 0)")
                Button(action: onSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(OrbitTheme.cyan)
                }
                .accessibilityLabel("Settings")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(OrbitTheme.nebulaDark.opacity(0.72))
                    .overlay(Capsule().stroke(OrbitTheme.glassStroke, lineWidth: 1))
            )
            .padding(.horizontal, 16)
            .padding(.top, 10)

            Spacer()

            HStack(spacing: 10) {
                hudChip("Route", icon: "point.topleft.down.to.point.bottomright.curvepath", action: onRoute)
                hudChip("Path", icon: "point.3.connected.trianglepath.dotted", action: onTrajectory)
                Spacer()
                Button(action: onScan) {
                    Image(systemName: "viewfinder")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(OrbitTheme.nebulaDark)
                        .frame(width: 54, height: 54)
                        .background(OrbitTheme.cyan)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Scan planet")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 22)
        }
        .allowsHitTesting(true)
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(OrbitTheme.star)
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(OrbitTheme.star.opacity(0.5))
        }
    }

    private func hudChip(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(OrbitTheme.cyan)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(OrbitTheme.nebulaDark.opacity(0.72))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(OrbitTheme.glassStroke, lineWidth: 1))
        }
    }
}
