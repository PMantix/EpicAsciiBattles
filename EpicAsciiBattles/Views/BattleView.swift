import SwiftUI

struct BattleView: View {
    @EnvironmentObject var gameState: GameState
    @State private var battleState: BattleState?
    @State private var combatLog: [String] = []
    @State private var isSimulating = false
    @State private var timer: Timer?
    @State private var hitBlips: [HitBlip] = []
    
    var body: some View {
        ZStack {
            DFColors.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                if let run = gameState.currentRun {
                    HStack {
                        Text("Round \(run.round)")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(DFColors.white)
                        
                        Spacer()
                        
                        if let state = battleState {
                            Text("Team A: \(state.teamA.count) | Team B: \(state.teamB.count)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(DFColors.lgray)
                        } else {
                            Text("Team A: \(run.teamACount) | Team B: \(run.teamBCount)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(DFColors.lgray)
                        }
                    }
                    .padding()
                    .background(DFColors.dgray)
                }
                
                // Battle grid
                ZStack {
                    Rectangle()
                        .fill(DFColors.black)
                    
                    if let state = battleState {
                        BattleGridView(battleState: state, blips: hitBlips)
                        
                        // Debug overlay
                        VStack {
                            Text("Grid: \(state.grid.width)x\(state.grid.height)")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.yellow)
                            Text("Team A: \(state.teamA.count) | Team B: \(state.teamB.count)")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.yellow)
                            Spacer()
                        }
                        .padding(4)
                    } else {
                        Text("[Initializing Battle...]")
                            .font(.system(.title, design: .monospaced))
                            .foregroundColor(.green.opacity(0.5))
                    }
                }
                
                // Combat Log (always visible at bottom)
                VStack(alignment: .leading, spacing: 0) {
                    // Log header with clear button
                    HStack {
                        Text("Combat Log")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(DFColors.white)
                        
                        Spacer()
                        
                        Button(action: {
                            combatLog.removeAll()
                        }) {
                            Text("Clear")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.red)
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
                                    Text(entry)
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(.green)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .id(index)
                                }
                            }
                            .padding(4)
                        }
                        .frame(height: 120)
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
                        Text("Step")
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .background(Color.blue.opacity(0.3))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    if isSimulating {
                        Button(action: {
                            stopSimulation()
                        }) {
                            Text("Pause")
                                .font(.system(.caption, design: .monospaced))
                                .padding(8)
                                .background(Color.orange.opacity(0.3))
                                .cornerRadius(8)
                        }
                    } else {
                        Button(action: {
                            startSimulation()
                        }) {
                            Text(timer == nil ? "Auto" : "Resume")
                                .font(.system(.caption, design: .monospaced))
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
                combatLog.append("===== BATTLE START =====")
                combatLog.append("Team A: \(run.teamACount)x \(run.teamAName)")
                combatLog.append("Team B: \(run.teamBCount)x \(run.teamBName)")
                combatLog.append("========================")
                combatLog.append("")
                
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
        
        for event in events {
            combatLog.append(event.describe())
            switch event {
            case .hit(let attackerId, let defenderId, _, _, _):
                if let (x, y) = actorPosition(defenderId, state: state) {
                    let glyphs = ["/", "\\", "x", "X"]
                    let glyph = glyphs.randomElement() ?? "x"
                    addBlip(x: x, y: y, glyph: glyph, color: .red, ttl: 0.45)
                }
                // small flash on attacker too
                if let (x, y) = actorPosition(attackerId, state: state) {
                    addBlip(x: x, y: y, glyph: "!", color: .orange, ttl: 0.3)
                }
            case .bleed(let actorId, _):
                if let (x, y) = actorPosition(actorId, state: state) {
                    addBlip(x: x, y: y, glyph: "~", color: .red.opacity(0.8), ttl: 0.35)
                }
            case .sever(let actorId, _, let gibChar, let x, let y):
                addBlip(x: x, y: y, glyph: String(gibChar), color: .red, ttl: 0.7)
                if let (ax, ay) = actorPosition(actorId, state: state) {
                    addBlip(x: ax, y: ay, glyph: "*", color: .orange, ttl: 0.7)
                }
            case .death(_, let x, let y):
                addBlip(x: x, y: y, glyph: "✚", color: .gray, ttl: 1.0)
            case .vomit(_, _, let x, let y):
                addBlip(x: x, y: y, glyph: "@", color: .green, ttl: 0.6)
            case .statusChange(let actorId, let status, _):
                if status == "miss", let (x, y) = actorPosition(actorId, state: state) {
                    addBlip(x: x, y: y, glyph: "?", color: .yellow, ttl: 0.25)
                }
            case .bump(_, let bumpedId, let toX, let toY):
                addBlip(x: toX, y: toY, glyph: "*", color: .yellow, ttl: 0.3)
                if let (x, y) = actorPosition(bumpedId, state: state) {
                    addBlip(x: x, y: y, glyph: "!", color: .orange, ttl: 0.25)
                }
            case .move:
                break
            }
        }
    }
    
    func finishBattle() {
        stopSimulation()
        
        if let run = gameState.currentRun, let picked = run.pickedTeam, let core = run.battleCore {
            let winner = Int(core.getWinner())
            run.wasCorrect = (winner == picked)
            run.battleFinished = true
            
            combatLog.append("")
            combatLog.append("===== BATTLE COMPLETE =====")
            combatLog.append(winner == 0 ? "🏆 Team A Wins!" : "🏆 Team B Wins!")
            combatLog.append("Your pick: Team \(picked == 0 ? "A" : "B")")
            combatLog.append(run.wasCorrect ? "✅ CORRECT!" : "❌ INCORRECT")
            combatLog.append("===========================")
            
            if run.wasCorrect {
                let points = run.calculateScore(isUnderdog: false)
                run.score += points
            } else {
                run.isActive = false
            }
            
            // Longer delay to view final state (3 seconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                gameState.navigationPath.append(NavigationDestination.roundResult)
            }
        }
    }
}

struct HitBlip: Identifiable {
    let id = UUID()
    let x: Int32
    let y: Int32
    let glyph: String
    let color: Color
    let expires: Date
}

struct BattleGridView: View {
    let battleState: BattleState
    let blips: [HitBlip]
    
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
                
