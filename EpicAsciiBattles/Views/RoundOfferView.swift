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
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 6) {
                TilesetTextView(text: "Round \(run.round)", color: DFColors.white, size: 20)
                HStack(spacing: 4) {
                    TilesetTextView(text: "*", color: DFColors.yellow, size: 14)
                    TilesetTextView(text: "\(run.totalTrophies)", color: DFColors.yellow, size: 14)
                }
            }
            .padding(.top, 20)
            
            Spacer()
            
            // Trophy reward indicator
            TrophyIndicator(run: run)
            
            Spacer()
            
            // Adjustments remaining
            HStack(spacing: 8) {
                TilesetTextView(text: "Adjustments:", color: DFColors.lgray, size: 12)
                TilesetTextView(text: "\(run.adjustmentsRemaining)/\(run.maxAdjustments)", 
                               color: run.adjustmentsRemaining > 0 ? DFColors.lgreen : DFColors.lred, 
                               size: 14)
            }
            .padding(.bottom, 12)
            
            // Team A with adjustment controls
            TeamBalanceCard(
                name: run.teamACount == 1 ? run.teamAName : run.teamANamePlural,
                count: run.teamACount,
                originalCount: run.originalTeamACount,
                glyph: run.teamAGlyph,
                color: DFColors.named(run.teamAColorName),
                canAdjust: run.adjustmentsRemaining > 0,
                onIncrement: { adjustTeamA(delta: 1) },
                onDecrement: { adjustTeamA(delta: -1) }
            )
            
            TilesetTextView(text: "VS", color: DFColors.yellow, size: 18)
                .padding(.vertical, 8)
            
            // Team B with adjustment controls
            TeamBalanceCard(
                name: run.teamBCount == 1 ? run.teamBName : run.teamBNamePlural,
                count: run.teamBCount,
                originalCount: run.originalTeamBCount,
                glyph: run.teamBGlyph,
                color: DFColors.named(run.teamBColorName),
                canAdjust: run.adjustmentsRemaining > 0,
                onIncrement: { adjustTeamB(delta: 1) },
                onDecrement: { adjustTeamB(delta: -1) }
            )
            
            Spacer()
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
        guard newCount >= 1 && newCount <= 40 else { return }
        
        // Check if moving toward or away from original
        let currentDistance = abs(run.teamACount - run.originalTeamACount)
        let newDistance = abs(newCount - run.originalTeamACount)
        
        if newDistance > currentDistance {
            // Moving away from original - consume adjustment if available
            guard run.adjustmentsRemaining > 0 else { return }
            run.teamACount = newCount
            run.adjustmentsUsed += 1
        } else {
            // Moving toward original (undo) - free, refund adjustment
            run.teamACount = newCount
            if run.adjustmentsUsed > 0 {
                run.adjustmentsUsed -= 1
            }
        }
    }
    
    func adjustTeamB(delta: Int) {
        let newCount = run.teamBCount + delta
        guard newCount >= 1 && newCount <= 40 else { return }
        
        // Check if moving toward or away from original
        let currentDistance = abs(run.teamBCount - run.originalTeamBCount)
        let newDistance = abs(newCount - run.originalTeamBCount)
        
        if newDistance > currentDistance {
            // Moving away from original - consume adjustment if available
            guard run.adjustmentsRemaining > 0 else { return }
            run.teamBCount = newCount
            run.adjustmentsUsed += 1
        } else {
            // Moving toward original (undo) - free, refund adjustment
            run.teamBCount = newCount
            if run.adjustmentsUsed > 0 {
                run.adjustmentsUsed -= 1
            }
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
    
    // Use team A's glyph and color consistently (the "winning" survivors could be from either team)
    private var previewGlyph: Character {
        run.teamAGlyph
    }
    
    private var previewColor: Color {
        DFColors.named(run.teamAColorName)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Compact header
            TilesetTextView(text: "Remaining Combatants", color: DFColors.lgray, size: 14)
            
            // Four tiers with animated combatant counts (3-star to 0-star)
            HStack(spacing: 16) {
                // 3 stars - near annihilation (1 survivor from 10)
                RewardTierView(
                    stars: 3,
                    survivorCount: 1,
                    glyphA: run.teamAGlyph,
                    colorA: DFColors.named(run.teamAColorName),
                    glyphB: run.teamBGlyph,
                    colorB: DFColors.named(run.teamBColorName),
                    animationOffset: animationOffset
                )
                
                // 2 stars - very close (2 survivors from 10)
                RewardTierView(
                    stars: 2,
                    survivorCount: 2,
                    glyphA: run.teamAGlyph,
                    colorA: DFColors.named(run.teamAColorName),
                    glyphB: run.teamBGlyph,
                    colorB: DFColors.named(run.teamBColorName),
                    animationOffset: animationOffset
                )
                
                // 1 star - close enough (4 survivors from 10)
                RewardTierView(
                    stars: 1,
                    survivorCount: 4,
                    glyphA: run.teamAGlyph,
                    colorA: DFColors.named(run.teamAColorName),
                    glyphB: run.teamBGlyph,
                    colorB: DFColors.named(run.teamBColorName),
                    animationOffset: animationOffset
                )
                
                // 0 stars - blowout (6+ survivors)
                RewardTierView(
                    stars: 0,
                    survivorCount: 6,
                    glyphA: run.teamAGlyph,
                    colorA: DFColors.named(run.teamAColorName),
                    glyphB: run.teamBGlyph,
                    colorB: DFColors.named(run.teamBColorName),
                    animationOffset: animationOffset,
                    isBlowout: true
                )
            }
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

// Individual reward tier with animated survivors - alternates between team A and B glyphs
struct RewardTierView: View {
    let stars: Int
    let survivorCount: Int
    let glyphA: Character
    let colorA: Color
    let glyphB: Character
    let colorB: Color
    let animationOffset: CGFloat
    var isBlowout: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            // Stars (or X for blowout)
            HStack(spacing: 1) {
                if isBlowout {
                    TilesetTextView(text: "X", color: DFColors.lred, size: 16)
                } else {
                    ForEach(0..<3, id: \.self) { i in
                        TilesetTextView(text: "*", 
                                       color: i < stars ? DFColors.yellow : DFColors.dgray, 
                                       size: 16)
                    }
                }
            }
            
            // Animated survivors in a row - alternate between team A and B
            HStack(spacing: 2) {
                ForEach(0..<survivorCount, id: \.self) { i in
                    // Alternate glyphs for visual interest
                    let useTeamA = i % 2 == 0
                    AnimatedCombatantView(
                        glyph: useTeamA ? glyphA : glyphB,
                        color: useTeamA ? colorA : colorB,
                        offset: animationOffset,
                        delay: Double(i) * 0.15
                    )
                }
                // Show "+" for blowout to indicate "6 or more"
                if isBlowout {
                    TilesetTextView(text: "+", color: DFColors.lred, size: 14)
                }
            }
            .frame(height: 20)
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
                
                // Count and name inline with change indicator
                HStack(spacing: 4) {
                    TilesetTextView(text: "x\(count)", color: DFColors.white, size: 16)
                    TilesetTextView(text: name, color: color, size: 16)
                    
                    let delta = count - originalCount
                    if delta != 0 {
                        TilesetTextView(text: delta > 0 ? "(+\(delta))" : "(\(delta))", 
                                       color: delta > 0 ? DFColors.lgreen : DFColors.lred, 
                                       size: 12)
                    }
                }
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
