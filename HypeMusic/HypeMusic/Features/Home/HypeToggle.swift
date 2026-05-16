import SwiftUI

struct HypeToggle: View {
    /// 0 = Discovery, 1 = Friends (independent of the bottom tab bar).
    @Binding var discoveryFriendsMode: Int
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette

    var body: some View {
        HStack(spacing: 0) {
            ForEach(["Discovery", "Friends"].indices, id: \.self) { index in
                Text(["Discovery", "Friends"][index])
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(
                        discoveryFriendsMode == index
                            ? palette.primaryText(for: colorScheme)
                            : palette.secondaryText(for: colorScheme)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            if discoveryFriendsMode == index {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(palette.togglePill(for: colorScheme))
                                    .matchedGeometryEffect(id: "tab", in: namespace)
                            }
                        }
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            discoveryFriendsMode = index
                        }
                    }
            }
        }
        .padding(4)
        .background(palette.toggleTrack(for: colorScheme))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(palette.tabBarTopHairline(for: colorScheme), lineWidth: 1)
        )
        .padding(.horizontal,16)
    }
    
    @Namespace private var namespace // For the smooth sliding animation
}
