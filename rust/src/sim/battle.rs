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
use super::action::Action;
use super::combat::CombatResolver;
use super::ai::SimpleAI;

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
        
        let mut events = Vec::new();
        self.tick_count += 1;
        
        // 1. Apply bleeding damage to all actors
        for actor in self.team_a.iter_mut().chain(self.team_b.iter_mut()) {
            if actor.is_alive() {
                let bleed_events = CombatResolver::apply_bleeding(actor);
                events.extend(bleed_events);
            }
        }
        
        // 2. Regenerate stamina
        for actor in self.team_a.iter_mut().chain(self.team_b.iter_mut()) {
            if actor.is_alive() {
                let regen = (actor.max_stamina / 10).max(5);
                actor.stamina = (actor.stamina + regen).min(actor.max_stamina);
            }
        }
        
        // 3. Build turn order based on speed (highest speed acts first)
        // Collect all alive actors with their indices and team
        let mut turn_order: Vec<(u32, u8, u32)> = Vec::new(); // (actor_id, team, speed)
        
        for actor in &self.team_a {
            if actor.is_alive() {
                turn_order.push((actor.id, 0, actor.speed));
            }
        }
        
        for actor in &self.team_b {
            if actor.is_alive() {
                turn_order.push((actor.id, 1, actor.speed));
            }
        }
        
        // Sort by speed (descending), then by actor_id for determinism
        turn_order.sort_by(|a, b| {
            b.2.cmp(&a.2).then_with(|| a.0.cmp(&b.0))
        });
        
        // 4. Process each actor's turn individually
        for (actor_id, team, _speed) in turn_order {
            // Find the current actor
            let actor_ref = if team == 0 {
                self.team_a.iter().find(|a| a.id == actor_id)
            } else {
                self.team_b.iter().find(|a| a.id == actor_id)
            };
            
            if actor_ref.is_none() || !actor_ref.unwrap().is_alive() {
                continue;
            }
            
            // Select action for this actor based on team
            let action = if team == 0 {
                SimpleAI::select_action(
                    &mut self.rng,
                    actor_ref.unwrap(),
                    &self.team_a,
                    &self.team_b,
                )
            } else {
                SimpleAI::select_action(
                    &mut self.rng,
                    actor_ref.unwrap(),
                    &self.team_b,
                    &self.team_a,
                )
            };
            
            if action.is_none() {
                continue;
            }
            
            // Execute the action
            match action.unwrap() {
                Action::Attack {
                    attacker_id,
                    target_id,
                    attack_id,
                } => {
                    // Determine which teams the attacker and defender are on
                    let attacker_in_a = self.team_a.iter().any(|a| a.id == attacker_id);
                    let defender_in_a = self.team_a.iter().any(|a| a.id == target_id);
                    
                    // Can't attack same team
                    if attacker_in_a == defender_in_a {
                        continue;
                    }
                    
                    // Get attack data from attacker
                    let attack_opt = {
                        let attacker = if attacker_in_a {
                            self.team_a.iter().find(|a| a.id == attacker_id)
                        } else {
                            self.team_b.iter().find(|a| a.id == attacker_id)
                        };
                        
                        attacker
                            .and_then(|a| {
                                a.get_available_attacks()
                                    .into_iter()
                                    .find(|atk| atk.attack_id == attack_id)
                            })
                    };
                    
                    if let Some(attack) = attack_opt {
                        // Resolve combat based on team configuration
                        let combat_events = if attacker_in_a {
                            // Team A attacks Team B
                            let attacker = self.team_a.iter_mut().find(|a| a.id == attacker_id);
                            let defender = self.team_b.iter_mut().find(|a| a.id == target_id);
                            
                            if let (Some(attacker), Some(defender)) = (attacker, defender) {
                                CombatResolver::resolve_attack(&mut self.rng, attacker, defender, &attack)
                            } else {
                                Vec::new()
                            }
                        } else {
                            // Team B attacks Team A
                            let attacker = self.team_b.iter_mut().find(|a| a.id == attacker_id);
                            let defender = self.team_a.iter_mut().find(|a| a.id == target_id);
                            
                            if let (Some(attacker), Some(defender)) = (attacker, defender) {
                                CombatResolver::resolve_attack(&mut self.rng, attacker, defender, &attack)
                            } else {
                                Vec::new()
                            }
                        };
                        
                        events.extend(combat_events);
                    }
                }
                Action::Move {
                    actor_id,
                    target_x,
                    target_y,
                } => {
                    // Find actor
                    if let Some(actor) = self
                        .team_a
                        .iter_mut()
                        .find(|a| a.id == actor_id)
                        .or_else(|| self.team_b.iter_mut().find(|a| a.id == actor_id))
                    {
                        if actor.is_alive() && actor.speed > 0 {
                            // Check if target is walkable
                            if self.grid.is_walkable(target_x, target_y) {
                                let old_x = actor.x;
                                let old_y = actor.y;
                                actor.x = target_x;
                                actor.y = target_y;
                                
                                events.push(BattleEvent::Move {
                                    actor_id,
                                    from_x: old_x,
                                    from_y: old_y,
                                    to_x: target_x,
                                    to_y: target_y,
                                });
                            }
                        }
                    }
                }
                Action::Defend { .. } | Action::Wait { .. } => {
                    // No-op for now
                }
            }
        }
        
        // 5. Check win conditions
        let team_a_alive = self.team_a.iter().filter(|a| a.is_alive()).count();
        let team_b_alive = self.team_b.iter().filter(|a| a.is_alive()).count();
        
        if team_a_alive == 0 {
            self.finished = true;
            self.winner = Some(1);
        } else if team_b_alive == 0 {
            self.finished = true;
            self.winner = Some(0);
        }
        
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
