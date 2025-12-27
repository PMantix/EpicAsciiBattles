use crate::species::Species;
use std::collections::{HashMap, HashSet};

pub struct SpeciesValidator {
    required_tags: HashSet<String>,
}

impl SpeciesValidator {
    pub fn new() -> Self {
        let mut required_tags = HashSet::new();
        // At minimum, require at least one vital part
        required_tags.insert("vital".to_string());
        
        Self { required_tags }
    }
    
    /// Validate a species definition
    pub fn validate(&self, species: &Species) -> Result<(), Vec<String>> {
        let mut errors = Vec::new();
        
        // Check basic fields
        if species.id.is_empty() {
            errors.push("Species ID cannot be empty".to_string());
        }
        
        if species.name.is_empty() {
            errors.push("Species name cannot be empty".to_string());
        }
        
        if species.parts.is_empty() {
            errors.push("Species must have at least one part".to_string());
            return Err(errors); // Can't continue without parts
        }
        
        // Check for vital parts
        let has_vital = species.has_part_with_tag("vital") || species.has_part_with_tag("brain");
        if !has_vital {
            errors.push("Species must have at least one vital part (vital or brain tag)".to_string());
        }
        
        // Validate part graph structure
        self.validate_part_graph(species, &mut errors);
        
        // Validate part definitions
        self.validate_parts(species, &mut errors);
        
        // Validate base stats
        self.validate_base_stats(species, &mut errors);
        
        if errors.is_empty() {
            Ok(())
        } else {
            Err(errors)
        }
    }
    
    fn validate_part_graph(&self, species: &Species, errors: &mut Vec<String>) {
        let part_ids: HashSet<String> = species.parts.iter()
            .map(|p| p.part_id.clone())
            .collect();
        
        // Check for duplicate part IDs
        let mut seen_ids = HashMap::new();
        for part in &species.parts {
            if let Some(count) = seen_ids.get_mut(&part.part_id) {
                *count += 1;
            } else {
                seen_ids.insert(&part.part_id, 1);
            }
        }
        
        for (part_id, count) in seen_ids {
            if count > 1 {
                errors.push(format!("Duplicate part ID: '{}'", part_id));
            }
        }
        
        // Validate attachments
        for part in &species.parts {
            for attachment in &part.attachments {
                if !part_ids.contains(attachment) {
                    errors.push(format!(
                        "Part '{}' attaches to non-existent part '{}'",
                        part.part_id, attachment
                    ));
                }
            }
        }
        
        // Check for root parts (parts with no attachments)
        let root_parts: Vec<_> = species.parts.iter()
            .filter(|p| p.attachments.is_empty())
            .collect();
        
        if root_parts.is_empty() {
            errors.push("Species must have at least one root part (no attachments)".to_string());
        }
        
        // Check for circular dependencies (basic check)
        for part in &species.parts {
            if part.attachments.contains(&part.part_id) {
                errors.push(format!("Part '{}' cannot attach to itself", part.part_id));
            }
        }
    }
    
    fn validate_parts(&self, species: &Species, errors: &mut Vec<String>) {
        for part in &species.parts {
            // Validate part_id
            if part.part_id.is_empty() {
                errors.push("Part ID cannot be empty".to_string());
            }
            
            // Validate display_name
            if part.display_name.is_empty() {
                errors.push(format!("Part '{}' must have a display name", part.part_id));
            }
            
            // Validate count
            if part.count == 0 {
                errors.push(format!("Part '{}' count must be at least 1", part.part_id));
            }
            
            // Validate HP
            if part.hp <= 0 {
                errors.push(format!("Part '{}' must have positive HP", part.part_id));
            }
            
            // Validate hit_weight
            if part.hit_weight == 0 {
                errors.push(format!("Part '{}' must have non-zero hit_weight", part.part_id));
            }
            
            // Check weapon parts have appropriate tags
            if part.has_tag("peck_weapon") || part.has_tag("bite_weapon") 
                || part.has_tag("scratch_weapon") || part.has_tag("sting_weapon") {
                // Weapon parts should generally have sharp or blunt tags
                if !part.has_tag("sharp") && !part.has_tag("blunt") {
                    // This is a warning, not an error
                    eprintln!("Warning: Weapon part '{}' has no sharp/blunt tag", part.part_id);
                }
            }
        }
    }
    
    fn validate_base_stats(&self, species: &Species, errors: &mut Vec<String>) {
        let stats = &species.base_stats;
        
        if stats.mass_kg <= 0.0 {
            errors.push("Mass must be positive".to_string());
        }
        
        if stats.speed == 0 {
            errors.push("Speed must be at least 1".to_string());
        }
        
        if stats.stamina == 0 {
            errors.push("Stamina must be at least 1".to_string());
        }
    }
}

impl Default for SpeciesValidator {
    fn default() -> Self {
        Self::new()
    }
}

