import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        NavigationStack(path: $gameState.navigationPath) {
            HomeView()
                .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                    case .roundOffer:
                        RoundOfferView()
                    case .battle:
                        BattleView()
                    case .roundResult:
                        RoundResultView()
                    case .runSummary:
                        RunSummaryView()
                    case .leaderboard:
                        LeaderboardView()
                    case .settings:
                        SettingsView()
                    }
                }
        }
    }
}

enum NavigationDestination: Hashable {
    case roundOffer
    case battle
    case roundResult
    case runSummary
    case leaderboard
    case settings
}

#Preview {
    ContentView()
        .environmentObject(GameState())
}
