use rand::rngs::SmallRng;
use rand_seeder::Seeder;
use serde::{Deserialize, Serialize};

use crate::events::BattleEvent;
use super::actor::Actor;
use super::grid::Grid;

#[derive(Debug, Serialize)]
pub struct Battle {
    seed: u64,
    #[serde(skip)]
    rng: SmallRng,
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
            grid: Grid::new(60, 40),
            team_a: Vec::new(),
            team_b: Vec::new(),
            tick_count: 0,
            finished: false,
            winner: None,
        }
    }
    
    pub fn init_teams(&mut self, team_a_json: &str, team_b_json: &str) -> Result<(), String> {
        // For now, just parse basic actor data
        // Full species loading will come in Phase 2
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
