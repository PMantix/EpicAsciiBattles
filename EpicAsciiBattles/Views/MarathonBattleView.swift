import SwiftUI

/// A self-contained marathon battle view for the home screen
/// Runs continuous battles with teams entering/exiting, with memory-safe cleanup
struct MarathonBattleView: View {
    // Marathon-specific state (isolated from main game)
    @StateObject private var marathonState = MarathonBattleState()
    
    // Muted background opacity for title screen aesthetic
    let backgroundOpacity: Double = 0.6
    
    let gridWidth: Int = 16
    let gridHeight: Int = 6
    
    var body: some View {
        GeometryReader { geometry in
            let cellSize = min(geometry.size.width / CGFloat(gridWidth),
                               geometry.size.height / CGFloat(gridHeight))
            let totalWidth = cellSize * CGFloat(gridWidth)
            let totalHeight = cellSize * CGFloat(gridHeight)
            let offsetX = (geometry.size.width - totalWidth) / 2
            let offsetY = (geometry.size.height - totalHeight) / 2
            
            Canvas { context, _ in
                // Draw blood/VFX layer first (behind everything)
                for vfx in marathonState.vfxParticles {
                    let px = offsetX + CGFloat(vfx.x) * cellSize
                    let py = offsetY + CGFloat(vfx.y) * cellSize
                    
                    let color = vfx.color.opacity(vfx.opacity * backgroundOpacity)
                    drawTile(context, char: vfx.glyph, 
                            at: CGPoint(x: px, y: py), 
                            size: cellSize, color: UIColor(color))
                }
                
                // Draw ground debris (bones, dust)
                for debris in marathonState.debris {
                    let px = offsetX + CGFloat(debris.x) * cellSize
                    let py = offsetY + CGFloat(debris.y) * cellSize
                    
                    let color = debris.color.opacity(debris.opacity * backgroundOpacity)
                    drawTile(context, char: debris.glyph, 
                            at: CGPoint(x: px, y: py), 
                            size: cellSize, color: UIColor(color))
                }
                
                // Draw all combatants
                for combatant in marathonState.combatants {
                    let px = offsetX + CGFloat(combatant.x) * cellSize
                    let py = offsetY + CGFloat(combatant.y) * cellSize
                    
                    let color = combatant.displayColor.opacity(combatant.opacity * backgroundOpacity)
                    drawTile(context, char: combatant.displayGlyph, 
                            at: CGPoint(x: px, y: py), 
                            size: cellSize, color: UIColor(color))
                }
            }
        }
        .onAppear {
            marathonState.start(gridWidth: gridWidth, gridHeight: gridHeight)
        }
        .onDisappear {
            marathonState.stop()
        }
    }
    
    private func drawTile(_ context: GraphicsContext, char: Character, at point: CGPoint, size: CGFloat, color: UIColor) {
        let renderer = TilesetRenderer.shared
        if renderer.isAvailable {
            let scale = size / CGFloat(renderer.sourceTileWidth)
            if let tileImage = renderer.getTile(index: renderer.tileIndex(for: char), color: color, scale: scale) {
                context.draw(Image(uiImage: tileImage), at: CGPoint(x: point.x + size/2, y: point.y + size/2))
                return
            }
        }
        // Fallback: draw character using system font
        let text = Text(String(char))
            .font(.system(size: size * 0.7, weight: .bold, design: .monospaced))
            .foregroundColor(Color(color))
        context.draw(text, at: CGPoint(x: point.x + size/2, y: point.y + size/2))
    }
}

/// State manager for marathon battles - handles simulation, team transitions, and cleanup
class MarathonBattleState: ObservableObject {
    @Published var combatants: [MarathonCombatant] = []
    @Published var debris: [MarathonDebris] = []
    @Published var vfxParticles: [MarathonVFX] = []
    
    private var timer: Timer?
    private var battleCore: GameCore?
    private var gridWidth: Int = 16
    private var gridHeight: Int = 6
    private var tickCount: Int = 0
    private var reinforcementCooldown: Int = 0
    
    // Track which team needs reinforcements
    private var teamASpecies: SpeciesInfo?
    private var teamBSpecies: SpeciesInfo?
    
    // Blood and gib glyphs
    private let bloodGlyphs: [Character] = ["*", "~", ".", ",", "'"]
    private let gibGlyphs: [Character] = ["%", ";", ":", "&", "@"]
    
