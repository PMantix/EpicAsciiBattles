import Foundation

/// Battle event from simulation
enum BattleEvent: Codable {
    case move(actorId: UInt32, fromX: Int32, fromY: Int32, toX: Int32, toY: Int32)
    case hit(attackerId: UInt32, defenderId: UInt32, partId: String, damage: UInt32, attackName: String)
    case bleed(actorId: UInt32, amount: UInt32)
    case sever(actorId: UInt32, partId: String, gibChar: Character, x: Int32, y: Int32)
    case death(actorId: UInt32, x: Int32, y: Int32)
    case vomit(actorId: UInt32, amount: UInt32, x: Int32, y: Int32)
    case statusChange(actorId: UInt32, status: String, active: Bool)
    case bump(bumperId: UInt32, bumpedId: UInt32, toX: Int32, toY: Int32)
    
    enum CodingKeys: String, CodingKey {
        case type
        case actorId, actor_id, fromX, fromY, toX, toY, from_x, from_y, to_x, to_y
        case attackerId, attacker_id, defenderId, defender_id, partId, part_id, damage, attackName, attack_name
        case amount, gibChar, gib_char, x, y
        case status, active
        case bumperId, bumper_id, bumpedId, bumped_id
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        // Helpers to decode snake_case or camelCase
        func decodeU32(_ primary: CodingKeys, alt: CodingKeys? = nil) throws -> UInt32 {
            if let value = try container.decodeIfPresent(UInt32.self, forKey: primary) {
                return value
            }
            if let alt = alt, let value = try container.decodeIfPresent(UInt32.self, forKey: alt) {
                return value
            }
            throw DecodingError.keyNotFound(primary, .init(codingPath: container.codingPath, debugDescription: "Missing key \(primary.rawValue)"))
        }
        func decodeI32(_ primary: CodingKeys, alt: CodingKeys? = nil) throws -> Int32 {
            if let value = try container.decodeIfPresent(Int32.self, forKey: primary) {
                return value
            }
            if let alt = alt, let value = try container.decodeIfPresent(Int32.self, forKey: alt) {
                return value
            }
            throw DecodingError.keyNotFound(primary, .init(codingPath: container.codingPath, debugDescription: "Missing key \(primary.rawValue)"))
        }
        func decodeString(_ primary: CodingKeys, alt: CodingKeys? = nil) throws -> String {
            if let value = try container.decodeIfPresent(String.self, forKey: primary) {
                return value
            }
            if let alt = alt, let value = try container.decodeIfPresent(String.self, forKey: alt) {
                return value
            }
            throw DecodingError.keyNotFound(primary, .init(codingPath: container.codingPath, debugDescription: "Missing key \(primary.rawValue)"))
        }
        
