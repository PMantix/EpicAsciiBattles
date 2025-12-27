import Foundation

/// Swift wrapper for the Rust battle simulation FFI
class GameCore {
    private var handle: OpaquePointer?
    let seed: UInt64
    
    init(seed: UInt64) {
        self.seed = seed
        self.handle = sim_new(seed)
    }
    
    deinit {
        if let handle = handle {
            sim_free(handle)
        }
    }
    
    /// Initialize battle with team compositions
    func initBattle(teamA: String, teamB: String) -> Bool {
        guard let handle = handle else { return false }
        
        return teamA.withCString { teamAPtr in
            teamB.withCString { teamBPtr in
                sim_init_battle(handle, teamAPtr, teamBPtr)
            }
        }
    }
    
    /// Advance simulation by one tick
    func tick() {
        guard let handle = handle else { return }
        sim_tick(handle)
    }
    
    /// Get events since last call
    func getEvents() -> [BattleEvent] {
        guard let handle = handle else { return [] }
        
        guard let cString = sim_get_events_json(handle) else {
            return []
        }
        
        defer {
            sim_free_string(UnsafeMutablePointer(mutating: cString))
        }
        
        let jsonString = String(cString: cString)
        guard let jsonData = jsonString.data(using: .utf8) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([BattleEvent].self, from: jsonData)
        } catch {
            print("Failed to decode events: \(error)")
            return []
        }
    }
    
    /// Get current battle state
    func getState() -> BattleState? {
        guard let handle = handle else { return nil }
        
        guard let cString = sim_get_state_json(handle) else {
            return nil
        }
        
        defer {
            sim_free_string(UnsafeMutablePointer(mutating: cString))
        }
        
        let jsonString = String(cString: cString)
        guard let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(BattleState.self, from: jsonData)
        } catch {
            print("Failed to decode state: \(error)")
            return nil
        }
    }
    
    /// Check if battle is finished
    func isFinished() -> Bool {
        guard let handle = handle else { return false }
        return sim_is_finished(handle)
    }
    
    /// Get winner (0 = team A, 1 = team B, -1 = ongoing)
    func getWinner() -> Int {
        guard let handle = handle else { return -1 }
        return Int(sim_get_winner(handle))
    }
}

// C function declarations
@_silgen_name("sim_new")
func sim_new(_ seed: UInt64) -> OpaquePointer?

@_silgen_name("sim_init_battle")
func sim_init_battle(_ handle: OpaquePointer, _ teamA: UnsafePointer<CChar>, _ teamB: UnsafePointer<CChar>) -> Bool

@_silgen_name("sim_tick")
func sim_tick(_ handle: OpaquePointer)

@_silgen_name("sim_get_events_json")
func sim_get_events_json(_ handle: OpaquePointer) -> UnsafePointer<CChar>?

@_silgen_name("sim_get_state_json")
func sim_get_state_json(_ handle: OpaquePointer) -> UnsafePointer<CChar>?

@_silgen_name("sim_is_finished")
func sim_is_finished(_ handle: OpaquePointer) -> Bool

@_silgen_name("sim_get_winner")
func sim_get_winner(_ handle: OpaquePointer) -> Int32

@_silgen_name("sim_free_string")
func sim_free_string(_ s: UnsafeMutablePointer<CChar>)

@_silgen_name("sim_free")
func sim_free(_ handle: OpaquePointer)
