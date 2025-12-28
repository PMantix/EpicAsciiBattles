use serde::{Deserialize, Serialize};
use crate::anatomy::part::Part;
use crate::sim::Attack;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Actor {
    pub id: u32,
    pub species_id: String,
    pub glyph: char,
    pub color: String,
    pub team: u8,
    pub x: i32,
    pub y: i32,
    pub hp: i32,
    pub max_hp: i32,
    #[serde(rename = "is_alive")]
    pub alive: bool,
    pub parts: Vec<Part>,
    pub stamina: u32,
    pub max_stamina: u32,
    pub speed: u32,
    pub morale: u32,
}

impl Actor {
    pub fn new(id: u32, species_id: String, glyph: char, color: String, team: u8, x: i32, y: i32) -> Self {
        Self {
            id,
            species_id,
            glyph,
            color,
            team,
            x,
            y,
            hp: 100,
            max_hp: 100,
            alive: true,
            parts: Vec::new(),
            stamina: 100,
            max_stamina: 100,
            speed: 5,
            morale: 100,
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
    
    /// Remove a part from the actor (when severed or destroyed)
    pub fn remove_part(&mut self, part_id: &str) -> bool {
        if let Some(index) = self.parts.iter().position(|p| p.part_id == part_id) {
            let part = self.parts.remove(index);
            
            // Apply effects based on lost part tags
            self.apply_part_loss_effects(&part);
            
            return true;
        }
        false
    }
    
    /// Apply capability effects when a part is lost
    fn apply_part_loss_effects(&mut self, lost_part: &Part) {
        // Loss of vital parts = death
        if lost_part.has_tag("vital") || lost_part.has_tag("brain") {
            self.hp = 0;
            self.alive = false;
            return;
        }
        
        // Loss of locomotion = immobile
        if lost_part.has_tag("locomotion") {
            // Check if we still have any locomotion parts
            let has_locomotion = self.parts.iter().any(|p| p.has_tag("locomotion"));
            if !has_locomotion {
                self.speed = 0; // Can't move
            } else {
                // Reduced speed if we lost some but not all legs
                self.speed = (self.speed / 2).max(1);
            }
        }
        
        // Loss of flight capability
        if lost_part.has_tag("flight") {
            let has_flight = self.parts.iter().any(|p| p.has_tag("flight"));
            if !has_flight {
                // Can no longer fly, reduced speed
                self.speed = (self.speed * 3 / 4).max(1);
            }
        }
        
        // Loss of balance affects accuracy/speed
        if lost_part.has_tag("balance") {
            let balance_count = self.parts.iter().filter(|p| p.has_tag("balance")).count();
            if balance_count < 2 {
                // Reduced speed/effectiveness with poor balance
                self.speed = (self.speed * 4 / 5).max(1);
            }
        }
        
        // Loss of weapon parts (handled by attack availability, not here)
    }
    
    /// Get available attacks based on current parts
    pub fn get_available_attacks(&self) -> Vec<Attack> {
        let mut attacks = Vec::new();
        
        for part in &self.parts {
            if let Some(attack) = Attack::derive_from_tags(
                &part.part_id,
                &part.display_name,
                &part.tags,
                part.hp,
            ) {
                attacks.push(attack);
            }
        }
        
        attacks
    }
    
    /// Check if actor has a specific part type
    pub fn has_part_with_tag(&self, tag: &str) -> bool {
        self.parts.iter().any(|p| p.has_tag(tag))
    }
    
    /// Get total bleed rate from all parts
    pub fn get_total_bleed_rate(&self) -> u32 {
        self.parts.iter().map(|p| p.bleed_rate).sum()
    }
}
