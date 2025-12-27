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
    
    enum CodingKeys: String, CodingKey {
        case type
        case actorId, actor_id, fromX, fromY, toX, toY, from_x, from_y, to_x, to_y
        case attackerId, attacker_id, defenderId, defender_id, partId, part_id, damage, attackName, attack_name
        case amount, gibChar, gib_char, x, y
        case status, active
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
        }
    }
    
    /// Convert event to readable text
    func describe() -> String {
        switch self {
        case .move(let actorId, _, _, let toX, let toY):
            return "Actor \(actorId) moves to (\(toX), \(toY))"
            
        case .hit(let attackerId, let defenderId, let partId, let damage, let attackName):
            return "Actor \(attackerId) \(attackName)s Actor \(defenderId)'s \(partId.replacingOccurrences(of: "_", with: " ")) for \(damage) damage!"
            
        case .bleed(let actorId, let amount):
            return "Actor \(actorId) bleeds for \(amount) damage"
            
        case .sever(let actorId, let partId, _, _, _):
            return "Actor \(actorId)'s \(partId.replacingOccurrences(of: "_", with: " ")) was severed!"
            
        case .death(let actorId, _, _):
            return "💀 Actor \(actorId) has died!"
            
        case .vomit(let actorId, _, _, _):
            return "Actor \(actorId) vomits from pain"
            
        case .statusChange(let actorId, let status, let active):
            return "Actor \(actorId) is \(active ? "now" : "no longer") \(status)"
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
