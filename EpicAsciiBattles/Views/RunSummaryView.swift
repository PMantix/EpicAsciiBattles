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
                        TilesetTextView(text: "===================", color: DFColors.yellow, size: 16)
                        TilesetTextView(text: "RUN COMPLETE", color: DFColors.white, size: 18)
                        TilesetTextView(text: "===================", color: DFColors.yellow, size: 16)
                    }
                    .padding(.bottom, 20)
                    
                    // Score with ASCII decoration
                    VStack(spacing: 10) {
                        TilesetTextView(text: "* * *", color: DFColors.yellow, size: 20)
                        
                        TilesetTextView(text: "\(run.score)", color: DFColors.yellow, size: 48)
                        
                        TilesetTextView(text: "FINAL SCORE", color: DFColors.white, size: 16)
                        
                        TilesetTextView(text: "* * *", color: DFColors.yellow, size: 20)
                    }
                    .padding(30)
                    .background(DFColors.dgray.opacity(0.5))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(DFColors.yellow, lineWidth: 2)
                    )
                    
                    // Battle Stats
                    VStack(spacing: 15) {
                        TilesetTextView(text: "=== BATTLE STATS ===", color: DFColors.yellow, size: 14)
                        
                        VStack(spacing: 8) {
                            HStack {
                                TilesetTextView(text: "Rounds Survived:", color: DFColors.lgray, size: 12)
                                Spacer()
                                TilesetTextView(text: "\(run.round)", color: DFColors.white, size: 12)
                            }
                            
                            HStack {
                                TilesetTextView(text: "Correct Picks:", color: DFColors.lgray, size: 12)
                                Spacer()
                                TilesetTextView(text: "\(run.round)", color: DFColors.lgreen, size: 12)
                            }
                        }
                        .padding()
                        .background(DFColors.dgray.opacity(0.3))
                        .cornerRadius(10)
                        
                        // Pile of corpses for fun
                        VStack(spacing: 0) {
                            TilesetTextView(text: "--- THE FALLEN ---", color: DFColors.red, size: 10)
                            TilesetTextView(text: "X X X X X X X X X X", color: DFColors.dgray, size: 12)
                            TilesetTextView(text: "X X X X X X X X X X", color: DFColors.dgray, size: 12)
                            TilesetTextView(text: "X X X X X X X X X X", color: DFColors.dgray, size: 12)
                        }
                        .padding(10)
                        .background(DFColors.black.opacity(0.5))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(DFColors.dgray.opacity(0.2))
                    .cornerRadius(15)
                    
                    Spacer()
                    
                    // Return home button
                    Button(action: {
                        gameState.endRun()
                    }) {
                        HStack(spacing: 8) {
                            TilesetTextView(text: "H", color: DFColors.black, size: 18)
                            TilesetTextView(text: "Back to Home", color: DFColors.black, size: 18)
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