    // Species pool for random selection
    private let speciesPool: [SpeciesInfo] = [
        SpeciesInfo(id: "chicken", name: "Chicken", glyph: "C", color: "yellow"),
        SpeciesInfo(id: "baboon", name: "Baboon", glyph: "B", color: "brown"),
        SpeciesInfo(id: "cat", name: "Cat", glyph: "c", color: "lgray"),
        SpeciesInfo(id: "dog", name: "Dog", glyph: "d", color: "brown"),
        SpeciesInfo(id: "rat", name: "Rat", glyph: "r", color: "dgray"),
        SpeciesInfo(id: "snake", name: "Snake", glyph: "s", color: "lgreen"),
        SpeciesInfo(id: "spider", name: "Spider", glyph: "x", color: "lgray"),
        SpeciesInfo(id: "wolf", name: "Wolf", glyph: "w", color: "lgray"),
        SpeciesInfo(id: "bear", name: "Bear", glyph: "U", color: "brown"),
        SpeciesInfo(id: "lion", name: "Lion", glyph: "L", color: "yellow"),
        SpeciesInfo(id: "tiger", name: "Tiger", glyph: "T", color: "orange"),
        SpeciesInfo(id: "dragon", name: "Dragon", glyph: "D", color: "lred"),
        SpeciesInfo(id: "demon", name: "Demon", glyph: "&", color: "lred"),
        SpeciesInfo(id: "ant", name: "Ant", glyph: "a", color: "brown"),
        SpeciesInfo(id: "goose", name: "Goose", glyph: "G", color: "white"),
    ]
    
    struct SpeciesInfo {
        let id: String
        let name: String
        let glyph: Character
        let color: String
    }
    
