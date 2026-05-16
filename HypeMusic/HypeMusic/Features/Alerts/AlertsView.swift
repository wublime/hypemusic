import SwiftUI

struct AlertsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Alerts")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(palette.primaryText(for: colorScheme))

                Text("Notifications, mentions, and drops from artists you follow will show up here.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(palette.secondaryText(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)

                RoundedRectangle(cornerRadius: 12)
                    .fill(palette.card(for: colorScheme))
                    .frame(height: 88)
                    .overlay(
                        Text("No new alerts")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(palette.secondaryText(for: colorScheme))
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
}
