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
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                if let run = gameState.currentRun {
                    HStack {
                        Text("Round \(run.round)")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if let state = battleState {
                            Text("Team A: \(state.teamA.count) | Team B: \(state.teamB.count)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                        } else {
                            Text("Team A: \(run.teamACount) | Team B: \(run.teamBCount)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.3))
                }
                
                // Battle grid
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                    
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
                            .foregroundColor(.white)
                        
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
                        .background(Color.black.opacity(0.9))
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
                .background(Color.gray.opacity(0.3))
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
                    
                    // Print actor positions
                    for actor in state.teamA {
                        print("     Team A Actor \(actor.id): '\(actor.glyph)' at (\(actor.x), \(actor.y))")
                    }
                    for actor in state.teamB {
                        print("     Team B Actor \(actor.id): '\(actor.glyph)' at (\(actor.x), \(actor.y))")
                    }
                } else {
                    print("   ⚠️ Failed to get initial state")
                }
            }
            // Don't auto-start - user will click Step or Auto
        }
        .onDisappear {
            stopSimulation()
        }
    }
    
    func startSimulation() {
        guard let run = gameState.currentRun else { return }
        
        isSimulating = true
        // Slower tick rate for better visibility (2 ticks per second)
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
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
        GeometryReader { _ in
            Canvas { context, size in
                let cellWidth = size.width / CGFloat(battleState.grid.width)
                let cellHeight = size.height / CGFloat(battleState.grid.height)
                let groundGlyphs: [Character] = ["`", ".", ",", "'", "\\"]
                let now = Date()
                
                // Background terrain to show grid cadence
                for y in 0..<Int(battleState.grid.height) {
                    for x in 0..<Int(battleState.grid.width) {
                        let hash = (x * 73856093) ^ (y * 19349663)
                        let glyph = groundGlyphs[abs(hash) % groundGlyphs.count]
                        let jitter = Double((hash >> 3) & 0xF) / 255.0
                        let baseGreen = 0.32 + jitter * 0.1
                        let baseRed = 0.18 + jitter * 0.05
                        let baseBlue = 0.18
                        let text = Text(String(glyph))
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(Color(red: baseRed, green: baseGreen, blue: baseBlue).opacity(0.75))
                        let px = CGFloat(x) * cellWidth + cellWidth / 2
                        let py = CGFloat(y) * cellHeight + cellHeight / 2
                        context.draw(text, at: CGPoint(x: px, y: py))
                    }
                }
                
                // Draw team A actors
                for actor in battleState.teamA where actor.isAlive {
                    let x = CGFloat(actor.x) * cellWidth + cellWidth / 2
                    let y = CGFloat(actor.y) * cellHeight + cellHeight / 2
                    let text = Text(String(actor.glyph))
                        .font(.system(size: 22, design: .monospaced))
                        .foregroundColor(.green)
                    context.draw(text, at: CGPoint(x: x, y: y))
                }
                
                // Draw team B actors
                for actor in battleState.teamB where actor.isAlive {
                    let x = CGFloat(actor.x) * cellWidth + cellWidth / 2
                    let y = CGFloat(actor.y) * cellHeight + cellHeight / 2
                    let text = Text(String(actor.glyph))
                        .font(.system(size: 22, design: .monospaced))
                        .foregroundColor(.red)
                    context.draw(text, at: CGPoint(x: x, y: y))
                }
                
                // Draw transient hit/gib blips
                for blip in blips where blip.expires > now {
                    let x = CGFloat(blip.x) * cellWidth + cellWidth / 2
                    let y = CGFloat(blip.y) * cellHeight + cellHeight / 2
                    let text = Text(blip.glyph)
                        .font(.system(size: 20, design: .monospaced))
                        .foregroundColor(blip.color)
                    context.draw(text, at: CGPoint(x: x, y: y))
                }
            }
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
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        isShowing = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
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
                    .background(Color.black.opacity(0.9))
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