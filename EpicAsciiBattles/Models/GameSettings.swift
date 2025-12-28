import Foundation
import Combine

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
        // Load from UserDefaults
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
    
    // How many gib particles spawn on sever
    var gibCount: Int {
        switch self {
        case .tame: return 1
        case .normal: return 3
        case .grotesque: return 6
        }
    }
    
    // TTL multiplier for particle effects
    var particleDuration: Double {
        switch self {
        case .tame: return 0.5
        case .normal: return 1.0
        case .grotesque: return 1.5
        }
    }
    
    // Blood stain probability
    var bloodStainChance: Double {
        switch self {
        case .tame: return 0.1
        case .normal: return 0.4
        case .grotesque: return 0.8
        }
    }
    
    // Blood tint opacity
    var tintOpacity: Double {
        switch self {
        case .tame: return 0.1
        case .normal: return 0.3
        case .grotesque: return 0.6
        }
    }
    
    // Should persistent marks fade over time
    var fadeMarks: Bool {
        switch self {
        case .tame: return true
        case .normal: return false
        case .grotesque: return false
        }
    }
}
