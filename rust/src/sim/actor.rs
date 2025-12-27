use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Actor {
    pub id: u32,
    pub species_id: String,
    pub glyph: char,
    pub team: u8,
    pub x: i32,
    pub y: i32,
    pub hp: i32,
    pub max_hp: i32,
    pub alive: bool,
}

impl Actor {
    pub fn new(id: u32, species_id: String, glyph: char, team: u8, x: i32, y: i32) -> Self {
        Self {
            id,
            species_id,
            glyph,
            team,
            x,
            y,
            hp: 100,
            max_hp: 100,
            alive: true,
        }
    }
    
    pub fn is_alive(&self) -> bool {
        self.alive && self.hp > 0
    }
    
    pub fn take_damage(&mut self, damage: i32) {
        self.hp -= damage;
        if self.hp <= 0 {
            self.hp = 0;
            self.alive = false;
        }
    }
}
