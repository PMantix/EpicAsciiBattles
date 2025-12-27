import SwiftUI

struct BattleView: View {
    @EnvironmentObject var gameState: GameState
    @State private var showingLog = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                if let run = gameState.currentRun {
                    HStack {
                        Text("Round \(run.round)")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Team A: \(run.teamACount) | Team B: \(run.teamBCount)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.3))
                }
                
                // Battle grid (placeholder for Phase 1)
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                    
                    Text("[Battle Simulation View]")
                        .font(.system(.title, design: .monospaced))
                        .foregroundColor(.green.opacity(0.5))
                }
                
                // Bottom controls
                HStack {
                    Button(action: {
                        showingLog.toggle()
                    }) {
                        Label("Combat Log", systemImage: "text.alignleft")
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Placeholder: end battle
                        endBattle()
                    }) {
                        Text("End Battle (Debug)")
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .background(Color.red.opacity(0.3))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.3))
            }
            
            // Combat log overlay
            if showingLog {
                CombatLogView(isShowing: $showingLog)
                    .transition(.move(edge: .bottom))
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    func endBattle() {
        // Placeholder: randomly determine outcome for now
        if let run = gameState.currentRun, let picked = run.pickedTeam {
            let winner = Int.random(in: 0...1)
            run.wasCorrect = (winner == picked)
            run.battleFinished = true
            
            if run.wasCorrect {
                let points = run.calculateScore(isUnderdog: false)
                run.score += points
            } else {
                run.isActive = false
            }
            
            gameState.navigationPath.append(NavigationDestination.roundResult)
        }
    }
}

struct CombatLogView: View {
    @Binding var isShowing: Bool
    @State private var logEntries: [String] = [
        "Battle begins!",
        "Chicken pecks at baboon's face!",
        "Baboon scratches chicken's wing!",
        "The chicken is bleeding.",
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("Combat Log")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        isShowing = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.5))
                
                // Log content
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(logEntries, id: \.self) { entry in
                            Text(entry)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                }
                .frame(height: 300)
                .background(Color.black.opacity(0.9))
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    BattleView()
        .environmentObject({
            let state = GameState()
            state.startNewRun()
            return state
        }())
}
