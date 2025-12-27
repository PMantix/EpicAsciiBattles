import SwiftUI

struct RunSummaryView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        ZStack {
            DFColors.black.ignoresSafeArea()
            
            if let run = gameState.currentRun {
                VStack(spacing: 30) {
                    Spacer()
                    
                    // ASCII art title
                    VStack(spacing: 5) {
                        Text("╔═══════════════════╗")
                            .font(.system(.title2, design: .monospaced))
                            .foregroundColor(DFColors.yellow)
                        Text("║   RUN COMPLETE   ║")
                            .font(.system(.title, design: .monospaced, weight: .bold))
                            .foregroundColor(DFColors.white)
                        Text("╚═══════════════════╝")
                            .font(.system(.title2, design: .monospaced))
                            .foregroundColor(DFColors.yellow)
                    }
                    .padding(.bottom, 20)
                    
                    // Score with ASCII decoration
                    VStack(spacing: 10) {
                        Text("☆ ☆ ☆")
                            .font(.system(.title, design: .monospaced))
                            .foregroundColor(DFColors.yellow)
                        
                        Text("\(run.score)")
                            .font(.system(size: 80, weight: .heavy, design: .monospaced))
                            .foregroundColor(DFColors.yellow)
                        
                        Text("FINAL SCORE")
                            .font(.system(.title3, design: .monospaced, weight: .bold))
                            .foregroundColor(DFColors.white)
                        
                        Text("☆ ☆ ☆")
                            .font(.system(.title, design: .monospaced))
                            .foregroundColor(DFColors.yellow)
                    }
                    .padding(30)
                    .background(DFColors.dgray.opacity(0.5))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(DFColors.yellow, lineWidth: 2)
                    )
                    
                    // Rounds
                    HStack(spacing: 10) {
                        Text("→")
                            .font(.system(.title2, design: .monospaced))
                            .foregroundColor(DFColors.lgreen)
                        Text("Rounds: \(run.round)")
                            .font(.system(.title2, design: .monospaced, weight: .semibold))
                            .foregroundColor(DFColors.white)
                        Text("←")
                            .font(.system(.title2, design: .monospaced))
                            .foregroundColor(DFColors.lgreen)
                    }
                    .padding()
                    .background(DFColors.dgray.opacity(0.3))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    // Return home button
                    Button(action: {
                        gameState.endRun()
                    }) {
                        HStack {
                            Text("⌂")
                                .font(.system(.title2, design: .monospaced))
                            Text("Back to Home")
                                .font(.system(.title2, design: .monospaced, weight: .semibold))
                        }
                        .frame(maxWidth: 300)
                        .padding()
                        .background(DFColors.lgreen)
                        .foregroundColor(DFColors.black)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(DFColors.white, lineWidth: 2)
                        )
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    RunSummaryView()
        .environmentObject({
            let state = GameState()
            state.startNewRun()
            state.currentRun?.score = 450
            state.currentRun?.round = 5
            return state
        }())
}
