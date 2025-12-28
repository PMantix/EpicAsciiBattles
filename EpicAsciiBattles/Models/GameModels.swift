import Foundation
import Combine
import SwiftUI

/// Record of a completed run
struct RunRecord: Codable, Identifiable {
    let runId: UUID
    let timestamp: Date
    let totalTrophies: Int
    let roundReached: Int
    let seed: UInt64
    
    var id: UUID { runId }
}

/// Game settings persisted to UserDefaults
class GameSettings: ObservableObject {
    static let shared = GameSettings()
    
    @Published var goreIntensity: GoreIntensity {
        didSet {
            UserDefaults.standard.set(goreIntensity.rawValue, forKey: "goreIntensity")
        }
    }
    
    @Published var reducedMotion: Bool {
        didSet {
            UserDefaults.standard.set(reducedMotion, forKey: "reducedMotion")
        }
    }
    
    @Published var colorScheme: ColorScheme {
        didSet {
            UserDefaults.standard.set(colorScheme.rawValue, forKey: "colorScheme")
        }
    }
    
    private init() {
        let intensityRaw = UserDefaults.standard.string(forKey: "goreIntensity") ?? "grotesque"
        self.goreIntensity = GoreIntensity(rawValue: intensityRaw) ?? .grotesque
        self.reducedMotion = UserDefaults.standard.bool(forKey: "reducedMotion")
        let schemeRaw = UserDefaults.standard.string(forKey: "colorScheme") ?? "classic"
        self.colorScheme = ColorScheme(rawValue: schemeRaw) ?? .classic
    }
}

/// Color scheme options for the game
enum ColorScheme: String, CaseIterable, Identifiable {
    case classic = "classic"
    case amber = "amber"
    case green = "green"
    case ice = "ice"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .amber: return "Amber CRT"
        case .green: return "Green Terminal"
        case .ice: return "Ice"
        }
    }
    
    var description: String {
        switch self {
        case .classic: return "Full color palette"
        case .amber: return "Retro amber monitor"
        case .green: return "Classic terminal green"
        case .ice: return "Cool blue tones"
        }
    }
    
    var previewColors: [Color] {
        switch self {
        case .classic:
            return [DFColors.lred, DFColors.yellow, DFColors.lgreen, DFColors.lblue]
        case .amber:
            return [Color(red: 1.0, green: 0.6, blue: 0.0), 
                    Color(red: 1.0, green: 0.8, blue: 0.2),
                    Color(red: 0.8, green: 0.5, blue: 0.0),
                    Color(red: 0.5, green: 0.3, blue: 0.0)]
        case .green:
            return [Color(red: 0.0, green: 1.0, blue: 0.0),
                    Color(red: 0.0, green: 0.8, blue: 0.0),
                    Color(red: 0.0, green: 0.6, blue: 0.0),
                    Color(red: 0.0, green: 0.4, blue: 0.0)]
        case .ice:
            return [Color(red: 0.6, green: 0.9, blue: 1.0),
                    Color(red: 0.4, green: 0.7, blue: 1.0),
                    Color(red: 0.2, green: 0.5, blue: 0.9),
                    Color(red: 0.8, green: 0.95, blue: 1.0)]
        }
    }
}

enum GoreIntensity: String, CaseIterable, Identifiable {
    case tame = "tame"
    case normal = "normal"
    case grotesque = "grotesque"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .tame: return "Tame"
        case .normal: return "Normal"
        case .grotesque: return "Grotesque"
        }
    }
    
    var description: String {
        switch self {
        case .tame: return "Minimal blood and effects"
        case .normal: return "Moderate violence"
        case .grotesque: return "Maximum carnage"
        }
    }
    
    var gibCount: Int {
        switch self {
        case .tame: return 1
        case .normal: return 3
        case .grotesque: return 6
        }
    }
    
    var particleDuration: Double {
        switch self {
        case .tame: return 0.5
        case .normal: return 1.0
        case .grotesque: return 1.5
        }
    }
    
    var bloodStainChance: Double {
        switch self {
        case .tame: return 0.1
        case .normal: return 0.4
        case .grotesque: return 0.8
        }
    }
    
    var tintOpacity: Double {
        switch self {
        case .tame: return 0.1
        case .normal: return 0.3
        case .grotesque: return 0.6
        }
    }
    
    var fadeMarks: Bool {
        switch self {
        case .tame: return true
        case .normal: return false
        case .grotesque: return false
        }
    }
}
