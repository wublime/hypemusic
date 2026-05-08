
import Foundation
internal import Combine

// This matches your Python dictionary keys exactly
struct ReleaseResponse: Codable, Identifiable {
    var id: String { title } // Using title as a temporary ID
    let title: String
    let artist: String
    let hype_score: Int
    let status: String
    let countdown: String
}

@MainActor
class NetworkManager: ObservableObject {
    @Published var releases: [ReleaseResponse] = []
    
    func fetchReleases() async {
        // "127.0.0.1" works for the simulator to talk to your Mac
        guard let url = URL(string: "http://127.0.0.1:8000/releases") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedData = try JSONDecoder().decode([ReleaseResponse].self, from: data)
            self.releases = decodedData
        } catch {
            print("❌ Error fetching data: \(error)")
        }
    }
}
