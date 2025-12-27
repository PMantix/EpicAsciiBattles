import Foundation

/// Generates descriptive names for combatants
struct NameGenerator {
    
    // Adjectives based on stats/conditions
    private static let sizeAdjectives = ["Tiny", "Small", "Little", "Large", "Big", "Huge", "Massive"]
    private static let conditionAdjectives = ["Healthy", "Robust", "Sturdy", "Frail", "Weak", "Sickly"]
    private static let moodAdjectives = ["Calm", "Fierce", "Angry", "Frazzled", "Nervous", "Bold", "Brave", "Timid"]
    private static let physicalAdjectives = ["Scarred", "Battered", "Injured", "Maimed", "Pristine", "Sleek", "Grizzled"]
    private static let colorAdjectives = ["Dark", "Pale", "Spotted", "Striped", "Mottled"]
    private static let quirkyAdjectives = ["Old", "Young", "Fat", "Lean", "Scruffy", "Mangy", "Feisty", "Lazy", "Quick", "Slow"]
    
    /// Generate a descriptive name for an actor
    static func generateName(speciesName: String, hp: Int, maxHp: Int, morale: Int, actorId: UInt32) -> String {
        // Use actor ID as seed for consistent naming
        var rng = SeededRNG(seed: UInt64(actorId) * 31337)
        
        // Determine health condition
        let healthPercent = Double(hp) / Double(max(maxHp, 1))
        
        var adjective: String
        
        if healthPercent < 0.3 {
            // Badly hurt
            adjective = ["Injured", "Maimed", "Battered", "Wounded", "Bleeding"].randomElement(using: &rng) ?? "Injured"
        } else if healthPercent < 0.6 {
            // Somewhat hurt
            adjective = ["Scarred", "Worn", "Tired", "Weary"].randomElement(using: &rng) ?? "Scarred"
        } else if morale < 50 {
            // Low morale
            adjective = ["Nervous", "Timid", "Frightened", "Panicked"].randomElement(using: &rng) ?? "Nervous"
        } else if morale > 90 {
            // High morale
            adjective = ["Fierce", "Bold", "Brave", "Ferocious"].randomElement(using: &rng) ?? "Fierce"
        } else {
            // Normal - use quirky/physical adjectives based on ID
            let allAdjectives = sizeAdjectives + moodAdjectives + quirkyAdjectives + colorAdjectives
            adjective = allAdjectives.randomElement(using: &rng) ?? "Small"
        }
        
        // Capitalize species name
        let capitalizedSpecies = speciesName.prefix(1).uppercased() + speciesName.dropFirst().lowercased()
        
        return "\(adjective) \(capitalizedSpecies)"
    }
    
    /// Get a simple name without condition checks (for initial display)
    static func generateInitialName(speciesName: String, actorId: UInt32) -> String {
        var rng = SeededRNG(seed: UInt64(actorId) * 31337)
        
        let allAdjectives = sizeAdjectives + moodAdjectives + quirkyAdjectives + colorAdjectives
        let adjective = allAdjectives.randomElement(using: &rng) ?? "Small"
        let capitalizedSpecies = speciesName.prefix(1).uppercased() + speciesName.dropFirst().lowercased()
        
        return "\(adjective) \(capitalizedSpecies)"
    }
}

/// Simple seeded random number generator for consistent naming
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        state = seed
    }
    
    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
