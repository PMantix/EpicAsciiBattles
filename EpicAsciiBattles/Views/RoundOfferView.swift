import SwiftUI

struct RoundOfferView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        ZStack {
            DFColors.black.ignoresSafeArea()
            
            if let run = gameState.currentRun {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        TilesetTextView(text: "Round \(run.round)", color: DFColors.white, size: 20)
                        TilesetTextView(text: "Score: \(run.score)", color: DFColors.lgray, size: 14)
                    }
                    .padding(.top, 30)
                    
                    // Instructions
                    TilesetTextView(text: "Balance the fight!", color: DFColors.yellow, size: 16)
                    
                    // Trophy reward indicator
                    TrophyIndicator(run: run)
                    
                    // Team A with adjustment controls
                    TeamBalanceCard(
                        name: run.teamAName,
                        count: run.teamACount,
                        originalCount: run.originalTeamACount,
                        glyph: run.teamAGlyph,
                        color: DFColors.named(run.teamAColorName),
                        canAdjust: run.adjustmentsRemaining > 0,
                        onIncrement: { adjustTeamA(run: run, delta: 1) },
                        onDecrement: { adjustTeamA(run: run, delta: -1) }
                    )
                    
                    TilesetTextView(text: "VS", color: DFColors.yellow, size: 20)
                    
                    // Team B with adjustment controls
                    TeamBalanceCard(
                        name: run.teamBName,
                        count: run.teamBCount,
                        originalCount: run.originalTeamBCount,
                        glyph: run.teamBGlyph,
                        color: DFColors.named(run.teamBColorName),
                        canAdjust: run.adjustmentsRemaining > 0,
                        onIncrement: { adjustTeamB(run: run, delta: 1) },
                        onDecrement: { adjustTeamB(run: run, delta: -1) }
                    )
                    
                    // Adjustments remaining
                    HStack(spacing: 8) {
                        TilesetTextView(text: "Adjustments:", color: DFColors.lgray, size: 12)
                        TilesetTextView(text: "\(run.adjustmentsRemaining)/\(run.maxAdjustments)", 
                                       color: run.adjustmentsRemaining > 0 ? DFColors.lgreen : DFColors.lred, 
                                       size: 14)
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Fight button
                    Button(action: {
                        startBattle(run: run)
                    }) {
                        TilesetTextView(text: "[ FIGHT! ]", color: DFColors.black, size: 20)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 15)
                            .background(DFColors.lgreen)
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    func adjustTeamA(run: GameRun, delta: Int) {
        let newCount = run.teamACount + delta
        if newCount >= 1 && newCount <= 30 {
            run.teamACount = newCount
            run.adjustmentsUsed += 1
        }
    }
    
    func adjustTeamB(run: GameRun, delta: Int) {
        let newCount = run.teamBCount + delta
        if newCount >= 1 && newCount <= 30 {
            run.teamBCount = newCount
            run.adjustmentsUsed += 1
        }
    }
    
    func startBattle(run: GameRun) {
        // No team picking needed - just start the battle
        run.pickTeam(0) // Always "pick" team A to trigger battle init
        gameState.navigationPath.append(NavigationDestination.battle)
    }
}

// Trophy indicator showing potential rewards
struct TrophyIndicator: View {
    @ObservedObject var run: GameRun
    
    var body: some View {
        HStack(spacing: 8) {
            let tier = run.trophyTier
            let points = run.calculateScore(adjustmentsRemaining: run.adjustmentsRemaining)
            
            // Trophy icons
            ForEach(0..<3, id: \.self) { i in
                TilesetTextView(text: "*", 
                               color: i < tier ? DFColors.yellow : DFColors.dgray, 
                               size: 18)
            }
            
            TilesetTextView(text: "+\(points)", color: DFColors.yellow, size: 14)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(DFColors.dgray.opacity(0.3))
        .cornerRadius(8)
    }
}

// Team card with balance adjustment controls
struct TeamBalanceCard: View {
    let name: String
    let count: Int
    let originalCount: Int
    let glyph: Character
    let color: Color
    let canAdjust: Bool
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // Decrement button
            Button(action: onDecrement) {
                TilesetTextView(text: "<", color: canAdjust && count > 1 ? DFColors.white : DFColors.dgray, size: 24)
                    .frame(width: 44, height: 44)
                    .background(canAdjust && count > 1 ? DFColors.dgray : DFColors.black.opacity(0.3))
                    .cornerRadius(8)
            }
            .disabled(!canAdjust || count <= 1)
            
