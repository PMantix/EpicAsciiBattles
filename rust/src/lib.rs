use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::ptr;

mod sim;
mod anatomy;
mod species;
mod events;

use sim::Battle;
use events::EventStream;

/// Opaque handle to a battle simulation
#[repr(C)]
pub struct SimHandle {
    battle: Battle,
    event_stream: EventStream,
}

/// Create a new battle simulation with the given seed
/// Returns an opaque pointer to the simulation handle
/// 
/// # Safety
/// The returned pointer must be freed with sim_free
#[no_mangle]
pub extern "C" fn sim_new(seed: u64) -> *mut SimHandle {
    let battle = Battle::new(seed);
    let event_stream = EventStream::new();
    
    let handle = Box::new(SimHandle {
        battle,
        event_stream,
    });
    
    Box::into_raw(handle)
}

/// Initialize a battle with team compositions
/// team_a_json and team_b_json should be JSON arrays of combatant definitions
/// 
/// # Safety
/// handle must be a valid pointer returned by sim_new
/// team_a_json and team_b_json must be valid null-terminated C strings
#[no_mangle]
pub extern "C" fn sim_init_battle(
    handle: *mut SimHandle,
    team_a_json: *const c_char,
    team_b_json: *const c_char,
) -> bool {
    if handle.is_null() || team_a_json.is_null() || team_b_json.is_null() {
        return false;
    }
    
    unsafe {
        let handle = &mut *handle;
        
        let team_a_str = match CStr::from_ptr(team_a_json).to_str() {
            Ok(s) => s,
            Err(_) => return false,
        };
        
        let team_b_str = match CStr::from_ptr(team_b_json).to_str() {
            Ok(s) => s,
            Err(_) => return false,
        };
        
        handle.battle.init_teams(team_a_str, team_b_str).is_ok()
    }
}

/// Advance the simulation by one tick
/// 
/// # Safety
/// handle must be a valid pointer returned by sim_new
#[no_mangle]
pub extern "C" fn sim_tick(handle: *mut SimHandle) {
    if handle.is_null() {
        return;
    }
    
    unsafe {
        let handle = &mut *handle;
        let events = handle.battle.tick();
        handle.event_stream.extend(events);
    }
}

/// Get all events since the last call to this function as a JSON string
/// Returns a pointer to a null-terminated C string that must be freed with sim_free_string
/// 
/// # Safety
/// handle must be a valid pointer returned by sim_new
#[no_mangle]
pub extern "C" fn sim_get_events_json(handle: *mut SimHandle) -> *mut c_char {
    if handle.is_null() {
        return ptr::null_mut();
    }
    
    unsafe {
        let handle = &mut *handle;
        let events = handle.event_stream.drain();
        
        match serde_json::to_string(&events) {
            Ok(json) => {
                match CString::new(json) {
                    Ok(c_str) => c_str.into_raw(),
                    Err(_) => ptr::null_mut(),
                }
            }
            Err(_) => ptr::null_mut(),
        }
    }
}

/// Get the current battle state as a JSON string
/// Returns a pointer to a null-terminated C string that must be freed with sim_free_string
/// 
/// # Safety
/// handle must be a valid pointer returned by sim_new
#[no_mangle]
pub extern "C" fn sim_get_state_json(handle: *mut SimHandle) -> *mut c_char {
    if handle.is_null() {
        return ptr::null_mut();
    }
    
    unsafe {
        let handle = &*handle;
        
        match serde_json::to_string(&handle.battle) {
            Ok(json) => {
                match CString::new(json) {
                    Ok(c_str) => c_str.into_raw(),
                    Err(_) => ptr::null_mut(),
                }
            }
            Err(_) => ptr::null_mut(),
        }
    }
}

/// Check if the battle has finished
/// 
/// # Safety
/// handle must be a valid pointer returned by sim_new
#[no_mangle]
pub extern "C" fn sim_is_finished(handle: *mut SimHandle) -> bool {
    if handle.is_null() {
        return false;
    }
    
    unsafe {
        let handle = &*handle;
        handle.battle.is_finished()
    }
}

/// Get the winner of the battle
/// Returns 0 for team A, 1 for team B, -1 if battle is still ongoing
/// 
/// # Safety
/// handle must be a valid pointer returned by sim_new
#[no_mangle]
pub extern "C" fn sim_get_winner(handle: *mut SimHandle) -> i32 {
    if handle.is_null() {
        return -1;
    }
    
    unsafe {
        let handle = &*handle;
        handle.battle.get_winner()
    }
}

/// Free a string returned by the library
/// 
/// # Safety
/// s must be a pointer returned by sim_get_events_json or sim_get_state_json
#[no_mangle]
pub extern "C" fn sim_free_string(s: *mut c_char) {
    if !s.is_null() {
        unsafe {
            let _ = CString::from_raw(s);
        }
    }
}

/// Free a simulation handle
/// 
/// # Safety
/// handle must be a valid pointer returned by sim_new and not already freed
#[no_mangle]
pub extern "C" fn sim_free(handle: *mut SimHandle) {
    if !handle.is_null() {
        unsafe {
            let _ = Box::from_raw(handle);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_ffi_lifecycle() {
        let handle = sim_new(12345);
        assert!(!handle.is_null());
        
        let is_finished = sim_is_finished(handle);
        assert!(!is_finished);
        
        sim_free(handle);
    }
}
