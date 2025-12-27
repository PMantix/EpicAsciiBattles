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
                            Text("╔═══════════╗")
                                .font(.system(.title, design: .monospaced))
                                .foregroundColor(DFColors.lgreen)
                            Text("║  ✓  WIN!  ║")
                                .font(.system(.largeTitle, design: .monospaced, weight: .bold))
                                .foregroundColor(DFColors.lgreen)
                            Text("╚═══════════╝")
                                .font(.system(.title, design: .monospaced))
                                .foregroundColor(DFColors.lgreen)
                            
                            Text("+\(run.calculateScore(isUnderdog: false)) points")
                                .font(.system(.title, design: .monospaced, weight: .bold))
                                .foregroundColor(DFColors.yellow)
                                .padding(.top, 10)
                        }
                        .padding(30)
                        .background(DFColors.dgray.opacity(0.5))
                        .cornerRadius(15)
                    } else {
                        VStack(spacing: 20) {
                            Text("╔═══════════╗")
                                .font(.system(.title, design: .monospaced))
                                .foregroundColor(DFColors.lred)
                            Text("║  ✗ LOSS  ║")
                                .font(.system(.largeTitle, design: .monospaced, weight: .bold))
                                .foregroundColor(DFColors.lred)
                            Text("╚═══════════╝")
                                .font(.system(.title, design: .monospaced))
                                .foregroundColor(DFColors.lred)
                            
                            Text("Run Ended")
                                .font(.system(.title2, design: .monospaced))
                                .foregroundColor(DFColors.lgray)
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
                            HStack {
                                Text("▶")
                                    .font(.system(.title2, design: .monospaced))
                                Text("Next Round")
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
                    } else {
                        Button(action: {
                            gameState.navigationPath.append(NavigationDestination.runSummary)
                        }) {
                            HStack {
                                Text("☆")
                                    .font(.system(.title2, design: .monospaced))
                                Text("View Summary")
                                    .font(.system(.title2, design: .monospaced, weight: .semibold))
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
