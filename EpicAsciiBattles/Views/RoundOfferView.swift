import SwiftUI

struct RoundOfferView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let run = gameState.currentRun {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 10) {
                        Text("Round \(run.round)")
                            .font(.system(.title, design: .monospaced, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Score: \(run.score)")
                            .font(.system(.title3, design: .monospaced))
                            .foregroundColor(.gray)
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
                            color: .green
                        )
                        .onTapGesture {
                            selectTeam(0, run: run)
                        }
                        
                        Text("VS")
                            .font(.system(.title, design: .monospaced, weight: .heavy))
                            .foregroundColor(.red)
                        
                        // Team B
                        TeamCard(
                            name: run.teamBName,
                            count: run.teamBCount,
                            glyph: run.teamBGlyph,
                            color: .blue
                        )
                        .onTapGesture {
                            selectTeam(1, run: run)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    Text("Tap a team to choose your pick")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
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
            Text(String(glyph))
                .font(.system(size: 80, design: .monospaced))
                .foregroundColor(color)
            
            Text(name)
                .font(.system(.title2, design: .monospaced, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Count: \(count)")
                .font(.system(.title3, design: .monospaced))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(color.opacity(0.5), lineWidth: 2)
        )
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
