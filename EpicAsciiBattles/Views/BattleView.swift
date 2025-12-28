import SwiftUI

struct BattleView: View {
    @EnvironmentObject var gameState: GameState
    @ObservedObject private var settings = GameSettings.shared
    @State private var battleState: BattleState?
    @State private var combatLog: [LogEntry] = []
    @State private var isSimulating = false
    @State private var timer: Timer?
    @State private var hitBlips: [HitBlip] = []
    @State private var showEndOverlay = false
    @State private var battleResult: BattleResult? = nil // WIN or LOSS result
    @State private var persistentMarks: [GridMark] = [] // Blood, gibs, trampled terrain
    @State private var trampleMap: [Int: Int] = [:] // Track how many times each tile has been walked on
    @State private var hitFlashes: [HitFlash] = [] // Actor hit flashes for brightening
    @State private var backgroundTints: [BackgroundTint] = [] // Blood/vomit background tints
    
    var body: some View {
        ZStack {
            DFColors.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar with stats
                if let run = gameState.currentRun {
                    VStack(spacing: 8) {
                        TilesetTextView(text: "Round \(run.round)", color: DFColors.white, size: 16)
                        
                        if let state = battleState {
                            VStack(spacing: 6) {
                                let teamAColor = state.teamA.first.map { DFColors.named($0.color) } ?? DFColors.lgreen
                                let teamBColor = state.teamB.first.map { DFColors.named($0.color) } ?? DFColors.lred
                                TeamStatsBar(team: state.teamA, color: teamAColor, label: run.teamAName.uppercased())
                                TeamStatsBar(team: state.teamB, color: teamBColor, label: run.teamBName.uppercased())
                            }
                            .padding(.horizontal, 12)
                        }
                    }
                    .padding(.vertical, 12)
                    .background(DFColors.dgray)
                }
                
                // Battle grid
                ZStack {
                    Rectangle()
                        .fill(DFColors.black)
                    
                    if let state = battleState {
                        BattleGridView(battleState: state, blips: hitBlips, persistentMarks: persistentMarks, 
                                     trampleMap: trampleMap, hitFlashes: hitFlashes, backgroundTints: backgroundTints)
                    } else {
                        Text("[Initializing Battle...]")
                            .font(.system(.title, design: .monospaced))
                            .foregroundColor(.green.opacity(0.5))
                    }
                    
                    // WIN/LOSS overlay
                    if showEndOverlay {
                        VStack {
                            Spacer()
                            EndBannerView(result: battleResult) {
                                handleEndTap()
                            }
                                .padding(.bottom, 40)
                        }
                    }
                }
                
                // Combat Log (always visible at bottom)
                VStack(alignment: .leading, spacing: 0) {
                    // Log header with clear button
                    HStack {
                        TilesetTextView(text: "Combat Log", color: DFColors.white, size: 10)
                        
                        Spacer()
                        
                        Button(action: {
                            combatLog.removeAll()
                        }) {
                            TilesetTextView(text: "Clear", color: .red, size: 9)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.5))
                    
                    // Scrollable log content
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(Array(combatLog.enumerated()), id: \.offset) { index, entry in
                                    Text(entry.text)
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(entry.color)
                                        .fontWeight(entry.isCritical ? .bold : .regular)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .id(index)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                        }
                        .frame(height: 200)
                        .background(DFColors.black.opacity(0.9))
                        .onChange(of: combatLog.count) { _ in
                            if let lastIndex = combatLog.indices.last {
                                proxy.scrollTo(lastIndex, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Bottom controls
                HStack {
                    Button(action: {
                        stepSimulation()
                    }) {
                        TilesetTextView(text: "Step", color: DFColors.white, size: 12)
                            .padding(8)
                            .background(Color.blue.opacity(0.3))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    if isSimulating {
                        Button(action: {
                            stopSimulation()
                        }) {
                            TilesetTextView(text: "Pause", color: DFColors.white, size: 12)
                                .padding(8)
                                .background(Color.orange.opacity(0.3))
                                .cornerRadius(8)
                        }
                    } else {
                        Button(action: {
                            startSimulation()
                        }) {
                            TilesetTextView(text: timer == nil ? "Auto" : "Resume", color: DFColors.white, size: 12)
                                .padding(8)
                                .background(Color.green.opacity(0.3))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(DFColors.dgray)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Add initial log entry
            if let run = gameState.currentRun {
                combatLog.append(LogEntry(text: "===== BATTLE START =====", color: DFColors.yellow, isCritical: true))
                combatLog.append(LogEntry(text: "Team A: \(run.teamACount)x \(run.teamAName)", color: DFColors.lgreen, isCritical: false))
                combatLog.append(LogEntry(text: "Team B: \(run.teamBCount)x \(run.teamBName)", color: DFColors.lred, isCritical: false))
                combatLog.append(LogEntry(text: "========================", color: DFColors.yellow, isCritical: true))
                combatLog.append(LogEntry(text: "", color: .white, isCritical: false))
                
                print("🎮 Battle View appeared")
                print("   Team A: \(run.teamACount)x \(run.teamAName)")
                print("   Team B: \(run.teamBCount)x \(run.teamBName)")
                
                // Get initial state immediately
                if let core = run.battleCore, let state = core.getState() {
                    battleState = state
                    print("   Initial state: Grid \(state.grid.width)x\(state.grid.height)")
                    print("   Team A actors: \(state.teamA.count)")
                    print("   Team B actors: \(state.teamB.count)")
                } else {
                    print("   ⚠️ Failed to get initial state")
                }
                
                // Auto-start battle immediately
                startSimulation()
            }
        }
        .onDisappear {
            stopSimulation()
        }
    }
    
    func startSimulation() {
        guard let run = gameState.currentRun else { return }
        
        isSimulating = true
        // Slower tick rate for better visibility (2 ticks per second)
        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            guard let core = run.battleCore else { return }
            
            if core.isFinished() {
                finishBattle()
                return
            }
            
            // Tick the simulation
            core.tick()
            
            // Get events and add visuals/log
            let events = core.getEvents()
            let newState = core.getState()
            battleState = newState
            handleEvents(events, state: newState)
        }
    }
    
    func stopSimulation() {
        isSimulating = false
        timer?.invalidate()
    }
    
    func stepSimulation() {
        guard let run = gameState.currentRun else { return }
        guard let core = run.battleCore else {
            print("⚠️ No battle core available")
            return
        }
        
        if core.isFinished() {
            print("⚠️ Battle already finished")
            finishBattle()
            return
        }
        
        print("⏭️ Stepping simulation...")
        
        // Tick the simulation
        core.tick()
        
        // Get events and add to log/visuals
        let events = core.getEvents()
        print("   Got \(events.count) events")
        let newState = core.getState()
        if let state = newState {
            print("   State updated: \(state.teamA.count) vs \(state.teamB.count)")
            battleState = state
        } else {
            print("   ⚠️ Failed to get state")
        }
        handleEvents(events, state: newState)
        
        // Check if finished
        if core.isFinished() {
            print("   Battle is now finished")
        }
    }

    private func actorPosition(_ actorId: UInt32, state: BattleState?) -> (Int32, Int32)? {
        guard let state else { return nil }
        if let found = state.teamA.first(where: { $0.id == actorId }) {
            return (found.x, found.y)
        }
        if let found = state.teamB.first(where: { $0.id == actorId }) {
            return (found.x, found.y)
        }
        return nil
    }
    
    private func addBlip(x: Int32, y: Int32, glyph: String, color: Color, ttl: TimeInterval) {
        let now = Date()
        hitBlips = hitBlips.filter { $0.expires > now }
        let expires = now.addingTimeInterval(ttl)
        hitBlips.append(HitBlip(x: x, y: y, glyph: glyph, color: color, expires: expires))
    }
    
    private func handleEvents(_ events: [BattleEvent], state: BattleState?) {
        let now = Date()
        hitBlips = hitBlips.filter { $0.expires > now }
        hitFlashes = hitFlashes.filter { $0.expires > now }
        backgroundTints = backgroundTints.filter { $0.expires > now }
        
        guard let state = state else { return }
        let gridWidth = Int(state.grid.width)
        let gore = settings.goreIntensity
        let motionScale = settings.reducedMotion ? 0.5 : 1.0
        
        // Build actor name map for flavorful descriptions
        var actorNames: [UInt32: String] = [:]
        for actor in state.teamA {
            actorNames[actor.id] = formatActorName(actor)
        }
        for actor in state.teamB {
            actorNames[actor.id] = formatActorName(actor)
        }
        
        for event in events {
            let logEntry = event.describe(names: actorNames)
            if !logEntry.isEmpty {
                // Determine color and criticality based on event type
                let (color, isCritical) = eventStyle(for: event)
                combatLog.append(LogEntry(text: logEntry, color: color, isCritical: isCritical))
            }
            
            switch event {
            case .hit(let attackerId, let defenderId, _, let damage, _):
                if let (x, y) = actorPosition(defenderId, state: state) {
                    // Hit flash on defender (brighten actor glyph)
                    addHitFlash(actorId: defenderId, duration: 0.15 * motionScale)
                    
                    // Impact particles
                    let glyphs = ["/", "\\", "x", "X", "*"]
                    let glyph = glyphs.randomElement() ?? "x"
                    addBlip(x: x, y: y, glyph: glyph, color: .red, ttl: 0.45 * gore.particleDuration * motionScale)
                    
                    // Subtle blood tint on background (single tile only)
                    addBackgroundTint(x: x, y: y, radius: 0, color: .red, 
                                     opacity: gore.tintOpacity * 0.3, duration: 0.4 * gore.particleDuration)
                }
                // Flash on attacker too
                if let (x, y) = actorPosition(attackerId, state: state) {
                    addHitFlash(actorId: attackerId, duration: 0.1 * motionScale)
                    addBlip(x: x, y: y, glyph: "!", color: .orange, ttl: 0.25 * motionScale)
                }
                
            case .bleed(let actorId, let amount):
                if let (x, y) = actorPosition(actorId, state: state) {
                    addBlip(x: x, y: y, glyph: "~", color: .red.opacity(0.8), ttl: 0.35 * gore.particleDuration * motionScale)
                    
                    // Add permanent blood stains based on gore setting
                    if Double.random(in: 0...1) < gore.bloodStainChance {
                        let stainGlyphs = [".", ",", "'", "`"]
                        let stain = stainGlyphs.randomElement() ?? "."
                        persistentMarks.append(GridMark(x: x, y: y, glyph: stain, 
                                                       color: .red.opacity(0.5 + Double(amount) * 0.02), 
                                                       isPermanent: !gore.fadeMarks))
                    }
                    // No background tint for bleed - just the particle
                }
                
            case .sever(let actorId, let partId, let gibChar, let x, let y):
                // Multiple gib particles based on gore setting
                let gibCount = gore.gibCount
                let gibGlyphs = [String(gibChar), "'", "`", ",", ".", "~", "2", "3"]
                for _ in 0..<gibCount {
                    let offsetX = Int32.random(in: -2...2)
                    let offsetY = Int32.random(in: -2...2)
                    let gx = max(0, min(state.grid.width - 1, x + offsetX))
                    let gy = max(0, min(state.grid.height - 1, y + offsetY))
                    let gib = gibGlyphs.randomElement() ?? String(gibChar)
                    addBlip(x: gx, y: gy, glyph: gib, color: .red, ttl: (0.5 + Double.random(in: 0...0.5)) * gore.particleDuration * motionScale)
                    
                    // Some gibs stay permanently
                    if Double.random(in: 0...1) < 0.6 {
                        persistentMarks.append(GridMark(x: gx, y: gy, glyph: gib, 
                                                       color: .red.opacity(0.7), isPermanent: !gore.fadeMarks))
                    }
                }
                
                // Subtle blood splash (single tile)
                if let (ax, ay) = actorPosition(actorId, state: state) {
                    addHitFlash(actorId: actorId, duration: 0.3 * motionScale)
                    addBlip(x: ax, y: ay, glyph: "*", color: .orange, ttl: 0.7 * motionScale)
                    addBackgroundTint(x: ax, y: ay, radius: 1, color: .red, 
                                     opacity: gore.tintOpacity * 0.5, duration: 0.8)
                }
                
            case .death(_, let x, let y):
                addBlip(x: x, y: y, glyph: "✚", color: .gray, ttl: 1.0 * motionScale)
                persistentMarks.append(GridMark(x: x, y: y, glyph: "X", color: .gray.opacity(0.7), isPermanent: true))
                // Single tile death tint
                addBackgroundTint(x: x, y: y, radius: 0, color: .red, opacity: gore.tintOpacity * 0.4, duration: 1.0)
                
            case .vomit(_, _, let x, let y):
                addBlip(x: x, y: y, glyph: "@", color: .green, ttl: 0.6 * motionScale)
                persistentMarks.append(GridMark(x: x, y: y, glyph: "~", color: .green.opacity(0.5), isPermanent: !gore.fadeMarks))
                addBackgroundTint(x: x, y: y, radius: 0, color: .green, opacity: gore.tintOpacity * 0.3, duration: 0.6)
                
            case .statusChange(let actorId, let status, _):
                if status == "miss", let (x, y) = actorPosition(actorId, state: state) {
                    addBlip(x: x, y: y, glyph: "?", color: .yellow, ttl: 0.25 * motionScale)
                }
                
            case .bump(_, let bumpedId, let toX, let toY):
                addBlip(x: toX, y: toY, glyph: "*", color: .yellow, ttl: 0.3 * motionScale)
                if let (x, y) = actorPosition(bumpedId, state: state) {
                    addHitFlash(actorId: bumpedId, duration: 0.1 * motionScale)
                    addBlip(x: x, y: y, glyph: "!", color: .orange, ttl: 0.25 * motionScale)
                }
                
            case .move(let actorId, let fromX, let fromY, let toX, let toY):
                let fromKey = Int(fromY) * gridWidth + Int(fromX)
                let toKey = Int(toY) * gridWidth + Int(toX)
                if Double.random(in: 0...1) < 0.3 {
                    trampleMap[fromKey] = min((trampleMap[fromKey] ?? 0) + 1, 4)
                }
                if Double.random(in: 0...1) < 0.2 {
                    trampleMap[toKey] = min((trampleMap[toKey] ?? 0) + 1, 4)
                }
            }
        }
    }
    
    private func addHitFlash(actorId: UInt32, duration: TimeInterval) {
        let expires = Date().addingTimeInterval(duration)
        hitFlashes.append(HitFlash(actorId: actorId, expires: expires))
    }
    
    private func addBackgroundTint(x: Int32, y: Int32, radius: Int, color: Color, opacity: Double, duration: TimeInterval) {
        let expires = Date().addingTimeInterval(duration)
        for dy in -radius...radius {
            for dx in -radius...radius {
                let dist = sqrt(Double(dx * dx + dy * dy))
                if dist <= Double(radius) {
                    let falloff = 1.0 - (dist / Double(radius))
                    backgroundTints.append(BackgroundTint(
                        x: x + Int32(dx),
                        y: y + Int32(dy),
                        color: color,
                        opacity: opacity * falloff,
                        expires: expires
                    ))
                }
            }
        }
    }
    
    private func formatActorName(_ actor: ActorInfo) -> String {
        // Format species name with "the" article
        let speciesName = actor.speciesId.replacingOccurrences(of: "_", with: " ")
        return "the \(speciesName)"
    }
    
    private func eventStyle(for event: BattleEvent) -> (Color, Bool) {
        switch event {
        case .death:
            return (DFColors.lred, true)
        case .sever:
            return (Color(red: 1.0, green: 0.4, blue: 0.2), true) // Orange-red
        case .hit(_, _, _, let damage, _):
            return (damage >= 10 ? Color(red: 1.0, green: 0.3, blue: 0.3) : .green, damage >= 15)
        case .bleed:
            return (Color(red: 0.8, green: 0.2, blue: 0.2), false)
        case .vomit:
            return (Color(red: 0.5, green: 0.8, blue: 0.3), false)
        case .statusChange(_, let status, let active):
            if status == "fleeing" && active {
                return (DFColors.yellow, false)
            }
            return (.gray, false)
        case .bump:
            return (DFColors.yellow, false)
        case .move:
            return (.gray, false)
        }
    }
    
    func finishBattle() {
        stopSimulation()
        
        if let run = gameState.currentRun, let core = run.battleCore {
            let winner = Int(core.getWinner())
            // Win condition: Team A wins the battle
            run.wasCorrect = (winner == 0)
            run.battleFinished = true
            
            let winningTeam = winner == 0 ? run.teamAName : run.teamBName
            
            combatLog.append(LogEntry(text: "", color: .white, isCritical: false))
            combatLog.append(LogEntry(text: "═══════════════════════════", color: DFColors.yellow, isCritical: true))
            combatLog.append(LogEntry(text: "\(winningTeam) wins!", color: winner == 0 ? DFColors.lgreen : DFColors.lred, isCritical: true))
            combatLog.append(LogEntry(text: run.wasCorrect ? "VICTORY!" : "DEFEAT", 
                                     color: run.wasCorrect ? DFColors.lgreen : DFColors.lred, 
                                     isCritical: true))
            combatLog.append(LogEntry(text: "═══════════════════════════", color: DFColors.yellow, isCritical: true))
            
            if run.wasCorrect {
                let points = run.calculateScore(adjustmentsRemaining: run.adjustmentsRemaining)
                run.score += points
                battleResult = BattleResult(isWin: true, points: points, totalScore: run.score)
            } else {
                run.isActive = false
                battleResult = BattleResult(isWin: false, points: 0, totalScore: run.score)
            }
            
            // Show result overlay (user taps to continue)
            withAnimation {
                showEndOverlay = true
            }
        }
    }
    
    func handleEndTap() {
        guard let run = gameState.currentRun else { return }
        
        if run.wasCorrect {
            // Win: reset and go to next round selection
            run.pickedTeam = nil
            run.battleCore = nil
            run.battleFinished = false
            run.wasCorrect = false
            run.generateNextMatchup()
            
            // Go back to round offer (pop battle view)
            gameState.navigationPath.removeLast()
        } else {
            // Loss: go to run summary
            gameState.navigationPath.append(NavigationDestination.runSummary)
        }
    }
}

// Battle result data for end overlay
struct BattleResult {
    let isWin: Bool
    let points: Int
    let totalScore: Int
}

struct HitBlip: Identifiable {
    let id = UUID()
    let x: Int32
    let y: Int32
    let glyph: String
    let color: Color
    let expires: Date
}

struct GridMark: Identifiable {
    let id = UUID()
    let x: Int32
    let y: Int32
    let glyph: String
    let color: Color
    let isPermanent: Bool
}

struct HitFlash: Identifiable {
    let id = UUID()
    let actorId: UInt32
    let expires: Date
}

struct BackgroundTint: Identifiable {
    let id = UUID()
    let x: Int32
    let y: Int32
    let color: Color
    let opacity: Double
    let expires: Date
}

struct BattleGridView: View {
    let battleState: BattleState
    let blips: [HitBlip]
    let persistentMarks: [GridMark]
    let trampleMap: [Int: Int]
    let hitFlashes: [HitFlash]
    let backgroundTints: [BackgroundTint]
    
    var body: some View {
        GeometryReader { geometry in
            let gridWidth = Int(battleState.grid.width)
            let gridHeight = Int(battleState.grid.height)
            // Use monospaced cell sizing - each cell is square based on font
            let cellSize = min(geometry.size.width / CGFloat(gridWidth),
                               geometry.size.height / CGFloat(gridHeight))
            let fontSize = cellSize * 0.7
            let totalWidth = cellSize * CGFloat(gridWidth)
            let totalHeight = cellSize * CGFloat(gridHeight)
            let offsetX = (geometry.size.width - totalWidth) / 2
            let offsetY = (geometry.size.height - totalHeight) / 2
            
            let useTileset = TilesetRenderer.shared.isAvailable
            
            Canvas { context, _ in
                let groundGlyphs: [Character] = ["`", ".", ",", "'", "\""]
                let now = Date()
                
                // Build lookup maps for actors and blips by position
                var teamAMap: [Int: ActorInfo] = [:]
                var teamBMap: [Int: ActorInfo] = [:]
                var blipMap: [Int: HitBlip] = [:]
                var markMap: [Int: GridMark] = [:]
                var flashMap: Set<UInt32> = Set()
                var tintMap: [Int: BackgroundTint] = [:]
                
                for actor in battleState.teamA where actor.isAlive {
                    let key = Int(actor.y) * gridWidth + Int(actor.x)
                    teamAMap[key] = actor
                }
                for actor in battleState.teamB where actor.isAlive {
                    let key = Int(actor.y) * gridWidth + Int(actor.x)
                    teamBMap[key] = actor
                }
                for blip in blips where blip.expires > now {
                    let key = Int(blip.y) * gridWidth + Int(blip.x)
                    blipMap[key] = blip
                }
                for mark in persistentMarks {
                    let key = Int(mark.y) * gridWidth + Int(mark.x)
                    markMap[key] = mark
                }
                for flash in hitFlashes where flash.expires > now {
                    flashMap.insert(flash.actorId)
                }
                for tint in backgroundTints where tint.expires > now {
                    let key = Int(tint.y) * gridWidth + Int(tint.x)
                    // Keep strongest tint per cell
                    if let existing = tintMap[key], existing.opacity > tint.opacity {
                        continue
                    }
                    tintMap[key] = tint
                }
                
                // Draw exactly one character per tile
                for y in 0..<gridHeight {
                    for x in 0..<gridWidth {
                        let key = y * gridWidth + x
                        let px = offsetX + CGFloat(x) * cellSize
                        let py = offsetY + CGFloat(y) * cellSize
                        
                        // Draw background tint if present
                        if let tint = tintMap[key] {
                            let tintRect = CGRect(x: px, y: py, width: cellSize, height: cellSize)
                            context.fill(Path(tintRect), with: .color(tint.color.opacity(tint.opacity)))
                        }
                        
                        // Priority: Team A actor > Team B actor > Blip > Terrain
                        if let actor = teamAMap[key] {
                            var actorColor = DFColors.uiNamed(actor.color)
                            // Apply hit flash brightening
                            if flashMap.contains(actor.id) {
                                actorColor = brighten(actorColor, factor: 1.8)
                            }
                            if useTileset {
                                drawTile(context, char: actor.glyph, at: CGPoint(x: px, y: py), 
                                        size: cellSize, color: actorColor)
                            } else {
                                let text = Text(String(actor.glyph))
                                    .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(actorColor))
                                context.draw(text, at: CGPoint(x: px + cellSize/2, y: py + cellSize/2))
                            }
                        } else if let actor = teamBMap[key] {
                            var actorColor = DFColors.uiNamed(actor.color)
                            // Apply hit flash brightening
                            if flashMap.contains(actor.id) {
                                actorColor = brighten(actorColor, factor: 1.8)
                            }
                            if useTileset {
                                drawTile(context, char: actor.glyph, at: CGPoint(x: px, y: py), 
                                        size: cellSize, color: actorColor)
                            } else {
                                let text = Text(String(actor.glyph))
                                    .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(actorColor))
                                context.draw(text, at: CGPoint(x: px + cellSize/2, y: py + cellSize/2))
                            }
                        } else if let blip = blipMap[key] {
                            if useTileset {
                                drawTile(context, char: Character(blip.glyph), at: CGPoint(x: px, y: py),
                                        size: cellSize, color: UIColor(blip.color))
                            } else {
                                let text = Text(blip.glyph)
                                    .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                                    .foregroundColor(blip.color)
                                context.draw(text, at: CGPoint(x: px + cellSize/2, y: py + cellSize/2))
                            }
                        } else {
                            // Check for persistent marks (blood, gibs) first
                            if let mark = markMap[key] {
                                if useTileset {
                                    drawTile(context, char: Character(mark.glyph), at: CGPoint(x: px, y: py),
                                            size: cellSize, color: UIColor(mark.color))
                                } else {
                                    let text = Text(mark.glyph)
                                        .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                                        .foregroundColor(mark.color)
                                    context.draw(text, at: CGPoint(x: px + cellSize/2, y: py + cellSize/2))
                                }
                            } else {
                                // Terrain background with trampling
                                let hash = (x * 73856093) ^ (y * 19349663)
                                let trampleCount = trampleMap[key] ?? 0
                                
                                var glyph: Character
                                if trampleCount > 0 {
                                    // Trampled terrain - flatter characters
                                    let trampledGlyphs: [Character] = ["'", ".", ",", "-", "_"]
                                    glyph = trampledGlyphs[min(trampleCount, trampledGlyphs.count - 1)]
                                } else {
                                    let groundGlyphs: [Character] = ["`", ".", ",", "'", "\""]
                                    glyph = groundGlyphs[abs(hash) % groundGlyphs.count]
                                }
                                
                                let jitter = Double((hash >> 3) & 0xF) / 255.0
                                let baseGreen = 0.32 + jitter * 0.1 - Double(trampleCount) * 0.05
                                let baseRed = 0.18 + jitter * 0.05
                                let baseBlue = 0.18
                                let terrainColor = Color(red: baseRed, green: baseGreen, blue: baseBlue).opacity(0.75)
                                
                                if useTileset {
                                    drawTile(context, char: glyph, at: CGPoint(x: px, y: py),
                                            size: cellSize * 0.8, color: UIColor(terrainColor))
                                } else {
                                    let text = Text(String(glyph))
                                        .font(.system(size: fontSize * 0.6, design: .monospaced))
                                        .foregroundColor(terrainColor)
                                    context.draw(text, at: CGPoint(x: px + cellSize/2, y: py + cellSize/2))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func drawTile(_ context: GraphicsContext, char: Character, at point: CGPoint, size: CGFloat, color: UIColor) {
        let renderer = TilesetRenderer.shared
        let index = renderer.tileIndex(for: char)
        let scale = size / CGFloat(renderer.sourceTileWidth)
        
        if let tileImage = renderer.getTile(index: index, color: color, scale: scale) {
            let resolved = context.resolve(Image(uiImage: tileImage))
            context.draw(resolved, at: CGPoint(x: point.x + size/2, y: point.y + size/2))
        }
    }
    
    private func brighten(_ color: UIColor, factor: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: min(1.0, r * factor), green: min(1.0, g * factor), blue: min(1.0, b * factor), alpha: a)
    }
}

struct LogEntry {
    let text: String
    let color: Color
    let isCritical: Bool
}

struct CombatLogView: View {
    @Binding var isShowing: Bool
    let logEntries: [String]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("Combat Log")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(DFColors.white)
                    
                    Spacer()
                    
                    Button(action: {
                        isShowing = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(DFColors.lgray)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.5))
                
                // Log content
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(logEntries.enumerated()), id: \.offset) { index, entry in
                                Text(entry)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.green)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id(index)
                            }
                        }
                        .padding()
                    }
                    .frame(height: 300)
                    .background(DFColors.black.opacity(0.9))
                    .onChange(of: logEntries.count) { _ in
                        if let lastIndex = logEntries.indices.last {
                            proxy.scrollTo(lastIndex, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

// END banner overlay - shows WIN or LOSS with points
struct EndBannerView: View {
    @EnvironmentObject var gameState: GameState
    let result: BattleResult?
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            if let result = result {
                if result.isWin {
                    // WIN banner - simple text
                    TilesetTextView(text: "=== WIN ===", color: DFColors.lgreen, size: 28)
                    
                    // Points earned
                    TilesetTextView(text: "+\(result.points) points", color: DFColors.yellow, size: 22)
                    TilesetTextView(text: "Total: \(result.totalScore)", color: DFColors.white, size: 18)
                } else {
                    // LOSS banner - simple text
                    TilesetTextView(text: "=== LOSS ===", color: DFColors.lred, size: 28)
                    
                    // Final score
                    TilesetTextView(text: "Final Score: \(result.totalScore)", color: DFColors.yellow, size: 18)
                    TilesetTextView(text: "Run Ended", color: DFColors.lgray, size: 16)
                }
                
                // Tap to continue
                TilesetTextView(text: "[ Tap to Continue ]", color: DFColors.lgray, size: 14)
                    .padding(.top, 10)
            }
        }
        .padding(30)
        .background(DFColors.black.opacity(0.9))
        .cornerRadius(12)
        .onTapGesture {
            onTap()
        }
    }
}

// Team stats bar showing alive count, health, morale
struct TeamStatsBar: View {
    let team: [ActorInfo]
    let color: Color
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Team label and alive count
            HStack {
                TilesetTextView(text: "\(label)", color: color, size: 14)
                Spacer()
                TilesetTextView(text: "Alive: \(team.count)", color: DFColors.white, size: 12)
            }
            
            // Health bar - full width with more segments
            HStack(spacing: 0) {
                TilesetTextView(text: "HP:", color: DFColors.lgray, size: 10)
                    .frame(width: 30, alignment: .leading)
                
                let avgHealth = team.isEmpty ? 0 : team.map { Double($0.hp) }.reduce(0, +) / Double(team.count)
                let avgMaxHp = team.isEmpty ? 100 : team.map { Double($0.maxHp) }.reduce(0, +) / Double(team.count)
                let healthPercent = avgMaxHp > 0 ? avgHealth / avgMaxHp : 0
                let totalBars = 30 // Much longer bar
                let healthBars = max(0, min(totalBars, Int(healthPercent * Double(totalBars))))
                
                TilesetTextView(
                    text: String(repeating: "#", count: healthBars) + String(repeating: ".", count: totalBars - healthBars),
                    color: color,
                    size: 10
                )
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(DFColors.black.opacity(0.3))
        .cornerRadius(6)
    }
}