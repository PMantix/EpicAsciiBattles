import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                Text("LEADERBOARD")
                    .font(.system(.largeTitle, design: .monospaced, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
                
                // Leaderboard list
                let runs = gameState.getLeaderboard()
                
                if runs.isEmpty {
                    VStack(spacing: 20) {
                        Text("No runs yet")
                            .font(.system(.title2, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        Text("Complete a run to see it here!")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(Array(runs.enumerated()), id: \.element.id) { index, run in
                                LeaderboardRow(rank: index + 1, run: run)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let run: RunRecord
    
    var body: some View {
        HStack {
            // Rank
            Text("#\(rank)")
                .font(.system(.title3, design: .monospaced, weight: .bold))
                .foregroundColor(rankColor)
                .frame(width: 50, alignment: .leading)
            
            // Score
            Text("\(run.score)")
                .font(.system(.title3, design: .monospaced, weight: .semibold))
                .foregroundColor(.yellow)
                .frame(width: 80, alignment: .trailing)
            
            Spacer()
            
            // Rounds
            Text("R\(run.roundReached)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray)
            
            // Date
            Text(formatDate(run.timestamp))
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray.opacity(0.7))
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
    
    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .white
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

#Preview {
    LeaderboardView()
        .environmentObject(GameState())
}
