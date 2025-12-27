import SwiftUI

struct HomeView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        ZStack {
            // Background ASCII pattern
            ASCIIBackgroundView()
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Title
                Text("EPIC ASCII BATTLES")
                    .font(.system(.largeTitle, design: .monospaced, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 10)
                
                Spacer()
                
                // Main buttons
                VStack(spacing: 20) {
                    Button(action: {
                        gameState.startNewRun()
                    }) {
                        Text("Start Run")
                            .font(.system(.title2, design: .monospaced, weight: .semibold))
                            .frame(maxWidth: 300)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        gameState.navigationPath.append(NavigationDestination.leaderboard)
                    }) {
                        Text("Leaderboard")
                            .font(.system(.title3, design: .monospaced))
                            .frame(maxWidth: 300)
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        gameState.navigationPath.append(NavigationDestination.settings)
                    }) {
                        Text("Settings")
                            .font(.system(.title3, design: .monospaced))
                            .frame(maxWidth: 300)
                            .padding()
                            .background(Color.gray.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
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
    let characters = ["@", "#", "%", "&", "*", "+", "=", "-", ".", ":", "~"]
    let gridSize = 20
    
    var body: some View {
        GeometryReader { geometry in
            let cellWidth = geometry.size.width / CGFloat(gridSize)
            let cellHeight = geometry.size.height / CGFloat(gridSize)
            
            Canvas { context, size in
                for row in 0..<gridSize {
                    for col in 0..<gridSize {
                        let char = characters.randomElement() ?? "#"
                        let x = CGFloat(col) * cellWidth + cellWidth / 2
                        let y = CGFloat(row) * cellHeight + cellHeight / 2
                        
                        let text = Text(char)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(Color.gray.opacity(0.2))
                        
                        context.draw(text, at: CGPoint(x: x, y: y))
                    }
                }
            }
        }
        .background(Color.black)
    }
}

#Preview {
    HomeView()
        .environmentObject(GameState())
}
