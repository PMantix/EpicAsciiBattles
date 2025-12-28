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
                    TilesetTextView(text: "=======================", color: DFColors.yellow, size: 16)
                    
                    TilesetTextView(text: "EPIC ASCII BATTLES", color: DFColors.white, size: 20)
                    
                    TilesetTextView(text: "=======================", color: DFColors.yellow, size: 16)
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
                        HStack(spacing: 8) {
                            TilesetTextView(text: ">", color: DFColors.black, size: 18)
                            TilesetTextView(text: "Start", color: DFColors.black, size: 18)
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
                    
                    Button(action: {
                        gameState.navigationPath.append(NavigationDestination.leaderboard)
                    }) {
                        HStack(spacing: 8) {
                            TilesetTextView(text: "*", color: DFColors.yellow, size: 18)
                            TilesetTextView(text: "Leaderboard", color: DFColors.yellow, size: 16)
                        }
                        .frame(maxWidth: 300)
                        .padding()
                        .background(DFColors.dgray)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(DFColors.yellow.opacity(0.5), lineWidth: 1)
                        )
                    }
                    
                    Button(action: {
                        gameState.navigationPath.append(NavigationDestination.settings)
                    }) {
                        HStack(spacing: 8) {
                            TilesetTextView(text: "O", color: DFColors.lgray, size: 18)
                            TilesetTextView(text: "Settings", color: DFColors.lgray, size: 16)
                        }
                        .frame(maxWidth: 300)
                        .padding()
                        .background(DFColors.dgray)
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

/// Renders text using tileset glyphs instead of system fonts
struct TilesetTextView: View {
    let text: String
    let color: Color
    let size: CGFloat
    
    var body: some View {
        let renderer = TilesetRenderer.shared
        if renderer.isAvailable {
            HStack(spacing: 0) {
                ForEach(Array(text.enumerated()), id: \.offset) { _, char in
                    let index = renderer.tileIndex(for: char)
                    let scale = size / CGFloat(renderer.sourceTileWidth)
                    if let tileImage = renderer.getTile(index: index, color: UIColor(color), scale: scale) {
                        Image(uiImage: tileImage)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: size, height: size)
                    }
                }
            }
        } else {
            // Fallback to system font if tileset not loaded
            Text(text)
                .font(.system(size: size * 0.7, design: .monospaced))
                .foregroundColor(color)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(GameState())
}