    func start(gridWidth: Int, gridHeight: Int) {
        self.gridWidth = gridWidth
        self.gridHeight = gridHeight
        
        // Start first battle
        startNewBattle()
        
        // Run simulation timer - slightly faster for more action
        timer = Timer.scheduledTimer(withTimeInterval: 0.10, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        battleCore = nil
        combatants.removeAll()
        debris.removeAll()
        vfxParticles.removeAll()
    }
    
    private func startNewBattle() {
        // Pick two different random species
        var shuffled = speciesPool.shuffled()
        teamASpecies = shuffled.removeFirst()
        teamBSpecies = shuffled.first(where: { $0.id != teamASpecies?.id }) ?? shuffled.first
        
        guard let teamA = teamASpecies, let teamB = teamBSpecies else { return }
        
        // Team sizes (4-6 each)
        let teamACount = Int.random(in: 4...6)
        let teamBCount = Int.random(in: 4...6)
        
        // Initialize battle core
        let seed = UInt64.random(in: 0...UInt64.max)
        battleCore = GameCore(seed: seed)
        
        guard let speciesDir = Bundle.main.resourcePath?.appending("/species") else { return }
        
        let teamAMembers = (0..<teamACount).map { _ in "{\"species_id\": \"\(teamA.id)\"}" }.joined(separator: ",")
        let teamBMembers = (0..<teamBCount).map { _ in "{\"species_id\": \"\(teamB.id)\"}" }.joined(separator: ",")
        
        let teamAJson = "[\(teamAMembers)]"
        let teamBJson = "[\(teamBMembers)]"
        
        _ = battleCore?.initWithSpecies(speciesDir: speciesDir, teamA: teamAJson, teamB: teamBJson)
        
        tickCount = 0
        reinforcementCooldown = 0
        
        // Clear old combatants but keep debris for continuity
        combatants.removeAll()
        updateCombatantsFromState()
    }
    
    private func sendReinforcements(forTeam team: Int) {
        // Pick a new species for the reinforcing team
        let newSpecies = speciesPool.randomElement()!
        
        if team == 0 {
            teamASpecies = newSpecies
        } else {
            teamBSpecies = newSpecies
        }
        
        // Create new battle with survivors + reinforcements
        guard let teamA = teamASpecies, let teamB = teamBSpecies else { return }
        
        // Count current survivors
        let teamASurvivors = combatants.filter { $0.team == 0 && $0.state == .alive }.count
        let teamBSurvivors = combatants.filter { $0.team == 1 && $0.state == .alive }.count
        
        // Add reinforcements to the losing side
        let reinforcementCount = Int.random(in: 4...6)
        let newTeamACount = team == 0 ? reinforcementCount : max(1, teamASurvivors)
        let newTeamBCount = team == 1 ? reinforcementCount : max(1, teamBSurvivors)
        
        // Initialize new battle core
        let seed = UInt64.random(in: 0...UInt64.max)
        battleCore = GameCore(seed: seed)
        
        guard let speciesDir = Bundle.main.resourcePath?.appending("/species") else { return }
        
        let teamAMembers = (0..<newTeamACount).map { _ in "{\"species_id\": \"\(teamA.id)\"}" }.joined(separator: ",")
        let teamBMembers = (0..<newTeamBCount).map { _ in "{\"species_id\": \"\(teamB.id)\"}" }.joined(separator: ",")
        
        let teamAJson = "[\(teamAMembers)]"
        let teamBJson = "[\(teamBMembers)]"
        
        _ = battleCore?.initWithSpecies(speciesDir: speciesDir, teamA: teamAJson, teamB: teamBJson)
        
        // Clear combatants and refresh from new state
        combatants.removeAll()
        tickCount = 0
        reinforcementCooldown = 30 // Cooldown before next reinforcement
        updateCombatantsFromState()
    }
    
    private func tick() {
        tickCount += 1
        if reinforcementCooldown > 0 {
            reinforcementCooldown -= 1
        }
        
        // Update VFX particles
        updateVFX()
        
        // Update debris (fade out old debris)
        updateDebris()
        
        // Check for dying combatants and convert to debris
        let dyingCombatants = combatants.filter { $0.state == .dying }
        for dying in dyingCombatants {
            advanceDeathAnimation(dying)
        }
        
        // If battle core exists and isn't finished, tick it
        if let core = battleCore, !core.isFinished() {
            // Track who was alive before tick
            let previousAlive = Set(combatants.filter { $0.state == .alive }.map { $0.id })
            
            core.tick()
            updateCombatantsFromState()
            
            // Check for kills and spawn blood/gibs
            let currentAlive = Set(combatants.filter { $0.state == .alive }.map { $0.id })
            
            // Spawn VFX for newly dead
            for deadId in previousAlive.subtracting(currentAlive) {
                if let deadCombatant = combatants.first(where: { $0.id == deadId }) {
                    spawnDeathVFX(at: deadCombatant.x, y: deadCombatant.y, color: deadCombatant.color)
                }
            }
        } else {
            // Battle ended - check if we need reinforcements
            let teamAAlive = combatants.filter { $0.team == 0 && $0.state == .alive }.count
            let teamBAlive = combatants.filter { $0.team == 1 && $0.state == .alive }.count
            
            if reinforcementCooldown == 0 {
                if teamAAlive == 0 && teamBAlive > 0 {
                    // Team A wiped, send new challengers
                    sendReinforcements(forTeam: 0)
                } else if teamBAlive == 0 && teamAAlive > 0 {
                    // Team B wiped, send new challengers
                    sendReinforcements(forTeam: 1)
                } else if teamAAlive == 0 && teamBAlive == 0 {
                    // Both wiped, start fresh
                    startNewBattle()
                }
            }
        }
        
        // Memory cleanup
        if debris.count > 80 {
            debris = Array(debris.suffix(40))
        }
        if vfxParticles.count > 60 {
            vfxParticles = Array(vfxParticles.suffix(30))
        }
    }
    
    private func spawnDeathVFX(at x: Int, y: Int, color: Color) {
        // Spawn blood splats around the death location
        for _ in 0..<Int.random(in: 3...6) {
            let offsetX = Int.random(in: -1...1)
            let offsetY = Int.random(in: -1...1)
            let newX = max(0, min(gridWidth - 1, x + offsetX))
            let newY = max(0, min(gridHeight - 1, y + offsetY))
            
            vfxParticles.append(MarathonVFX(
                x: newX,
                y: newY,
                glyph: bloodGlyphs.randomElement() ?? "*",
                color: DFColors.lred,
                opacity: Double.random(in: 0.6...1.0),
                age: 0,
                lifetime: Int.random(in: 20...40)
            ))
        }
        
        // Spawn gibs
        for _ in 0..<Int.random(in: 1...3) {
            let offsetX = Int.random(in: -2...2)
            let offsetY = Int.random(in: -1...1)
            let newX = max(0, min(gridWidth - 1, x + offsetX))
            let newY = max(0, min(gridHeight - 1, y + offsetY))
            
            debris.append(MarathonDebris(
                x: newX,
                y: newY,
                glyph: gibGlyphs.randomElement() ?? "%",
                color: DFColors.lred.opacity(0.7),
                opacity: 0.8,
                age: 0
            ))
        }
    }
    
    private func updateCombatantsFromState() {
        guard let state = battleCore?.getState() else { return }
        
        // Build set of currently alive actor IDs
        var aliveIds = Set<UInt32>()
        
        for actor in state.teamA where actor.isAlive {
            aliveIds.insert(actor.id)
            if let index = combatants.firstIndex(where: { $0.id == actor.id }) {
                combatants[index].x = Int(actor.x)
                combatants[index].y = Int(actor.y)
            } else {
                combatants.append(MarathonCombatant(
                    id: actor.id,
                    x: Int(actor.x),
                    y: Int(actor.y),
                    glyph: actor.glyph,
                    color: DFColors.named(actor.color),
                    team: 0
                ))
            }
        }
        
        for actor in state.teamB where actor.isAlive {
            aliveIds.insert(actor.id)
            if let index = combatants.firstIndex(where: { $0.id == actor.id }) {
                combatants[index].x = Int(actor.x)
                combatants[index].y = Int(actor.y)
            } else {
                combatants.append(MarathonCombatant(
                    id: actor.id,
                    x: Int(actor.x),
                    y: Int(actor.y),
                    glyph: actor.glyph,
                    color: DFColors.named(actor.color),
                    team: 1
                ))
            }
        }
        
        // Mark dead combatants for death animation
        for i in combatants.indices {
            if !aliveIds.contains(combatants[i].id) && combatants[i].state == .alive {
                combatants[i].state = .dying
                combatants[i].deathPhase = 0
            }
        }
    }
    
    private func advanceDeathAnimation(_ combatant: MarathonCombatant) {
        guard let index = combatants.firstIndex(where: { $0.id == combatant.id }) else { return }
        
        combatants[index].deathPhase += 1
        
        switch combatants[index].deathPhase {
        case 1...2:
            // Corpse
            combatants[index].displayGlyph = "%"
            combatants[index].opacity = 0.8
        case 3...4:
            // Bones
            combatants[index].displayGlyph = ";"
            combatants[index].opacity = 0.6
        case 5...6:
            // Crumble
            combatants[index].displayGlyph = ","
            combatants[index].opacity = 0.4
        default:
            // Leave debris and remove combatant
            debris.append(MarathonDebris(
                x: combatants[index].x,
                y: combatants[index].y,
                glyph: [",", ".", "`", ";"].randomElement() ?? ".",
                color: DFColors.dgray,
                opacity: 0.3,
                age: 0
            ))
            combatants.remove(at: index)
        }
    }
    
    private func updateVFX() {
        for i in vfxParticles.indices.reversed() {
            vfxParticles[i].age += 1
            // Fade based on lifetime
            let progress = Double(vfxParticles[i].age) / Double(vfxParticles[i].lifetime)
            vfxParticles[i].opacity = max(0, 1.0 - progress)
            
            if vfxParticles[i].age >= vfxParticles[i].lifetime {
                vfxParticles.remove(at: i)
            }
        }
    }
    
    private func updateDebris() {
        for i in debris.indices.reversed() {
            debris[i].age += 1
            // Fade debris over time (slower fade)
            if debris[i].age > 150 {
                debris[i].opacity -= 0.01
                if debris[i].opacity <= 0 {
                    debris.remove(at: i)
                }
            }
        }
    }
}

/// A combatant in the marathon battle
struct MarathonCombatant: Identifiable {
    let id: UInt32
    var x: Int
    var y: Int
    var glyph: Character
    var color: Color
    var team: Int
    var state: CombatantState = .alive
    var deathPhase: Int = 0
    var opacity: Double = 1.0
    private var _displayGlyph: Character = "%"
    
    init(id: UInt32, x: Int, y: Int, glyph: Character, color: Color, team: Int) {
        self.id = id
        self.x = x
        self.y = y
        self.glyph = glyph
        self.color = color
        self.team = team
        self._displayGlyph = "%"
    }
    
    var displayGlyph: Character {
        get { state == .alive ? glyph : _displayGlyph }
        set { _displayGlyph = newValue }
    }
    
    var displayColor: Color {
        state == .alive ? color : DFColors.dgray
    }
    
    enum CombatantState {
        case alive
        case dying
    }
}

/// Ground debris left by dead combatants
struct MarathonDebris {
    var x: Int
    var y: Int
    var glyph: Character
    var color: Color
    var opacity: Double
    var age: Int
}

/// VFX particle (blood, sparks, etc)
struct MarathonVFX {
    var x: Int
    var y: Int
    var glyph: Character
    var color: Color
    var opacity: Double
    var age: Int
    var lifetime: Int
}

#Preview {
    ZStack {
        DFColors.black.ignoresSafeArea()
        MarathonBattleView()
            .frame(height: 150)
    }
}
