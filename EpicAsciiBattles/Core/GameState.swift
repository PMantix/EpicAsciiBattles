import Foundation
import SwiftUI

/// Game state manager
class GameState: ObservableObject {
    @Published var navigationPath = NavigationPath()
    @Published var currentRun: GameRun?
    var settings: GameSettings { GameSettings.shared }
    
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
    @Published var teamAColorName: String = "lgreen"
    @Published var teamBColorName: String = "lred"
    
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
        
        // All available species: (name, glyph, count range, color)
        let species: [(String, String, ClosedRange<Int>, String)] = [
            ("Ant", "a", 10...30, "red"),
            ("Baboon", "b", 1...5, "brown"),
            ("Bear", "B", 1...3, "brown"),
            ("Cat", "c", 2...8, "gray"),
            ("Chicken", "c", 2...10, "yellow"),
            ("Chimpanzee", "C", 1...4, "brown"),
            ("Cockroach", "i", 10...25, "brown"),
            ("Dog", "o", 2...7, "brown"),
            ("Donkey", "d", 1...4, "gray"),
            ("Dragon", "D", 1...2, "lred"),
            ("Duck", "u", 3...12, "yellow"),
            ("Flamingo", "f", 2...8, "lpink"),
            ("Gecko", "e", 5...15, "lgreen"),
            ("Gerbil", "g", 6...18, "brown"),
            ("Goose", "G", 2...9, "white"),
            ("Horse", "H", 1...4, "brown"),
            ("Alligator", "A", 1...3, "green"),
            ("Lion", "L", 1...3, "yellow"),
            ("Mouse", "m", 8...25, "gray"),
            ("Rat", "r", 6...20, "gray"),
            ("Salamander", "l", 4...12, "orange"),
            ("Snake", "s", 2...8, "green"),
            ("Spider", "m", 5...15, "black"),
            ("Tiger", "T", 1...3, "orange"),
            ("Turtle", "t", 2...6, "green"),
            ("Wolf", "w", 2...6, "gray"),
            ("Demon", "&", 1...2, "lred"),
            ("Lava Beast", "@", 1...2, "orange"),
            ("Rock Monster", "R", 1...2, "gray"),
            ("Space Void", "V", 1...3, "purple")
        ]
        
        // Pick two different species
        let teamAIndex = Int.random(in: 0..<species.count)
        var teamBIndex = Int.random(in: 0..<species.count)
        while teamBIndex == teamAIndex {
            teamBIndex = Int.random(in: 0..<species.count)
        }
        
        let teamA = species[teamAIndex]
        let teamB = species[teamBIndex]
        
        teamAName = teamA.0
        teamAGlyph = Character(teamA.1)
        teamACount = Int.random(in: teamA.2)
        teamAColorName = teamA.3
        
        teamBName = teamB.0
        teamBGlyph = Character(teamB.1)
        teamBCount = Int.random(in: teamB.2)
        teamBColorName = teamB.3
    }
    
    func pickTeam(_ team: Int) {
        print("📍 [INIT] pickTeam(\(team)) starting...")
        pickedTeam = team
        battleFinished = false
        wasCorrect = false
        
        // Initialize battle simulation
        let battleSeed = seed &+ UInt64(round)
        print("📍 [INIT] Creating GameCore with seed \(battleSeed)")
        battleCore = GameCore(seed: battleSeed)
        print("📍 [INIT] GameCore created")
        
        // Get species directory from bundle
        guard let speciesDir = Bundle.main.resourcePath?.appending("/species") else {
            print("❌ ERROR: Could not find species directory in bundle")
            print("   Bundle path: \(Bundle.main.resourcePath ?? "nil")")
            return
        }
        
        print("\n🎯 Initializing battle...")
        print("   Species dir: \(speciesDir)")
        
        // Verify species files exist
        let fileManager = FileManager.default
        let chickenPath = "\(speciesDir)/chicken.yaml"
        let baboonPath = "\(speciesDir)/baboon.yaml"
        
        print("   Checking files...")
        print("   - chicken.yaml exists: \(fileManager.fileExists(atPath: chickenPath))")
        print("   - baboon.yaml exists: \(fileManager.fileExists(atPath: baboonPath))")
        
        if let contents = try? fileManager.contentsOfDirectory(atPath: speciesDir) {
            print("   Directory contents: \(contents)")
        }
        
        print("   Team A: \(teamACount)x \(teamAName)")
        print("   Team B: \(teamBCount)x \(teamBName)")
        
        // Create team JSON with species IDs - convert names to file format (lowercase with underscores)
        let teamASpeciesId = teamAName.lowercased().replacingOccurrences(of: " ", with: "_")
        let teamBSpeciesId = teamBName.lowercased().replacingOccurrences(of: " ", with: "_")
        
        let teamAMembers = (0..<teamACount).map { _ in "{\"species_id\": \"\(teamASpeciesId)\"}" }.joined(separator: ",")
        let teamBMembers = (0..<teamBCount).map { _ in "{\"species_id\": \"\(teamBSpeciesId)\"}" }.joined(separator: ",")
        
        let teamAJson = "[\(teamAMembers)]"
        let teamBJson = "[\(teamBMembers)]"
        
        print("   Team A JSON: \(teamAJson)")
        print("   Team B JSON: \(teamBJson)")
        
        let success = battleCore?.initWithSpecies(speciesDir: speciesDir, teamA: teamAJson, teamB: teamBJson) ?? false
        if !success {
            print("❌ ERROR: Failed to initialize battle with species")
            print("   This means either:")
            print("   1. Species files are not in the bundle")
            print("   2. JSON is malformed")
            print("   3. Species IDs don't match file names")
        } else {
            print("✅ Battle initialized successfully!")
            if let state = battleCore?.getState() {
                print("   Loaded: \(state.teamA.count) vs \(state.teamB.count) actors")
                print("   Grid: \(state.grid.width)x\(state.grid.height)")
            } else {
                print("   ⚠️ State returned nil after successful init")
            }
        }
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
