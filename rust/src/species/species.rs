use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use crate::sim::Attack;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Species {
    pub id: String,
    pub name: String,
    pub glyph: char,
    pub color: String,
    pub base_stats: BaseStats,
    pub parts: Vec<PartDefinition>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BaseStats {
    pub mass_kg: f32,
    pub speed: u32,
    pub stamina: u32,
    pub pain_tolerance: u32,
    pub base_morale: u32,
    pub aggression: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PartDefinition {
    pub part_id: String,
    pub display_name: String,
    pub count: u32,
    pub attachments: Vec<String>,
    pub tags: Vec<String>,
    pub hp: i32,
    pub armor: i32,
    pub bleed_rate: u32,
    pub hit_weight: u32,
}

impl Species {
    pub fn new(id: String, name: String, glyph: char) -> Self {
        Self {
            id,
            name,
            glyph,
            color: "white".to_string(),
            base_stats: BaseStats {
                mass_kg: 1.0,
                speed: 5,
                stamina: 50,
                pain_tolerance: 50,
                base_morale: 100,
                aggression: 50,
            },
            parts: Vec::new(),
        }
    }
    
    pub fn add_part(&mut self, part: PartDefinition) {
        self.parts.push(part);
    }
    
    pub fn get_part(&self, part_id: &str) -> Option<&PartDefinition> {
        self.parts.iter().find(|p| p.part_id == part_id)
    }
    
    pub fn get_parts_with_tag(&self, tag: &str) -> Vec<&PartDefinition> {
        self.parts
            .iter()
            .filter(|p| p.tags.iter().any(|t| t == tag))
            .collect()
    }
    
    pub fn has_part_with_tag(&self, tag: &str) -> bool {
        self.parts.iter().any(|p| p.tags.iter().any(|t| t == tag))
    }
    
    /// Get all unique tags from all parts
    pub fn get_all_tags(&self) -> Vec<String> {
        let mut tags: Vec<String> = self.parts
            .iter()
            .flat_map(|p| p.tags.clone())
            .collect();
        tags.sort();
        tags.dedup();
        tags
    }
    
    /// Derive all available attacks from weapon parts
    pub fn derive_attacks(&self) -> Vec<Attack> {
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
    
    /// Validate the species definition
    pub fn validate(&self) -> Result<(), Vec<String>> {
        let mut errors = Vec::new();
        
        // Check for at least one part
        if self.parts.is_empty() {
            errors.push("Species must have at least one part".to_string());
        }
        
        // Check for vital parts
        let has_vital = self.has_part_with_tag("vital") || self.has_part_with_tag("brain");
        if !has_vital {
            errors.push("Species must have at least one vital part (vital or brain tag)".to_string());
        }
        
        // Validate part attachments
        let part_ids: Vec<String> = self.parts.iter().map(|p| p.part_id.clone()).collect();
        for part in &self.parts {
            if !part.attachments.is_empty() {
                for attachment in &part.attachments {
                    if !part_ids.contains(attachment) {
                        errors.push(format!(
                            "Part '{}' attaches to non-existent part '{}'",
                            part.part_id, attachment
                        ));
                    }
                }
            }
        }
        
        // Check for duplicate part IDs
        let mut seen_ids = HashMap::new();
        for part in &self.parts {
            if seen_ids.contains_key(&part.part_id) {
                errors.push(format!("Duplicate part ID: '{}'", part.part_id));
            }
            seen_ids.insert(&part.part_id, true);
        }
        
        if errors.is_empty() {
            Ok(())
        } else {
            Err(errors)
        }
    }
}

impl PartDefinition {
    pub fn new(part_id: String, display_name: String) -> Self {
        Self {
            part_id,
            display_name,
            count: 1,
            attachments: Vec::new(),
            tags: Vec::new(),
            hp: 10,
            armor: 0,
            bleed_rate: 0,
            hit_weight: 1,
        }
    }
    
    pub fn with_count(mut self, count: u32) -> Self {
        self.count = count;
        self
    }
    
    pub fn with_attachments(mut self, attachments: Vec<String>) -> Self {
        self.attachments = attachments;
        self
    }
    
    pub fn with_tags(mut self, tags: Vec<String>) -> Self {
        self.tags = tags;
        self
    }
    
    pub fn with_hp(mut self, hp: i32) -> Self {
        self.hp = hp;
        self
    }
    
    pub fn with_armor(mut self, armor: i32) -> Self {
        self.armor = armor;
        self
    }
    
    pub fn with_bleed_rate(mut self, bleed_rate: u32) -> Self {
        self.bleed_rate = bleed_rate;
        self
    }
    
    pub fn with_hit_weight(mut self, hit_weight: u32) -> Self {
        self.hit_weight = hit_weight;
        self
    }
    
    pub fn has_tag(&self, tag: &str) -> bool {
        self.tags.iter().any(|t| t == tag)
    }
}
