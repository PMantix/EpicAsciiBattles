import SwiftUI

struct RunSummaryView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let run = gameState.currentRun {
                VStack(spacing: 30) {
                    Spacer()
                    
                    Text("RUN COMPLETE")
                        .font(.system(.largeTitle, design: .monospaced, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Score
                    VStack(spacing: 10) {
                        Text("\(run.score)")
                            .font(.system(size: 80, design: .monospaced, weight: .heavy))
                            .foregroundColor(.yellow)
                        
                        Text("Final Score")
                            .font(.system(.title3, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    
                    // Rounds
                    Text("Rounds Reached: \(run.round)")
                        .font(.system(.title2, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Return home button
                    Button(action: {
                        gameState.endRun()
                    }) {
                        Text("Back to Home")
                            .font(.system(.title2, design: .monospaced, weight: .semibold))
                            .frame(maxWidth: 300)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.black)
                            .cornerRadius(10)
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
