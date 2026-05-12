import SwiftUI

struct AlertsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Alerts")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.white)

                Text("Notifications, mentions, and drops from artists you follow will show up here.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hexString: "#1A1A1C"))
                    .frame(height: 88)
                    .overlay(
                        Text("No new alerts")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
}
