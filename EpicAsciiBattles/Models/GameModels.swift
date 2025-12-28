import Foundation
import Combine

/// Record of a completed run
struct RunRecord: Codable, Identifiable {
    let runId: UUID
    let timestamp: Date
    let score: Int
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
    
    private init() {
        let intensityRaw = UserDefaults.standard.string(forKey: "goreIntensity") ?? "normal"
        self.goreIntensity = GoreIntensity(rawValue: intensityRaw) ?? .normal
        self.reducedMotion = UserDefaults.standard.bool(forKey: "reducedMotion")
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
