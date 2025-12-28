import SwiftUI

struct RoundResultView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        ZStack {
            DFColors.black.ignoresSafeArea()
            
            if let run = gameState.currentRun {
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Result indicator with ASCII art
                    if run.wasCorrect {
                        VStack(spacing: 20) {
                            TilesetTextView(text: "=============", color: DFColors.lgreen, size: 18)
                            TilesetTextView(text: "# WIN! #", color: DFColors.lgreen, size: 24)
                            TilesetTextView(text: "=============", color: DFColors.lgreen, size: 18)
                            
                            // Show trophies earned
                            HStack(spacing: 4) {
                                TilesetTextView(text: "*", color: DFColors.yellow, size: 18)
                                TilesetTextView(text: "Trophies earned!", color: DFColors.yellow, size: 18)
                            }
                            .padding(.top, 10)
                        }
                        .padding(30)
                        .background(DFColors.dgray.opacity(0.5))
                        .cornerRadius(15)
                    } else {
                        VStack(spacing: 20) {
                            TilesetTextView(text: "=============", color: DFColors.lred, size: 18)
                            TilesetTextView(text: "# LOSS #", color: DFColors.lred, size: 24)
                            TilesetTextView(text: "=============", color: DFColors.lred, size: 18)
                            
                            TilesetTextView(text: "Run Ended", color: DFColors.lgray, size: 16)
                                .padding(.top, 10)
                        }
                        .padding(30)
                        .background(DFColors.dgray.opacity(0.5))
                        .cornerRadius(15)
                    }
                    
                    Spacer()
                    
                    // Continue button
                    if run.wasCorrect {
                        Button(action: {
                            // Reset battle state
                            run.pickedTeam = nil
                            run.battleCore = nil
                            run.battleFinished = false
                            run.wasCorrect = false
                            
                            // Generate next matchup
                            run.generateNextMatchup()
                            
                            // Navigate back to round offer (remove both result and battle views)
                            gameState.navigationPath.removeLast(2)
                        }) {
                            HStack(spacing: 8) {
                                TilesetTextView(text: ">", color: DFColors.black, size: 18)
                                TilesetTextView(text: "Next Round", color: DFColors.black, size: 18)
                            }
                            .frame(maxWidth: 300)
                            .padding()
                            .background(DFColors.lgreen)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(DFColors.white, lineWidth: 2)
                            )
                        }
                    } else {
                        Button(action: {
                            gameState.navigationPath.append(NavigationDestination.runSummary)
                        }) {
                            HStack(spacing: 8) {
                                TilesetTextView(text: "*", color: DFColors.black, size: 18)
                                TilesetTextView(text: "View Summary", color: DFColors.black, size: 18)
                            }
                            .frame(maxWidth: 300)
                            .padding()
                            .background(DFColors.lblue)
                            .foregroundColor(DFColors.black)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(DFColors.white, lineWidth: 2)
                            )
                        }
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
    RoundResultView()
        .environmentObject({
            let state = GameState()
            state.startNewRun()
            state.currentRun?.wasCorrect = true
            return state
        }())
}
