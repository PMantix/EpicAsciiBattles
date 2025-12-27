use rand::Rng;
use crate::sim::{Actor, Action, Attack, CombatResolver};

pub struct SimpleAI;

impl SimpleAI {
    /// Select an action for an actor
    pub fn select_action<R: Rng>(
        rng: &mut R,
        actor: &Actor,
        allies: &[Actor],
        enemies: &[Actor],
    ) -> Option<Action> {
        if !actor.is_alive() {
            return None;
        }
        
        // Get available attacks
        let attacks = actor.get_available_attacks();
        if attacks.is_empty() {
            return Some(Action::wait(actor.id));
        }
        
        // Find nearest enemy
        let nearest_enemy = enemies
            .iter()
            .filter(|e| e.is_alive())
            .min_by(|a, b| {
                let dist_a = CombatResolver::distance(actor.x, actor.y, a.x, a.y);
                let dist_b = CombatResolver::distance(actor.x, actor.y, b.x, b.y);
                dist_a.partial_cmp(&dist_b).unwrap()
            });
        
        if let Some(enemy) = nearest_enemy {
            let distance = CombatResolver::distance(actor.x, actor.y, enemy.x, enemy.y);
            
            // If in melee range (adjacent) and have stamina, attack
            if distance <= 1.1 {
                // Pick a random attack we can afford
                let affordable_attacks: Vec<&Attack> = attacks
                    .iter()
                    .filter(|a| actor.stamina >= a.stamina_cost)
                    .collect();
                
                if !affordable_attacks.is_empty() {
                    let attack = affordable_attacks[rng.gen_range(0..affordable_attacks.len())];
                    return Some(Action::attack(
                        actor.id,
                        enemy.id,
                        attack.attack_id.clone(),
                    ));
                }
            }
            
            // Move towards enemy
            let dx = (enemy.x - actor.x).signum();
            let dy = (enemy.y - actor.y).signum();
            
            return Some(Action::move_to(
                actor.id,
                actor.x + dx,
                actor.y + dy,
            ));
        }
        
        // No valid action
        Some(Action::wait(actor.id))
    }
}
