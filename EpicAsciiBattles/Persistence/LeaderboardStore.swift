import Foundation

class LeaderboardStore: ObservableObject {
    private let maxRuns = 20
    private let storageKey = "leaderboard_runs"
    
    @Published private(set) var runs: [RunRecord] = []
    
    init() {
        loadRuns()
    }
    
    func addRun(_ run: RunRecord) {
        runs.append(run)
        runs.sort { $0.totalTrophies > $1.totalTrophies }
        
        if runs.count > maxRuns {
            runs = Array(runs.prefix(maxRuns))
        }
        
        saveRuns()
    }
    
    func getTopRuns() -> [RunRecord] {
        return runs
    }
    
    private func loadRuns() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return
        }
        
        do {
            runs = try JSONDecoder().decode([RunRecord].self, from: data)
        } catch {
            print("Failed to load runs: \(error)")
        }
    }
    
    private func saveRuns() {
        do {
            let data = try JSONEncoder().encode(runs)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save runs: \(error)")
        }
    }
}
