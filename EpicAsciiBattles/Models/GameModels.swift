import Foundation

/// Record of a completed run
struct RunRecord: Codable, Identifiable {
    let runId: UUID
    let timestamp: Date
    let score: Int
    let roundReached: Int
    let seed: UInt64
    
    var id: UUID { runId }
}

/// Game settings
struct GameSettings: Codable {
    var goreIntensity: GoreIntensity = .normal
    var combatLogVerbosity: CombatLogVerbosity = .normal
    var soundEnabled: Bool = true
    var hapticsEnabled: Bool = true
    var reduceMotion: Bool = false
}

enum GoreIntensity: String, Codable, CaseIterable {
    case tame = "Tame"
    case normal = "Normal"
    case grotesque = "Grotesque"
}

enum CombatLogVerbosity: String, Codable, CaseIterable {
    case brief = "Brief"
    case normal = "Normal"
    case verbose = "Verbose"
}
