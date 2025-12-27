use rand::rngs::SmallRng;
use rand_seeder::Seeder;
use rand::Rng;
use serde::{Deserialize, Serialize};

use crate::events::BattleEvent;
use crate::species::{Species, SpeciesLoader};
use crate::anatomy::part::Part;
use crate::variation::VariationGenerator;
use super::actor::Actor;
use super::grid::Grid;

#[derive(Debug, Serialize)]
pub struct Battle {
    seed: u64,
    #[serde(skip)]
    rng: SmallRng,
    #[serde(skip)]
    species_loader: SpeciesLoader,
    grid: Grid,
    team_a: Vec<Actor>,
    team_b: Vec<Actor>,
    tick_count: u64,
    finished: bool,
    winner: Option<u8>, // 0 = team A, 1 = team B
}

impl Battle {
    pub fn new(seed: u64) -> Self {
        let rng: SmallRng = Seeder::from(seed).make_rng();
        
        Self {
            seed,
            rng,
            species_loader: SpeciesLoader::new(),
            grid: Grid::new(60, 40),
            team_a: Vec::new(),
            team_b: Vec::new(),
            tick_count: 0,
            finished: false,
            winner: None,
        }
    }
    
    /// Initialize battle with species data from YAML files
    pub fn init_with_species(&mut self, species_dir: &str, team_a_json: &str, team_b_json: &str) -> Result<(), String> {
        // Load species from directory
        self.species_loader.load_from_directory(species_dir)?;
        
        // Parse team composition
        let team_a_data: Vec<TeamMemberData> = serde_json::from_str(team_a_json)
            .map_err(|e| format!("Failed to parse team A: {}", e))?;
        let team_b_data: Vec<TeamMemberData> = serde_json::from_str(team_b_json)
            .map_err(|e| format!("Failed to parse team B: {}", e))?;
        
        // Spawn team A on the left side
        for (idx, data) in team_a_data.iter().enumerate() {
            let species = self.species_loader.get_species(&data.species_id)
                .ok_or_else(|| format!("Species '{}' not found", data.species_id))?;
            
            let y = (idx as i32 * 3) % self.grid.height();
            let mut actor = self.create_actor_from_species(idx as u32, species, 0, 5, y);
            
            // Apply variation - either specified or auto-generated
            if let Some(variation) = &data.variation {
                self.apply_variation(&mut actor, variation);
            } else {
                // Auto-generate variation
                self.apply_auto_variation(&mut actor);
            }
            
            self.team_a.push(actor);
        }
        
        // Spawn team B on the right side
        for (idx, data) in team_b_data.iter().enumerate() {
            let species = self.species_loader.get_species(&data.species_id)
                .ok_or_else(|| format!("Species '{}' not found", data.species_id))?;
            
            let y = (idx as i32 * 3) % self.grid.height();
            let mut actor = self.create_actor_from_species(
                (team_a_data.len() + idx) as u32,
                species,
                1,
                self.grid.width() - 6,
                y
            );
            
            // Apply variation - either specified or auto-generated
            if let Some(variation) = &data.variation {
                self.apply_variation(&mut actor, variation);
            } else {
                // Auto-generate variation
                self.apply_auto_variation(&mut actor);
            }
            
            self.team_b.push(actor);
        }
        
        Ok(())
    }
    
    /// Apply auto-generated variation to an actor
    fn apply_auto_variation(&mut self, actor: &mut Actor) {
        // Generate stat variation
        let (hp_mult, speed_mult, stamina_mult) = VariationGenerator::generate_stat_variation(&mut self.rng);
        
        actor.max_hp = ((actor.max_hp as f32) * hp_mult) as i32;
        actor.hp = actor.max_hp;
        actor.speed = ((actor.speed as f32) * speed_mult) as u32;
        actor.max_stamina = ((actor.max_stamina as f32) * stamina_mult) as u32;
        actor.stamina = actor.max_stamina;
        
        // Generate pre-existing injuries
        let part_ids: Vec<String> = actor.parts.iter()
            .filter(|p| !p.has_tag("vital") && !p.has_tag("brain"))
            .map(|p| p.part_id.clone())
            .collect();
        
        let injuries = VariationGenerator::generate_injuries(&mut self.rng, &part_ids);
        for (part_id, damage) in injuries {
            if let Some(part) = actor.parts.iter_mut().find(|p| p.part_id == part_id) {
                part.hp = (part.hp - damage).max(1);
            }
        }
    }
    
