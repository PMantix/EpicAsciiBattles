import SwiftUI

struct RunSummaryView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        ZStack {
            DFColors.black.ignoresSafeArea()
            
            if let run = gameState.currentRun {
                VStack(spacing: 20) {
                    // ASCII art title
                    VStack(spacing: 5) {
                        TilesetTextView(text: "===================", color: DFColors.yellow, size: 16)
                        TilesetTextView(text: "RUN COMPLETE", color: DFColors.white, size: 18)
                        TilesetTextView(text: "===================", color: DFColors.yellow, size: 16)
                    }
                    .padding(.top, 20)
                    
                    // Total trophies display
                    HStack(spacing: 8) {
                        TilesetTextView(text: "*", color: DFColors.yellow, size: 32)
                        TilesetTextView(text: "\(run.totalTrophies)", color: DFColors.yellow, size: 40)
                        TilesetTextView(text: "*", color: DFColors.yellow, size: 32)
                    }
                    .padding(.vertical, 10)
                    
                    TilesetTextView(text: "TOTAL TROPHIES", color: DFColors.white, size: 14)
                    
                    // Battle History header
                    TilesetTextView(text: "=== BATTLE HISTORY ===", color: DFColors.yellow, size: 14)
                        .padding(.top, 10)
                    
                    // Scrollable battle history
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(run.battleHistory, id: \.round) { entry in
                                BattleHistoryRow(entry: entry)
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                    .frame(maxHeight: 300)
                    .background(DFColors.dgray.opacity(0.2))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    // Return home button
                    Button(action: {
                        gameState.endRun()
                    }) {
                        HStack(spacing: 8) {
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
                    .padding(.bottom, 20)
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

/// A row showing one battle in history: winner vs loser with trophies
struct BattleHistoryRow: View {
    let entry: BattleHistoryEntry
    
    var body: some View {
        HStack(spacing: 8) {
            // Round number
            TilesetTextView(text: "\(entry.round).", color: DFColors.lgray, size: 12)
                .frame(width: 24, alignment: .leading)
            
            // Winner side (alive combatants)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    TilesetTextView(text: String(entry.winnerGlyph), 
                                   color: DFColors.named(entry.winnerColor), 
                                   size: 14)
                }
            }
            
            TilesetTextView(text: "vs", color: DFColors.dgray, size: 10)
            
            // Loser side (dead combatants - X's in loser color)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    TilesetTextView(text: "X", 
                                   color: DFColors.named(entry.loserColor).opacity(0.5), 
                                   size: 14)
                }
            }
            
            Spacer()
            
            // Trophies earned
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { i in
                    TilesetTextView(text: "*", 
                                   color: i < entry.trophies ? DFColors.yellow : DFColors.dgray, 
                                   size: 14)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(DFColors.dgray.opacity(0.3))
        .cornerRadius(6)
    }
}

#Preview {
    RunSummaryView()
        .environmentObject({
            let state = GameState()
            state.startNewRun()
            state.currentRun?.totalTrophies = 7
            state.currentRun?.round = 4
            // Add some sample battle history
            state.currentRun?.battleHistory = [
                BattleHistoryEntry(round: 1, winnerGlyph: "G", winnerColor: "lgreen", winnerName: "Goblins",
                                  loserGlyph: "O", loserColor: "lred", loserName: "Orcs", trophies: 2),
                BattleHistoryEntry(round: 2, winnerGlyph: "G", winnerColor: "lgreen", winnerName: "Goblins",
                                  loserGlyph: "S", loserColor: "lblue", loserName: "Skeletons", trophies: 3),
                BattleHistoryEntry(round: 3, winnerGlyph: "G", winnerColor: "lgreen", winnerName: "Goblins",
                                  loserGlyph: "D", loserColor: "magenta", loserName: "Demons", trophies: 2),
                BattleHistoryEntry(round: 4, winnerGlyph: "Z", winnerColor: "dgray", winnerName: "Zombies",
                                  loserGlyph: "G", loserColor: "lgreen", loserName: "Goblins", trophies: 0),
            ]
            return state
        }())
}
