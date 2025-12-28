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
    
    // Team balancing (new meta game)
    @Published var originalTeamACount: Int = 0
    @Published var originalTeamBCount: Int = 0
    @Published var adjustmentsUsed: Int = 0
    
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
        
        // Scale battle size with round number
        let roundScale = 1.0 + 0.15 * Double(round - 1) // 15% bigger each round
        
        // All available species: (name, glyph, base count range, color)
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
        // Scale count with round, capped at reasonable max
        let baseCountA = Int.random(in: teamA.2)
        teamACount = min(40, max(1, Int(Double(baseCountA) * roundScale)))
        teamAColorName = teamA.3
        originalTeamACount = teamACount
        
        teamBName = teamB.0
        teamBGlyph = Character(teamB.1)
        let baseCountB = Int.random(in: teamB.2)
        teamBCount = min(40, max(1, Int(Double(baseCountB) * roundScale)))
        teamBColorName = teamB.3
        originalTeamBCount = teamBCount
        
        // Reset adjustments for new round
        adjustmentsUsed = 0
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
    
    /// Maximum adjustments allowed based on total score (progression unlock)
    var maxAdjustments: Int {
        if score >= 2000 { return 6 }
        if score >= 1000 { return 5 }
        if score >= 500 { return 4 }
        if score >= 200 { return 3 }
        return 2
    }
    
    /// Remaining adjustments this round
    var adjustmentsRemaining: Int {
        max(0, maxAdjustments - adjustmentsUsed)
    }
    
    /// Calculate battle closeness ratio (0.0 = total blowout, 1.0 = perfectly close)
    /// Based on what percentage of total combatants survived
    func battleCloseness(survivorCount: Int, totalStartCount: Int) -> Double {
        guard totalStartCount > 0 else { return 0 }
        let survivorRatio = Double(survivorCount) / Double(totalStartCount)
        // Lower survivors = closer battle = better
        // 0% survivors = perfect (1.0 closeness)
        // 50%+ survivors = blowout (0.0 closeness)
        let closeness = max(0, 1.0 - (survivorRatio * 2.0))
        return closeness
    }
    
    /// Determine if battle was close enough to continue (not a blowout)
    /// Blowout threshold: if more than 60% of one side survived, it's a loss
    func isBlowout(survivorCount: Int, totalStartCount: Int) -> Bool {
        guard totalStartCount > 0 else { return true }
        let survivorRatio = Double(survivorCount) / Double(totalStartCount)
        // More than 50% survivors = blowout (run ends)
        return survivorRatio > 0.5
    }
    
    /// Trophy tier based on how close the battle was (survivors)
    /// 3 trophies: 0-10% survivors (near total annihilation)
    /// 2 trophies: 10-25% survivors (very close)
    /// 1 trophy: 25-50% survivors (close enough)
    /// 0 trophies: 50%+ survivors (blowout - run ends)
    func trophyTier(survivorCount: Int, totalStartCount: Int) -> Int {
        guard totalStartCount > 0 else { return 0 }
        let survivorRatio = Double(survivorCount) / Double(totalStartCount)
        
        if survivorRatio <= 0.10 { return 3 } // Near total annihilation
        if survivorRatio <= 0.25 { return 2 } // Very close
        if survivorRatio <= 0.50 { return 1 } // Close enough
        return 0 // Blowout
    }
    
    /// Calculate score based on closeness (survivors ratio)
    func calculateScore(survivorCount: Int, totalStartCount: Int) -> Int {
        let baseScore = 50
        let roundMultiplier = 1.0 + 0.15 * Double(round - 1) // Slightly higher scaling
        
        let tier = trophyTier(survivorCount: survivorCount, totalStartCount: totalStartCount)
        let trophyMultiplier: Double
        switch tier {
        case 3: trophyMultiplier = 3.0  // Near annihilation - 3 trophies
        case 2: trophyMultiplier = 2.0  // Very close - 2 trophies
        case 1: trophyMultiplier = 1.5  // Close enough - 1 trophy
        default: trophyMultiplier = 0.0 // Blowout - no points
        }
        
        return Int(Double(baseScore) * roundMultiplier * trophyMultiplier)
    }
    
    /// Legacy methods for compatibility
    var trophyTier: Int {
        return 1 // Default - will be overridden by battle result
    }
    
    func calculateScore(adjustmentsRemaining: Int) -> Int {
        return 50 // Fallback
    }
    
    func calculateScore(isUnderdog: Bool) -> Int {
        return 50 // Fallback
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
