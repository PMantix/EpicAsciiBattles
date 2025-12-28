import SwiftUI

struct RoundOfferView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        ZStack {
            DFColors.black.ignoresSafeArea()
            
            if let run = gameState.currentRun {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 10) {
                        TilesetTextView(text: "Round \(run.round)", color: DFColors.white, size: 20)
                        
                        TilesetTextView(text: "Score: \(run.score)", color: DFColors.lgray, size: 16)
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Matchup card
                    VStack(spacing: 40) {
                        // Team A
                        TeamCard(
                            name: run.teamAName,
                            count: run.teamACount,
                            glyph: run.teamAGlyph,
                            color: DFColors.named(run.teamAColorName)
                        )
                        .onTapGesture {
                            selectTeam(0, run: run)
                        }
                        
                        TilesetTextView(text: "VS", color: DFColors.yellow, size: 24)
                        
                        // Team B
                        TeamCard(
                            name: run.teamBName,
                            count: run.teamBCount,
                            glyph: run.teamBGlyph,
                            color: DFColors.named(run.teamBColorName)
                        )
                        .onTapGesture {
                            selectTeam(1, run: run)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    TilesetTextView(text: "Tap a team to choose your pick", color: DFColors.lgray, size: 12)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    func selectTeam(_ team: Int, run: GameRun) {
        run.pickTeam(team)
        gameState.navigationPath.append(NavigationDestination.battle)
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