            // Team info
            VStack(spacing: 8) {
                // Combatant preview
                HStack(spacing: 4) {
                    ForEach(0..<min(count, 5), id: \.self) { _ in
                        CombatantTile(glyph: glyph, color: color)
                    }
                    if count > 5 {
                        TilesetTextView(text: "...", color: color, size: 14)
                    }
                }
                
                // Count with change indicator
                HStack(spacing: 4) {
                    TilesetTextView(text: "x\(count)", color: DFColors.white, size: 18)
                    
                    let delta = count - originalCount
                    if delta != 0 {
                        TilesetTextView(text: delta > 0 ? "+\(delta)" : "\(delta)", 
                                       color: delta > 0 ? DFColors.lgreen : DFColors.lred, 
                                       size: 14)
                    }
                }
                
                TilesetTextView(text: name, color: color, size: 14)
            }
            .frame(minWidth: 150)
            
            // Increment button
            Button(action: onIncrement) {
                TilesetTextView(text: ">", color: canAdjust && count < 30 ? DFColors.white : DFColors.dgray, size: 24)
                    .frame(width: 44, height: 44)
                    .background(canAdjust && count < 30 ? DFColors.dgray : DFColors.black.opacity(0.3))
                    .cornerRadius(8)
            }
            .disabled(!canAdjust || count >= 30)
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 20)
        .background(DFColors.dgray.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.4), lineWidth: 2)
        )
    }
}

struct TeamCard: View {
    let name: String
    let count: Int
    let glyph: Character
    let color: Color
    
    var body: some View {
        VStack(spacing: 15) {
            // Show individual combatants
            CombatantGrid(glyph: glyph, count: count, color: color)
            
            TilesetTextView(text: "x\(count) \(name)", color: DFColors.white, size: 18)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(DFColors.dgray.opacity(0.3))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(color.opacity(0.5), lineWidth: 2)
        )
    }
}

struct CombatantGrid: View {
    let glyph: Character
    let count: Int
    let color: Color
    
    var body: some View {
        let columns = min(count, 5)
        let rows = (count + columns - 1) / columns
        
        VStack(spacing: 4) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<columns, id: \.self) { col in
                        let index = row * columns + col
                        if index < count {
                            CombatantTile(glyph: glyph, color: color)
                        }
                    }
                }
            }
        }
    }
}

struct CombatantTile: View {
    let glyph: Character
    let color: Color
    
    var body: some View {
        ZStack {
            if TilesetRenderer.shared.isAvailable {
                TilesetImage(glyph: glyph, color: color, size: 32)
            } else {
                Text(String(glyph))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
            }
        }
        .background(DFColors.black.opacity(0.3))
        .cornerRadius(4)
    }
}

struct TilesetImage: View {
    let glyph: Character
    let color: Color
    let size: CGFloat
    
    var body: some View {
        let renderer = TilesetRenderer.shared
        let index = renderer.tileIndex(for: glyph)
        let scale = size / CGFloat(renderer.sourceTileWidth)
        
        if let tileImage = renderer.getTile(index: index, color: UIColor(color), scale: scale) {
            Image(uiImage: tileImage)
                .resizable()
                .frame(width: size, height: size)
        } else {
            Text(String(glyph))
                .font(.system(size: size * 0.7, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .frame(width: size, height: size)
        }
    }
}

#Preview {
    RoundOfferView()
        .environmentObject({
            let state = GameState()
            state.startNewRun()
            return state
        }())
}