        switch type {
        case "Move", "move":
            let actorId = try decodeU32(.actorId, alt: .actor_id)
            let fromX = try decodeI32(.fromX, alt: .from_x)
            let fromY = try decodeI32(.fromY, alt: .from_y)
            let toX = try decodeI32(.toX, alt: .to_x)
            let toY = try decodeI32(.toY, alt: .to_y)
            self = .move(actorId: actorId, fromX: fromX, fromY: fromY, toX: toX, toY: toY)
            
        case "Hit", "hit":
            let attackerId = try decodeU32(.attackerId, alt: .attacker_id)
            let defenderId = try decodeU32(.defenderId, alt: .defender_id)
            let partId = try decodeString(.partId, alt: .part_id)
            let damage = try decodeU32(.damage)
            let attackName = try decodeString(.attackName, alt: .attack_name)
            self = .hit(attackerId: attackerId, defenderId: defenderId, partId: partId, damage: damage, attackName: attackName)
            
        case "Bleed", "bleed":
            let actorId = try decodeU32(.actorId, alt: .actor_id)
            let amount = try decodeU32(.amount)
            self = .bleed(actorId: actorId, amount: amount)
            
        case "Sever", "sever":
            let actorId = try decodeU32(.actorId, alt: .actor_id)
            let partId = try decodeString(.partId, alt: .part_id)
            let gibCharStr = try decodeString(.gibChar, alt: .gib_char)
            let gibChar = gibCharStr.first ?? " "
            let x = try decodeI32(.x)
            let y = try decodeI32(.y)
            self = .sever(actorId: actorId, partId: partId, gibChar: gibChar, x: x, y: y)
            
        case "Death", "death":
            let actorId = try decodeU32(.actorId, alt: .actor_id)
            let x = try decodeI32(.x)
            let y = try decodeI32(.y)
            self = .death(actorId: actorId, x: x, y: y)
            
        case "Vomit", "vomit":
            let actorId = try decodeU32(.actorId, alt: .actor_id)
            let amount = try decodeU32(.amount)
            let x = try decodeI32(.x)
            let y = try decodeI32(.y)
            self = .vomit(actorId: actorId, amount: amount, x: x, y: y)
            
        case "StatusChange", "statusChange":
            let actorId = try decodeU32(.actorId, alt: .actor_id)
            let status = try container.decode(String.self, forKey: .status)
            let active = try container.decode(Bool.self, forKey: .active)
            self = .statusChange(actorId: actorId, status: status, active: active)
            
        case "Bump", "bump":
            let bumperId = try decodeU32(.bumperId, alt: .bumper_id)
            let bumpedId = try decodeU32(.bumpedId, alt: .bumped_id)
            let toX = try decodeI32(.toX, alt: .to_x)
            let toY = try decodeI32(.toY, alt: .to_y)
            self = .bump(bumperId: bumperId, bumpedId: bumpedId, toX: toX, toY: toY)
            
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown event type: \(type)")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .move(let actorId, let fromX, let fromY, let toX, let toY):
            try container.encode("Move", forKey: .type)
            try container.encode(actorId, forKey: .actorId)
            try container.encode(fromX, forKey: .fromX)
            try container.encode(fromY, forKey: .fromY)
            try container.encode(toX, forKey: .toX)
            try container.encode(toY, forKey: .toY)
            
        case .hit(let attackerId, let defenderId, let partId, let damage, let attackName):
            try container.encode("Hit", forKey: .type)
            try container.encode(attackerId, forKey: .attackerId)
            try container.encode(defenderId, forKey: .defenderId)
            try container.encode(partId, forKey: .partId)
            try container.encode(damage, forKey: .damage)
            try container.encode(attackName, forKey: .attackName)
            
        case .bleed(let actorId, let amount):
            try container.encode("Bleed", forKey: .type)
            try container.encode(actorId, forKey: .actorId)
            try container.encode(amount, forKey: .amount)
            
        case .sever(let actorId, let partId, let gibChar, let x, let y):
            try container.encode("Sever", forKey: .type)
            try container.encode(actorId, forKey: .actorId)
            try container.encode(partId, forKey: .partId)
            try container.encode(String(gibChar), forKey: .gibChar)
            try container.encode(x, forKey: .x)
            try container.encode(y, forKey: .y)
            
        case .death(let actorId, let x, let y):
            try container.encode("Death", forKey: .type)
            try container.encode(actorId, forKey: .actorId)
            try container.encode(x, forKey: .x)
            try container.encode(y, forKey: .y)
            
        case .vomit(let actorId, let amount, let x, let y):
            try container.encode("Vomit", forKey: .type)
            try container.encode(actorId, forKey: .actorId)
            try container.encode(amount, forKey: .amount)
            try container.encode(x, forKey: .x)
            try container.encode(y, forKey: .y)
            
        case .statusChange(let actorId, let status, let active):
            try container.encode("StatusChange", forKey: .type)
            try container.encode(actorId, forKey: .actorId)
            try container.encode(status, forKey: .status)
            try container.encode(active, forKey: .active)
            
        case .bump(let bumperId, let bumpedId, let toX, let toY):
            try container.encode("Bump", forKey: .type)
            try container.encode(bumperId, forKey: .bumperId)
            try container.encode(bumpedId, forKey: .bumpedId)
            try container.encode(toX, forKey: .toX)
            try container.encode(toY, forKey: .toY)
        }
    }
    
