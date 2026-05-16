import SwiftUI

struct ReviewPost: Identifiable {
    let id = UUID()
    let albumTitle: String
    let artist: String
    let body: String
    let score: Double // 0..10
    let username: String
    let views: Int
    let likes: Int
    let comments: Int
}

struct ReviewCard: View {
    let post: ReviewPost
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Album + artist + score badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.albumTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(palette.primaryText(for: colorScheme))
                        .lineLimit(1)
                    Text("by \(post.artist)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(palette.secondaryText(for: colorScheme))
                        .lineLimit(1)
                }
                Spacer()
                ScoreBadge(score: post.score)
            }

            // Body
            Text(post.body)
                .font(.system(size: 13))
                .foregroundColor(palette.primaryText(for: colorScheme))
                .lineLimit(4)

            // Meta row
            HStack(spacing: 10) {
                Avatar()
                Text(post.username)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(palette.secondaryText(for: colorScheme))
                Spacer()
                ActionStat(system: "eye", value: post.views)
                ActionStat(system: "heart", value: post.likes)
                ActionStat(system: "bubble.right", value: post.comments)
            }
        }
        .padding(16)
        .background(palette.card(for: colorScheme))
        .cornerRadius(12)
    }
}

struct ScoreBadge: View {
    let score: Double
    @Environment(\.appPalette) private var palette
    var body: some View {
        Text(String(format: "%.1f/10", score))
            .font(.system(size: 13, weight: .black))
            .foregroundColor(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(palette.accent)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct Avatar: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.gray)
                .opacity(0.3)
            Image(systemName: "person.fill")
                .foregroundColor(.gray)
                .font(.system(size: 12))
        }
        .frame(width: 24, height: 24)
    }
}

struct ActionStat: View {
    let system: String
    let value: Int
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: system)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(palette.secondaryText(for: colorScheme))
            Text("\(value)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(palette.secondaryText(for: colorScheme))
        }
    }
}

struct ReviewCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(mockReviewPosts) { post in
                    ReviewCard(post: post)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .background(AppPalette(preference: .hype).background(for: .dark))
        }
        .background(Color.black)
        .previewDisplayName("ReviewCard - Mock List")
    }
}

let mockReviewPosts: [ReviewPost] = [
    .init(albumTitle: "DAMN.", artist: "Kendrick Lamar", body: "Wow. This album hits different every single time. Pure storytelling from start to finish.", score: 9.0, username: "wubezaa", views: 420, likes: 12, comments: 30),
    .init(albumTitle: "2014 Forest Hills Drive", artist: "J. Cole", body: "I love this one — one of the most authentic rap albums of the decade — no features, no filler.", score: 9.8, username: "ztamri", views: 446, likes: 27, comments: 19)
]
