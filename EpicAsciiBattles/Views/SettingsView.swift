import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Form {
                Section("Gore & Violence") {
                    Picker("Gore Intensity", selection: $gameState.settings.goreIntensity) {
                        ForEach(GoreIntensity.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                }
                
                Section("Combat Log") {
                    Picker("Verbosity", selection: $gameState.settings.combatLogVerbosity) {
                        ForEach(CombatLogVerbosity.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                }
                
                Section("Audio & Feedback") {
                    Toggle("Sound Effects", isOn: $gameState.settings.soundEnabled)
                    Toggle("Haptics", isOn: $gameState.settings.hapticsEnabled)
                }
                
                Section("Accessibility") {
                    Toggle("Reduce Motion", isOn: $gameState.settings.reduceMotion)
                }
            }
            .scrollContentBackground(.hidden)
            .foregroundColor(.white)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(GameState())
}
