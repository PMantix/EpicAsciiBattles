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
        
        // Find all alive enemies
        let alive_enemies: Vec<&Actor> = enemies.iter().filter(|e| e.is_alive()).collect();
        if alive_enemies.is_empty() {
            return Some(Action::wait(actor.id));
        }
        
        // Find nearest enemy
        let nearest_enemy = alive_enemies
            .iter()
            .min_by(|a, b| {
                let dist_a = CombatResolver::distance(actor.x, actor.y, a.x, a.y);
                let dist_b = CombatResolver::distance(actor.x, actor.y, b.x, b.y);
                dist_a.partial_cmp(&dist_b).unwrap()
            })
            .copied();
        
        if let Some(enemy) = nearest_enemy {
            let distance = CombatResolver::distance(actor.x, actor.y, enemy.x, enemy.y);
            
            // If in melee range (adjacent orthogonally or diagonally)
            // Orthogonal distance = 1.0, diagonal distance = sqrt(2) ≈ 1.414
            if distance <= 1.5 {
                // 15% chance to dodge/sidestep instead of attacking
                if rng.gen_range(0..100) < 15 {
                    let dodge_moves = [(-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, 1), (-1, 1), (1, -1)];
                    let (dx, dy) = dodge_moves[rng.gen_range(0..dodge_moves.len())];
                    return Some(Action::move_to(actor.id, actor.x + dx, actor.y + dy));
                }
                
                // Pick a random attack we can afford
                let affordable_attacks: Vec<&Attack> = attacks
                    .iter()
                    .filter(|a| actor.stamina >= a.stamina_cost)
                    .collect();
                
                if !affordable_attacks.is_empty() {
                    // 20% chance to attack a different nearby enemy if available
                    let target = if alive_enemies.len() > 1 && rng.gen_range(0..100) < 20 {
                        // Find other enemies in range
                        let others_in_range: Vec<&&Actor> = alive_enemies.iter()
                            .filter(|e| {
                                let d = CombatResolver::distance(actor.x, actor.y, e.x, e.y);
                                d <= 1.5 && e.id != enemy.id
                            })
                            .collect();
                        if !others_in_range.is_empty() {
                            others_in_range[rng.gen_range(0..others_in_range.len())]
                        } else {
                            &enemy
                        }
                    } else {
                        &enemy
                    };
                    
                    let attack = affordable_attacks[rng.gen_range(0..affordable_attacks.len())];
                    return Some(Action::attack(
                        actor.id,
                        target.id,
                        attack.attack_id.clone(),
                    ));
                } else {
                    // No stamina - step back to recover
                    let dx = (actor.x - enemy.x).signum();
                    let dy = (actor.y - enemy.y).signum();
                    return Some(Action::move_to(actor.id, actor.x + dx, actor.y + dy));
                }
            }
            
            // Not in range - move towards enemy
            let dx = (enemy.x - actor.x).signum();
            let dy = (enemy.y - actor.y).signum();
            
            // 10% chance to take a slightly different path (flank)
            let (final_dx, final_dy) = if rng.gen_range(0..100) < 10 {
                if rng.gen_bool(0.5) {
                    (dx, if dy == 0 { rng.gen_range(-1..=1) } else { dy })
                } else {
                    (if dx == 0 { rng.gen_range(-1..=1) } else { dx }, dy)
                }
            } else {
                (dx, dy)
            };
            
            return Some(Action::move_to(actor.id, actor.x + final_dx, actor.y + final_dy));
        }
        
        // No valid action
        Some(Action::wait(actor.id))
    }
}