    /// Create an actor from a species definition
    fn create_actor_from_species(&self, id: u32, species: &Species, team: u8, x: i32, y: i32) -> Actor {
        let mut actor = Actor::new(id, species.id.clone(), species.glyph, team, x, y);
        
        // Copy base stats
        actor.max_hp = (species.base_stats.mass_kg * 10.0) as i32;
        actor.hp = actor.max_hp;
        actor.speed = species.base_stats.speed;
        actor.max_stamina = species.base_stats.stamina;
        actor.stamina = actor.max_stamina;
        actor.morale = species.base_stats.base_morale;
        
        // Clone all parts from species definition
        for part_def in &species.parts {
            for i in 0..part_def.count {
                let part_instance_id = if part_def.count > 1 {
                    format!("{}_{}", part_def.part_id, i)
                } else {
                    part_def.part_id.clone()
                };
                
                let part = Part {
                    part_id: part_instance_id,
                    display_name: part_def.display_name.clone(),
                    count: 1,
                    attachments: part_def.attachments.clone(),
                    tags: part_def.tags.clone(),
                    hp: part_def.hp,
                    max_hp: part_def.hp,
                    armor: part_def.armor,
                    bleed_rate: part_def.bleed_rate,
                    hit_weight: part_def.hit_weight,
                };
                
                actor.parts.push(part);
            }
        }
        
        actor
    }
    
    /// Apply individual variation to an actor
    fn apply_variation(&self, actor: &mut Actor, variation: &IndividualVariation) {
        // Apply stat multipliers
        if let Some(hp_mult) = variation.hp_multiplier {
            actor.max_hp = ((actor.max_hp as f32) * hp_mult) as i32;
            actor.hp = actor.max_hp;
        }
        
        if let Some(speed_mult) = variation.speed_multiplier {
            actor.speed = ((actor.speed as f32) * speed_mult) as u32;
        }
        
        if let Some(stamina_mult) = variation.stamina_multiplier {
            actor.max_stamina = ((actor.max_stamina as f32) * stamina_mult) as u32;
            actor.stamina = actor.max_stamina;
        }
        
        // Apply pre-existing injuries (reduce part HP)
        if let Some(injuries) = &variation.injuries {
            for injury in injuries {
                if let Some(part) = actor.parts.iter_mut().find(|p| p.part_id == injury.part_id) {
                    part.hp = (part.hp - injury.damage).max(1);
                }
            }
        }
    }
    
    pub fn init_teams(&mut self, team_a_json: &str, team_b_json: &str) -> Result<(), String> {
        // Legacy method for basic actor data (kept for backwards compatibility)
        // For full species support, use init_with_species instead
        let team_a_data: Vec<BasicActorData> = serde_json::from_str(team_a_json)
            .map_err(|e| format!("Failed to parse team A: {}", e))?;
        let team_b_data: Vec<BasicActorData> = serde_json::from_str(team_b_json)
            .map_err(|e| format!("Failed to parse team B: {}", e))?;
        
        // Spawn team A on the left side
        for (idx, data) in team_a_data.iter().enumerate() {
            let y = (idx as i32 * 3) % self.grid.height();
            let actor = Actor::new(
                idx as u32,
                data.species_id.clone(),
                data.glyph,
                0, // team 0
                5,
                y,
            );
            self.team_a.push(actor);
        }
        
        // Spawn team B on the right side
        for (idx, data) in team_b_data.iter().enumerate() {
            let y = (idx as i32 * 3) % self.grid.height();
            let actor = Actor::new(
                (idx + team_a_data.len()) as u32,
                data.species_id.clone(),
                data.glyph,
                1, // team 1
                self.grid.width() - 5,
                y,
            );
            self.team_b.push(actor);
        }
        
        Ok(())
    }
    
    pub fn tick(&mut self) -> Vec<BattleEvent> {
        if self.finished {
            return Vec::new();
        }
        
        let events = Vec::new();
        self.tick_count += 1;
        
        // Check win conditions
        let team_a_alive = self.team_a.iter().filter(|a| a.is_alive()).count();
        let team_b_alive = self.team_b.iter().filter(|a| a.is_alive()).count();
        
        if team_a_alive == 0 {
            self.finished = true;
            self.winner = Some(1);
        } else if team_b_alive == 0 {
            self.finished = true;
            self.winner = Some(0);
        }
        
        // Basic simulation placeholder - will be expanded in Phase 2
        // For now, just demonstrate event generation
        
        events
    }
    
    pub fn is_finished(&self) -> bool {
        self.finished
    }
    
    pub fn get_winner(&self) -> i32 {
        match self.winner {
            Some(0) => 0,
            Some(1) => 1,
            None => -1,
            _ => -1,
        }
    }
    
    pub fn get_team_a_alive_count(&self) -> usize {
        self.team_a.iter().filter(|a| a.is_alive()).count()
    }
    
    pub fn get_team_b_alive_count(&self) -> usize {
        self.team_b.iter().filter(|a| a.is_alive()).count()
    }
}

#[derive(Debug, Deserialize)]
struct BasicActorData {
    species_id: String,
    glyph: char,
}

#[derive(Debug, Deserialize)]
struct TeamMemberData {
    species_id: String,
    #[serde(default)]
    variation: Option<IndividualVariation>,
}

#[derive(Debug, Deserialize)]
struct IndividualVariation {
    #[serde(default)]
    hp_multiplier: Option<f32>,
    #[serde(default)]
    speed_multiplier: Option<f32>,
    #[serde(default)]
    stamina_multiplier: Option<f32>,
    #[serde(default)]
    injuries: Option<Vec<PreExistingInjury>>,
}

#[derive(Debug, Deserialize)]
struct PreExistingInjury {
    part_id: String,
    damage: i32,
}
