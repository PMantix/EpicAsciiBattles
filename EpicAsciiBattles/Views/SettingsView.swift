import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var gameState: GameState
    @ObservedObject private var settings = GameSettings.shared
    
    var body: some View {
        ZStack {
            DFColors.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // Header
                    VStack(spacing: 8) {
                        TilesetTextView(text: "Settings", color: DFColors.white, size: 24)
                        Rectangle()
                            .fill(DFColors.yellow)
                            .frame(height: 2)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Gore Intensity Setting
                    VStack(alignment: .leading, spacing: 15) {
                        TilesetTextView(text: "Gore Intensity", color: DFColors.yellow, size: 18)
                        
                        TilesetTextView(text: "Blood and VFX intensity", 
                                       color: DFColors.lgray, size: 12)
                            .padding(.bottom, 8)
                        
                        ForEach(GoreIntensity.allCases) { intensity in
                            Button(action: {
                                settings.goreIntensity = intensity
                            }) {
                                HStack {
                                    // Radio button
                                    ZStack {
                                        Circle()
                                            .stroke(DFColors.white, lineWidth: 2)
                                            .frame(width: 20, height: 20)
                                        
                                        if settings.goreIntensity == intensity {
                                            Circle()
                                                .fill(DFColors.lgreen)
                                                .frame(width: 12, height: 12)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        TilesetTextView(text: intensity.displayName, 
                                                       color: settings.goreIntensity == intensity ? DFColors.white : DFColors.lgray, 
                                                       size: 16)
                                        TilesetTextView(text: intensity.description, 
                                                       color: DFColors.lgray, 
                                                       size: 10)
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(
                                    settings.goreIntensity == intensity 
                                        ? DFColors.dgray.opacity(0.8) 
                                        : DFColors.dgray.opacity(0.3)
                                )
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Color Scheme Setting
                    VStack(alignment: .leading, spacing: 15) {
                        TilesetTextView(text: "Color Scheme", color: DFColors.yellow, size: 18)
                        
                        TilesetTextView(text: "Visual theme for the game", 
                                       color: DFColors.lgray, size: 12)
                            .padding(.bottom, 8)
                        
                        ForEach(ColorScheme.allCases) { scheme in
                            Button(action: {
                                settings.colorScheme = scheme
                            }) {
                                HStack {
                                    // Radio button
                                    ZStack {
                                        Circle()
                                            .stroke(DFColors.white, lineWidth: 2)
                                            .frame(width: 20, height: 20)
                                        
                                        if settings.colorScheme == scheme {
                                            Circle()
                                                .fill(DFColors.lgreen)
                                                .frame(width: 12, height: 12)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        TilesetTextView(text: scheme.displayName, 
                                                       color: settings.colorScheme == scheme ? DFColors.white : DFColors.lgray, 
                                                       size: 16)
                                        TilesetTextView(text: scheme.description, 
                                                       color: DFColors.lgray, 
                                                       size: 10)
                                    }
                                    
                                    Spacer()
                                    
                                    // Color preview swatch
                                    HStack(spacing: 2) {
                                        ForEach(scheme.previewColors, id: \.self) { color in
                                            Rectangle()
                                                .fill(color)
                                                .frame(width: 12, height: 20)
                                        }
                                    }
                                    .cornerRadius(4)
                                }
                                .padding()
                                .background(
                                    settings.colorScheme == scheme 
                                        ? DFColors.dgray.opacity(0.8) 
                                        : DFColors.dgray.opacity(0.3)
                                )
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                    
                    // Back button
                    Button(action: {
                        gameState.navigationPath.removeLast()
                    }) {
                        HStack(spacing: 8) {
                            TilesetTextView(text: "<", color: DFColors.yellow, size: 18)
                            TilesetTextView(text: "Back", color: DFColors.yellow, size: 16)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DFColors.dgray)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(DFColors.yellow.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(GameState())
    }
}
