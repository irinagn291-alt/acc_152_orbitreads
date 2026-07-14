import SwiftUI

struct OrbitReadsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Flight Deck Config")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(OrbitTheme.cyan)
                    Text(OrbitReadsMetadata.websiteHost)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(OrbitTheme.star.opacity(0.6))

                    settingsRow("Privacy Policy", icon: "lock.shield") {
                        openURL(OrbitReadsMetadata.privacyPolicyURL)
                    }
                    settingsRow("Contact Us", icon: "antenna.radiowaves.left.and.right") {
                        openURL(OrbitReadsMetadata.contactUsURL)
                    }
                }
                .padding()
            }
            .orbitScreenStyle()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func settingsRow(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).foregroundStyle(OrbitTheme.cyan)
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(OrbitTheme.star)
                Spacer()
                Image(systemName: "arrow.up.right").foregroundStyle(OrbitTheme.cyan.opacity(0.6))
            }
            .padding()
            .background(OrbitTheme.nebulaDark.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(OrbitTheme.glassStroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
