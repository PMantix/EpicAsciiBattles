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
        case actorId, fromX, fromY, toX, toY
        case attackerId, defenderId, partId, damage, attackName
        case amount, gibChar, x, y
        case status, active
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "Move":
            let actorId = try container.decode(UInt32.self, forKey: .actorId)
            let fromX = try container.decode(Int32.self, forKey: .fromX)
            let fromY = try container.decode(Int32.self, forKey: .fromY)
            let toX = try container.decode(Int32.self, forKey: .toX)
            let toY = try container.decode(Int32.self, forKey: .toY)
            self = .move(actorId: actorId, fromX: fromX, fromY: fromY, toX: toX, toY: toY)
            
        case "Hit":
            let attackerId = try container.decode(UInt32.self, forKey: .attackerId)
            let defenderId = try container.decode(UInt32.self, forKey: .defenderId)
            let partId = try container.decode(String.self, forKey: .partId)
            let damage = try container.decode(UInt32.self, forKey: .damage)
            let attackName = try container.decode(String.self, forKey: .attackName)
            self = .hit(attackerId: attackerId, defenderId: defenderId, partId: partId, damage: damage, attackName: attackName)
            
        case "Bleed":
            let actorId = try container.decode(UInt32.self, forKey: .actorId)
            let amount = try container.decode(UInt32.self, forKey: .amount)
            self = .bleed(actorId: actorId, amount: amount)
            
        case "Sever":
            let actorId = try container.decode(UInt32.self, forKey: .actorId)
            let partId = try container.decode(String.self, forKey: .partId)
            let gibCharStr = try container.decode(String.self, forKey: .gibChar)
            let gibChar = gibCharStr.first ?? " "
            let x = try container.decode(Int32.self, forKey: .x)
            let y = try container.decode(Int32.self, forKey: .y)
            self = .sever(actorId: actorId, partId: partId, gibChar: gibChar, x: x, y: y)
            
        case "Death":
            let actorId = try container.decode(UInt32.self, forKey: .actorId)
            let x = try container.decode(Int32.self, forKey: .x)
            let y = try container.decode(Int32.self, forKey: .y)
            self = .death(actorId: actorId, x: x, y: y)
            
        case "Vomit":
            let actorId = try container.decode(UInt32.self, forKey: .actorId)
            let amount = try container.decode(UInt32.self, forKey: .amount)
            let x = try container.decode(Int32.self, forKey: .x)
            let y = try container.decode(Int32.self, forKey: .y)
            self = .vomit(actorId: actorId, amount: amount, x: x, y: y)
            
        case "StatusChange":
            let actorId = try container.decode(UInt32.self, forKey: .actorId)
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
}

/// Battle state snapshot
struct BattleState: Codable {
    let seed: UInt64
    let tickCount: UInt64
    let finished: Bool
    let winner: Int?
    
    enum CodingKeys: String, CodingKey {
        case seed
        case tickCount = "tick_count"
        case finished
        case winner
    }
}