                // Draw exactly one character per tile
                for y in 0..<gridHeight {
                    for x in 0..<gridWidth {
                        let key = y * gridWidth + x
                        let px = offsetX + CGFloat(x) * cellSize
                        let py = offsetY + CGFloat(y) * cellSize
                        
                        // Priority: Team A actor > Team B actor > Blip > Terrain
                        if let actor = teamAMap[key] {
                            if useTileset {
                                drawTile(context, char: actor.glyph, at: CGPoint(x: px, y: py), 
                                        size: cellSize, color: UIColor(DFColors.lgreen))
                            } else {
                                let text = Text(String(actor.glyph))
                                    .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                                    .foregroundColor(DFColors.lgreen)
                                context.draw(text, at: CGPoint(x: px + cellSize/2, y: py + cellSize/2))
                            }
                        } else if let actor = teamBMap[key] {
                            if useTileset {
                                drawTile(context, char: actor.glyph, at: CGPoint(x: px, y: py), 
                                        size: cellSize, color: UIColor(DFColors.lred))
                            } else {
                                let text = Text(String(actor.glyph))
                                    .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                                    .foregroundColor(DFColors.lred)
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
                            // Terrain background
                            let hash = (x * 73856093) ^ (y * 19349663)
                            let glyph = groundGlyphs[abs(hash) % groundGlyphs.count]
                            let jitter = Double((hash >> 3) & 0xF) / 255.0
                            let baseGreen = 0.32 + jitter * 0.1
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
    
    private func drawTile(_ context: GraphicsContext, char: Character, at point: CGPoint, size: CGFloat, color: UIColor) {
        let renderer = TilesetRenderer.shared
        let index = renderer.tileIndex(for: char)
        let scale = size / CGFloat(renderer.sourceTileWidth)
        
        if let tileImage = renderer.getTile(index: index, color: color, scale: scale) {
            let resolved = context.resolve(Image(uiImage: tileImage))
            context.draw(resolved, at: CGPoint(x: point.x + size/2, y: point.y + size/2))
        }
    }
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