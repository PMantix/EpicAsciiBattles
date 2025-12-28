import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var gameState: GameState
    @StateObject private var settings = GameSettings.shared
    
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
                        
                        TilesetTextView(text: "Controls blood, gibs, and VFX intensity", 
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
                                                       size: 11)
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
                    
                    // Accessibility Settings
                    VStack(alignment: .leading, spacing: 15) {
                        TilesetTextView(text: "Accessibility", color: DFColors.yellow, size: 18)
                        
                        Toggle(isOn: $settings.reducedMotion) {
                            VStack(alignment: .leading, spacing: 4) {
                                TilesetTextView(text: "Reduced Motion", color: DFColors.white, size: 16)
                                TilesetTextView(text: "Shorter particle effects and animations", 
                                               color: DFColors.lgray, size: 11)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: DFColors.lgreen))
                        .padding()
                        .background(DFColors.dgray.opacity(0.3))
                        .cornerRadius(8)
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
