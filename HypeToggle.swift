import SwiftUI

struct HypeToggle: View {
    @Binding var selectedTab: Int // 0 for Discovery, 1 for Friends
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(["Discovery", "Friends"].indices, id: \.self) { index in
                Text(["Discovery", "Friends"][index])
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(selectedTab == index ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            if selectedTab == index {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "#2C2C2E"))
                                    .matchedGeometryEffect(id: "tab", in: namespace)
                            }
                        }
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    }
            }
        }
        .padding(4)
        .background(Color.black)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
    
    @Namespace private var namespace // For the smooth sliding animation
}
