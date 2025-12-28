import SwiftUI

struct RoundOfferView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        ZStack {
            DFColors.black.ignoresSafeArea()
            
            if let run = gameState.currentRun {
                RoundOfferContent(run: run, gameState: gameState)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// Separate view that observes the run directly
struct RoundOfferContent: View {
    @ObservedObject var run: GameRun
    var gameState: GameState
    
    var body: some View {
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
                onIncrement: { adjustTeamA(delta: 1) },
                onDecrement: { adjustTeamA(delta: -1) }
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
                onIncrement: { adjustTeamB(delta: 1) },
                onDecrement: { adjustTeamB(delta: -1) }
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
                startBattle()
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
    
    func adjustTeamA(delta: Int) {
        let newCount = run.teamACount + delta
        if newCount >= 1 && newCount <= 40 && run.adjustmentsRemaining > 0 {
            run.teamACount = newCount
            run.adjustmentsUsed += 1
        }
    }
    
    func adjustTeamB(delta: Int) {
        let newCount = run.teamBCount + delta
        if newCount >= 1 && newCount <= 40 && run.adjustmentsRemaining > 0 {
            run.teamBCount = newCount
            run.adjustmentsUsed += 1
        }
    }
    
    func startBattle() {
        run.pickTeam(0)
        gameState.navigationPath.append(NavigationDestination.battle)
    }
}

// Trophy indicator showing potential rewards with animated combatant preview
struct TrophyIndicator: View {
    @ObservedObject var run: GameRun
    @State private var animationOffset: CGFloat = 0
    
    // Pick a random glyph for the preview
    private var previewGlyph: Character {
        [run.teamAGlyph, run.teamBGlyph].randomElement() ?? "c"
    }
    
    private var previewColor: Color {
        DFColors.named([run.teamAColorName, run.teamBColorName].randomElement() ?? "white")
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Compact header
            TilesetTextView(text: "Closer = Better!", color: DFColors.yellow, size: 14)
            
            // Three tiers with animated combatant counts
            HStack(spacing: 20) {
                // 3 stars - near annihilation (1-2 survivors from 10)
                RewardTierView(
                    stars: 3,
                    survivorCount: 1,
                    totalCount: 10,
                    glyph: previewGlyph,
                    color: previewColor,
                    points: run.calculateScore(survivorCount: 5, totalStartCount: 100),
                    animationOffset: animationOffset
                )
                
                // 2 stars - very close (2-3 survivors from 10)
                RewardTierView(
                    stars: 2,
                    survivorCount: 2,
                    totalCount: 10,
                    glyph: previewGlyph,
                    color: previewColor,
                    points: run.calculateScore(survivorCount: 20, totalStartCount: 100),
                    animationOffset: animationOffset
                )
                
                // 1 star - close enough (4-5 survivors from 10)
                RewardTierView(
                    stars: 1,
                    survivorCount: 4,
                    totalCount: 10,
                    glyph: previewGlyph,
                    color: previewColor,
                    points: run.calculateScore(survivorCount: 40, totalStartCount: 100),
                    animationOffset: animationOffset
                )
            }
            
            // Blowout warning
            TilesetTextView(text: "6+ left = BLOWOUT!", color: DFColors.lred, size: 12)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(DFColors.dgray.opacity(0.3))
        .cornerRadius(8)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                animationOffset = 4
            }
        }
    }
}

// Individual reward tier with animated survivors
struct RewardTierView: View {
    let stars: Int
    let survivorCount: Int
    let totalCount: Int
    let glyph: Character
    let color: Color
    let points: Int
    let animationOffset: CGFloat
    
    var body: some View {
        VStack(spacing: 4) {
            // Stars
            HStack(spacing: 1) {
                ForEach(0..<3, id: \.self) { i in
                    TilesetTextView(text: "*", 
                                   color: i < stars ? DFColors.yellow : DFColors.dgray, 
                                   size: 16)
                }
            }
            
            // Animated survivors in a row
            HStack(spacing: 2) {
                ForEach(0..<survivorCount, id: \.self) { i in
                    AnimatedCombatantView(
                        glyph: glyph,
                        color: color,
                        offset: animationOffset,
                        delay: Double(i) * 0.15
                    )
                }
            }
            .frame(height: 20)
            
            // Points
            TilesetTextView(text: "+\(points)", color: DFColors.yellow, size: 12)
        }
    }
}

// Single animated combatant that moves horizontally
struct AnimatedCombatantView: View {
    let glyph: Character
    let color: Color
    let offset: CGFloat
    let delay: Double
    
    @State private var localOffset: CGFloat = 0
    
    var body: some View {
        TilesetTextView(text: String(glyph), color: color, size: 14)
            .offset(x: localOffset)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        localOffset = CGFloat.random(in: -3...3)
                    }
                }
            }
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
