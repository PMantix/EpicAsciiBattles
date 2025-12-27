import Foundation
import SwiftUI

/// Game state manager
class GameState: ObservableObject {
    @Published var navigationPath = NavigationPath()
    @Published var currentRun: GameRun?
    @Published var settings = GameSettings()
    
    private let leaderboardStore = LeaderboardStore()
    
    func startNewRun() {
        let seed = UInt64.random(in: 0...UInt64.max)
        currentRun = GameRun(seed: seed)
        navigationPath.append(NavigationDestination.roundOffer)
    }
    
    func endRun() {
        if let run = currentRun {
            leaderboardStore.addRun(run.toRecord())
        }
        currentRun = nil
        navigationPath.removeLast(navigationPath.count)
    }
    
    func getLeaderboard() -> [RunRecord] {
        leaderboardStore.getTopRuns()
    }
}

/// Represents a single game run
class GameRun: ObservableObject {
    let runId: UUID
    let seed: UInt64
    var startTime: Date
    
    @Published var round: Int = 0
    @Published var score: Int = 0
    @Published var isActive: Bool = true
    
    // Current matchup
    @Published var teamAName: String = ""
    @Published var teamACount: Int = 0
    @Published var teamAGlyph: Character = " "
    @Published var teamBName: String = ""
    @Published var teamBCount: Int = 0
    @Published var teamBGlyph: Character = " "
    
    // Battle state
    @Published var pickedTeam: Int? = nil // 0 = A, 1 = B
    @Published var battleCore: GameCore?
    @Published var battleFinished: Bool = false
    @Published var wasCorrect: Bool = false
    
    init(seed: UInt64) {
        self.runId = UUID()
        self.seed = seed
        self.startTime = Date()
        generateNextMatchup()
    }
    
    func generateNextMatchup() {
        round += 1
        
        // Simple matchup generation for now
        // Will be enhanced with actual species data in Phase 2
        let species = [
            ("Chicken", "c", 2...10),
            ("Baboon", "b", 1...5)
        ]
        
        let teamAIndex = Int.random(in: 0..<species.count)
        let teamBIndex = (teamAIndex + 1) % species.count
        
        let teamA = species[teamAIndex]
        let teamB = species[teamBIndex]
        
        teamAName = teamA.0
        teamAGlyph = Character(teamA.1)
        teamACount = Int.random(in: teamA.2)
        
        teamBName = teamB.0
        teamBGlyph = Character(teamB.1)
        teamBCount = Int.random(in: teamB.2)
    }
    
    func pickTeam(_ team: Int) {
        pickedTeam = team
        
        // Initialize battle simulation
        let battleSeed = seed &+ UInt64(round)
        battleCore = GameCore(seed: battleSeed)
        
        // Create team JSON (simplified for Phase 1)
        let teamAJson = """
        [{"species_id": "\(teamAName)", "glyph": "\(teamAGlyph)"}]
        """
        let teamBJson = """
        [{"species_id": "\(teamBName)", "glyph": "\(teamBGlyph)"}]
        """
        
        _ = battleCore?.initBattle(teamA: teamAJson, teamB: teamBJson)
    }
    
    func calculateScore(isUnderdog: Bool) -> Int {
        let baseScore = 100
        let roundMultiplier = 1.0 + 0.1 * Double(round - 1)
        let underdogBonus = isUnderdog ? 1.25 : 1.0
        return Int(Double(baseScore) * roundMultiplier * underdogBonus)
    }
    
    func toRecord() -> RunRecord {
        RunRecord(
            runId: runId,
            timestamp: startTime,
            score: score,
            roundReached: round,
            seed: seed
        )
    }
}
