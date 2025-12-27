use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Part {
    pub part_id: String,
    pub display_name: String,
    pub count: u32,
    pub attachments: Vec<String>,
    pub tags: Vec<String>,
    pub hp: i32,
    pub max_hp: i32,
    pub armor: i32,
    pub bleed_rate: u32,
    pub hit_weight: u32,
}

impl Part {
    pub fn new(part_id: String, display_name: String) -> Self {
        Self {
            part_id,
            display_name,
            count: 1,
            attachments: Vec::new(),
            tags: Vec::new(),
            hp: 10,
            max_hp: 10,
            armor: 0,
            bleed_rate: 0,
            hit_weight: 1,
        }
    }
    
    pub fn is_destroyed(&self) -> bool {
        self.hp <= 0
    }
    
    pub fn has_tag(&self, tag: &str) -> bool {
        self.tags.iter().any(|t| t == tag)
    }
}
