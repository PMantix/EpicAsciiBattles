use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "camelCase")]
pub enum BattleEvent {
    Move {
        actor_id: u32,
        from_x: i32,
        from_y: i32,
        to_x: i32,
        to_y: i32,
    },
    Hit {
        attacker_id: u32,
        defender_id: u32,
        part_id: String,
        damage: u32,
        attack_name: String,
    },
    Bleed {
        actor_id: u32,
        amount: u32,
    },
    Sever {
        actor_id: u32,
        part_id: String,
        gib_char: char,
        x: i32,
        y: i32,
    },
    Death {
        actor_id: u32,
        x: i32,
        y: i32,
    },
    Vomit {
        actor_id: u32,
        amount: u32,
        x: i32,
        y: i32,
    },
    StatusChange {
        actor_id: u32,
        status: String,
        active: bool,
    },
    /// Two actors collided and one was bumped to a new position
    Bump {
        bumper_id: u32,
        bumped_id: u32,
        to_x: i32,
        to_y: i32,
    },
}

pub struct EventStream {
    events: Vec<BattleEvent>,
}

impl EventStream {
    pub fn new() -> Self {
        Self {
            events: Vec::new(),
        }
    }
    
    pub fn push(&mut self, event: BattleEvent) {
        self.events.push(event);
    }
    
    pub fn extend(&mut self, events: Vec<BattleEvent>) {
        self.events.extend(events);
    }
    
    pub fn drain(&mut self) -> Vec<BattleEvent> {
        std::mem::take(&mut self.events)
    }
}

impl Default for EventStream {
    fn default() -> Self {
        Self::new()
    }
}
