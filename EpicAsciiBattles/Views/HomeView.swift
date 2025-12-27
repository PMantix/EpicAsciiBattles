import SwiftUI

struct HomeView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        ZStack {
            // Background
            DFColors.black.ignoresSafeArea()
            
            // ASCII pattern background
            ASCIIBackgroundView()
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Title with ASCII border
                VStack(spacing: 10) {
                    Text("═══════════════════════")
                        .font(.system(.title3, design: .monospaced))
                        .foregroundColor(DFColors.yellow)
                    
                    Text("EPIC ASCII BATTLES")
                        .font(.system(.largeTitle, design: .monospaced, weight: .bold))
                        .foregroundColor(DFColors.white)
                    
                    Text("═══════════════════════")
                        .font(.system(.title3, design: .monospaced))
                        .foregroundColor(DFColors.yellow)
                }
                .padding()
                .background(DFColors.dgray.opacity(0.5))
                .cornerRadius(10)
                
                Spacer()
                
                // Main buttons with ASCII styling
                VStack(spacing: 20) {
                    Button(action: {
                        gameState.startNewRun()
                    }) {
                        HStack {
                            Text("▶")
                                .font(.system(.title2, design: .monospaced))
                            Text("Start Run")
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
                    
                    Button(action: {
                        gameState.navigationPath.append(NavigationDestination.leaderboard)
                    }) {
                        HStack {
                            Text("☆")
                                .font(.system(.title2, design: .monospaced))
                            Text("Leaderboard")
                                .font(.system(.title3, design: .monospaced))
                        }
                        .frame(maxWidth: 300)
                        .padding()
                        .background(DFColors.dgray)
                        .foregroundColor(DFColors.yellow)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(DFColors.yellow.opacity(0.5), lineWidth: 1)
                        )
                    }
                    
                    Button(action: {
                        gameState.navigationPath.append(NavigationDestination.settings)
                    }) {
                        HStack {
                            Text("⚙")
                                .font(.system(.title2, design: .monospaced))
                            Text("Settings")
                                .font(.system(.title3, design: .monospaced))
                        }
                        .frame(maxWidth: 300)
                        .padding()
                        .background(DFColors.dgray)
                        .foregroundColor(DFColors.lgray)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(DFColors.lgray.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationBarHidden(true)
    }
}

struct ASCIIBackgroundView: View {
    let characters = [".", "·", ":", "░", "▒"]
    let gridSize = 30
    
    var body: some View {
        GeometryReader { geometry in
            let cellWidth = geometry.size.width / CGFloat(gridSize)
            let cellHeight = geometry.size.height / CGFloat(gridSize)
            
            Canvas { context, size in
                for row in 0..<gridSize {
                    for col in 0..<gridSize {
                        let char = characters.randomElement() ?? "."
                        let x = CGFloat(col) * cellWidth + cellWidth / 2
                        let y = CGFloat(row) * cellHeight + cellHeight / 2
                        
                        let opacity = Double.random(in: 0.05...0.15)
                        let text = Text(char)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(DFColors.lgreen.opacity(opacity))
                        
                        context.draw(text, at: CGPoint(x: x, y: y))
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(GameState())
}
