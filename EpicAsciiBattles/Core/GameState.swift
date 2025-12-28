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
    @Published var totalTrophies: Int = 0  // Total trophies earned this run
    @Published var isActive: Bool = true
    
    // Battle history for run summary
    @Published var battleHistory: [BattleHistoryEntry] = []
    
    // Current matchup (singular names for species ID, plural for display)
    @Published var teamAName: String = ""  // singular (for species ID)
    @Published var teamANamePlural: String = ""  // plural (for display)
    @Published var teamACount: Int = 0
    @Published var teamAGlyph: Character = " "
    @Published var teamBName: String = ""  // singular (for species ID)
    @Published var teamBNamePlural: String = ""  // plural (for display)
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
        
        // All available species: (singular, plural, glyph, base count range, color)
        let species: [(String, String, String, ClosedRange<Int>, String)] = [
            ("Ant", "Ants", "a", 10...30, "red"),
            ("Baboon", "Baboons", "b", 1...5, "brown"),
            ("Bear", "Bears", "B", 1...3, "brown"),
            ("Cat", "Cats", "c", 2...8, "gray"),
            ("Chicken", "Chickens", "c", 2...10, "yellow"),
            ("Chimpanzee", "Chimpanzees", "C", 1...4, "brown"),
            ("Cockroach", "Cockroaches", "i", 10...25, "brown"),
            ("Dog", "Dogs", "o", 2...7, "brown"),
            ("Donkey", "Donkeys", "d", 1...4, "gray"),
            ("Dragon", "Dragons", "D", 1...2, "lred"),
            ("Duck", "Ducks", "u", 3...12, "yellow"),
            ("Flamingo", "Flamingos", "f", 2...8, "lpink"),
            ("Gecko", "Geckos", "e", 5...15, "lgreen"),
            ("Gerbil", "Gerbils", "g", 6...18, "brown"),
            ("Goose", "Geese", "G", 2...9, "white"),
            ("Horse", "Horses", "H", 1...4, "brown"),
            ("Alligator", "Alligators", "A", 1...3, "green"),
            ("Lion", "Lions", "L", 1...3, "yellow"),
            ("Mouse", "Mice", "m", 8...25, "gray"),
            ("Rat", "Rats", "r", 6...20, "gray"),
            ("Salamander", "Salamanders", "l", 4...12, "orange"),
            ("Snake", "Snakes", "s", 2...8, "green"),
            ("Spider", "Spiders", "m", 5...15, "lgray"),
            ("Tiger", "Tigers", "T", 1...3, "orange"),
            ("Turtle", "Turtles", "t", 2...6, "green"),
            ("Wolf", "Wolves", "w", 2...6, "gray"),
            ("Demon", "Demons", "&", 1...2, "lred"),
            ("Lava Beast", "Lava Beasts", "@", 1...2, "orange"),
            ("Rock Monster", "Rock Monsters", "R", 1...2, "gray"),
            ("Space Void", "Space Voids", "V", 1...3, "purple")
        ]
        
        // Pick two different species
        let teamAIndex = Int.random(in: 0..<species.count)
        var teamBIndex = Int.random(in: 0..<species.count)
        while teamBIndex == teamAIndex {
            teamBIndex = Int.random(in: 0..<species.count)
        }
        
        let teamA = species[teamAIndex]
        let teamB = species[teamBIndex]
        
        teamAName = teamA.0  // singular
        teamANamePlural = teamA.1  // plural
        teamAGlyph = Character(teamA.2)
        // Scale count with round, capped at reasonable max
        let baseCountA = Int.random(in: teamA.3)
        teamACount = min(40, max(1, Int(Double(baseCountA) * roundScale)))
        teamAColorName = teamA.4
        originalTeamACount = teamACount
        
        teamBName = teamB.0  // singular
        teamBNamePlural = teamB.1  // plural
        teamBGlyph = Character(teamB.2)
        let baseCountB = Int.random(in: teamB.3)
        teamBCount = min(40, max(1, Int(Double(baseCountB) * roundScale)))
        teamBColorName = teamB.4
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
    
    /// Maximum adjustments allowed based on total trophies (progression unlock)
    var maxAdjustments: Int {
        if totalTrophies >= 30 { return 6 }
        if totalTrophies >= 20 { return 5 }
        if totalTrophies >= 12 { return 4 }
        if totalTrophies >= 6 { return 3 }
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
    
    /// Record a completed battle in history
    func recordBattle(winnerGlyph: Character, winnerColor: String, winnerName: String,
                      loserGlyph: Character, loserColor: String, loserName: String,
                      trophies: Int) {
        let entry = BattleHistoryEntry(
            round: round,
            winnerGlyph: winnerGlyph,
            winnerColor: winnerColor,
            winnerName: winnerName,
            loserGlyph: loserGlyph,
            loserColor: loserColor,
            loserName: loserName,
            trophies: trophies
        )
        battleHistory.append(entry)
        totalTrophies += trophies
    }
    
    func toRecord() -> RunRecord {
        RunRecord(
            runId: runId,
            timestamp: startTime,
            totalTrophies: totalTrophies,
            roundReached: round,
            seed: seed
        )
    }
}

/// A single battle result for history display
struct BattleHistoryEntry: Identifiable {
    let id = UUID()
    let round: Int
    let winnerGlyph: Character
    let winnerColor: String
    let winnerName: String
    let loserGlyph: Character
    let loserColor: String
    let loserName: String
    let trophies: Int
}