    /// Convert event to readable text (using actor names lookup)
    func describe(names: [UInt32: String] = [:]) -> String {
        // Helper to get name or fallback
        func name(_ id: UInt32) -> String {
            names[id] ?? "the combatant"
        }
        
        // Helper for part names
        func partName(_ partId: String) -> String {
            partId.replacingOccurrences(of: "_", with: " ")
                  .replacingOccurrences(of: "0", with: "")
                  .replacingOccurrences(of: "1", with: "")
                  .trimmingCharacters(in: .whitespaces)
        }
        
        // Flavor verbs for attacks
        func attackVerb(_ attackName: String) -> String {
            let lower = attackName.lowercased()
            if lower.contains("peck") { return ["pecks at", "jabs", "stabs at", "strikes"].randomElement()! }
            if lower.contains("bite") { return ["bites", "chomps", "sinks teeth into", "mauls"].randomElement()! }
            if lower.contains("scratch") { return ["scratches", "rakes", "tears at", "claws"].randomElement()! }
            if lower.contains("kick") { return ["kicks", "stomps", "slams"].randomElement()! }
            return "strikes"
        }
        
        // Wound severity descriptions
        func woundDesc(_ damage: UInt32) -> String {
            if damage >= 15 { return ["tearing it badly", "ripping it open", "leaving a grievous wound", "shredding it"].randomElement()! }
            if damage >= 8 { return ["wounding it", "drawing blood", "cutting deep", "leaving a gash"].randomElement()! }
            if damage >= 3 { return ["scratching it", "nicking it", "grazing it"].randomElement()! }
            return ["barely scratching it", "glancing off", "leaving a small mark"].randomElement()!
        }
        
        switch self {
        case .move:
            // Don't log movement - too spammy
            return ""
            
        case .hit(let attackerId, let defenderId, let partId, let damage, let attackName):
            let attacker = name(attackerId)
            let defender = name(defenderId)
            let part = partName(partId)
            let verb = attackVerb(attackName)
            let wound = woundDesc(damage)
            return "\(attacker) \(verb) \(defender)'s \(part), \(wound)!"
            
        case .bleed(let actorId, _):
            let actor = name(actorId)
            let desc = ["bleeds profusely", "drips blood", "leaves a trail of blood", "is bleeding badly"].randomElement()!
            return "\(actor) \(desc)."
            
        case .sever(let actorId, let partId, _, _, _):
            let actor = name(actorId)
            let part = partName(partId)
            let desc = ["is torn away", "flies off", "is ripped free", "is severed completely"].randomElement()!
            return "💥 \(actor)'s \(part) \(desc)!"
            
        case .death(let actorId, _, _):
            let actor = name(actorId)
            let desc = ["collapses", "falls lifeless", "crumples to the ground", "breathes their last", "is slain"].randomElement()!
            return "💀 \(actor) \(desc)!"
            
        case .vomit(let actorId, _, _, _):
            let actor = name(actorId)
            return "🤢 \(actor) vomits from the pain!"
            
        case .statusChange(let actorId, let status, let active):
            let actor = name(actorId)
            if status == "miss" && !active {
                return "" // Don't log miss recovery
            }
            if status == "miss" {
                return "\(actor)'s attack misses!"
            }
            if status == "fleeing" && active {
                return "😱 \(actor) panics and tries to flee!"
            }
            if status == "fleeing" && !active {
                return "\(actor) regains their composure."
            }
            return active ? "\(actor) is now \(status)." : "\(actor) recovers."
            
        case .bump(let bumperId, let bumpedId, _, _):
            let bumper = name(bumperId)
            let bumped = name(bumpedId)
            let desc = ["slams into", "crashes into", "barrels into", "collides with", "shoves"].randomElement()!
            return "💥 \(bumper) \(desc) \(bumped)!"
        }
    }
}

/// Battle state snapshot
struct BattleState: Codable {
    let seed: UInt64
    let tickCount: UInt64
    let finished: Bool
    let winner: Int?
    let grid: GridInfo
    let teamA: [ActorInfo]
    let teamB: [ActorInfo]
    
    enum CodingKeys: String, CodingKey {
        case seed
        case tickCount = "tick_count"
        case finished
        case winner
        case grid
        case teamA = "team_a"
        case teamB = "team_b"
    }
}

struct GridInfo: Codable {
    let width: Int32
    let height: Int32
}

struct ActorInfo: Codable {
    let id: UInt32
    let speciesId: String
    let glyph: Character
    let team: UInt8
    let x: Int32
    let y: Int32
    let hp: Int32
    let maxHp: Int32
    let isAlive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case speciesId = "species_id"
        case glyph
        case team
        case x
        case y
        case hp
        case maxHp = "max_hp"
        case isAlive = "is_alive"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UInt32.self, forKey: .id)
        speciesId = try container.decode(String.self, forKey: .speciesId)
        let glyphStr = try container.decode(String.self, forKey: .glyph)
        glyph = glyphStr.first ?? " "
        team = try container.decode(UInt8.self, forKey: .team)
        x = try container.decode(Int32.self, forKey: .x)
        y = try container.decode(Int32.self, forKey: .y)
        hp = try container.decode(Int32.self, forKey: .hp)
        maxHp = try container.decode(Int32.self, forKey: .maxHp)
        isAlive = try container.decode(Bool.self, forKey: .isAlive)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(speciesId, forKey: .speciesId)
        try container.encode(String(glyph), forKey: .glyph)
        try container.encode(team, forKey: .team)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(hp, forKey: .hp)
        try container.encode(maxHp, forKey: .maxHp)
        try container.encode(isAlive, forKey: .isAlive)
    }
}
