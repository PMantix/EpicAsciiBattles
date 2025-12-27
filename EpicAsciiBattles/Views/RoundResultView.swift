import SwiftUI

struct RoundResultView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let run = gameState.currentRun {
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Result indicator
                    if run.wasCorrect {
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 100))
                                .foregroundColor(.green)
                            
                            Text("CORRECT!")
                                .font(.system(.largeTitle, design: .monospaced, weight: .bold))
                                .foregroundColor(.green)
                            
                            Text("+\(run.calculateScore(isUnderdog: false)) points")
                                .font(.system(.title, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 100))
                                .foregroundColor(.red)
                            
                            Text("INCORRECT")
                                .font(.system(.largeTitle, design: .monospaced, weight: .bold))
                                .foregroundColor(.red)
                            
                            Text("Run Ended")
                                .font(.system(.title, design: .monospaced))
                                .foregroundColor(.gray)
                        }
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
                            Text("Next Round")
                                .font(.system(.title2, design: .monospaced, weight: .semibold))
                                .frame(maxWidth: 300)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: {
                            gameState.navigationPath.append(NavigationDestination.runSummary)
                        }) {
                            Text("View Summary")
                                .font(.system(.title2, design: .monospaced, weight: .semibold))
                                .frame(maxWidth: 300)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
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
