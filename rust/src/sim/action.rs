use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Action {
    Attack {
        attacker_id: u32,
        target_id: u32,
        attack_id: String,
    },
    Move {
        actor_id: u32,
        target_x: i32,
        target_y: i32,
    },
    Defend {
        actor_id: u32,
    },
    Wait {
        actor_id: u32,
    },
}

impl Action {
    pub fn attack(attacker_id: u32, target_id: u32, attack_id: String) -> Self {
        Action::Attack {
            attacker_id,
            target_id,
            attack_id,
        }
    }
    
    pub fn move_to(actor_id: u32, target_x: i32, target_y: i32) -> Self {
        Action::Move {
            actor_id,
            target_x,
            target_y,
        }
    }
    
    pub fn defend(actor_id: u32) -> Self {
        Action::Defend { actor_id }
    }
    
    pub fn wait(actor_id: u32) -> Self {
        Action::Wait { actor_id }
    }
    
    pub fn actor_id(&self) -> u32 {
        match self {
            Action::Attack { attacker_id, .. } => *attacker_id,
            Action::Move { actor_id, .. } => *actor_id,
            Action::Defend { actor_id } => *actor_id,
            Action::Wait { actor_id } => *actor_id,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CombatAction {
    pub action: Action,
    pub stamina_cost: u32,
}

impl CombatAction {
    pub fn new(action: Action, stamina_cost: u32) -> Self {
        Self {
            action,
            stamina_cost,
        }
    }
}
