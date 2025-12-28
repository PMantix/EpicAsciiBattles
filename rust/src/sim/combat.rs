use rand::Rng;
use crate::sim::{Actor, Attack, Action};
use crate::events::BattleEvent;
use crate::anatomy::part::Part;

pub struct CombatResolver;

impl CombatResolver {
    /// Resolve an attack action
    pub fn resolve_attack<R: Rng>(
        rng: &mut R,
        attacker: &mut Actor,
        defender: &mut Actor,
        attack: &Attack,
    ) -> Vec<BattleEvent> {
        let mut events = Vec::new();
        
        // Check stamina
        if attacker.stamina < attack.stamina_cost {
            // Not enough stamina - attack fails
            return events;
        }
        
        // Consume stamina
        attacker.stamina = attacker.stamina.saturating_sub(attack.stamina_cost);
        
        // Hit roll
        let hit_roll = rng.gen_range(0..100);
        if hit_roll >= attack.accuracy {
            // Miss!
            events.push(BattleEvent::StatusChange {
                actor_id: attacker.id,
                status: "miss".to_string(),
                active: true,
            });
            return events;
        }
        
        // Select target part based on hit_weight
        if defender.parts.is_empty() {
            // No parts to target (shouldn't happen)
            return events;
        }
        
        let target_part = Self::select_target_part(rng, &defender.parts);
        let target_part_id = target_part.part_id.clone();
        
        // Calculate damage
        let base_damage = attack.damage.base_damage;
        let armor = target_part.armor;
        let penetration = attack.damage.armor_penetration;
        
        let effective_armor = (armor - penetration).max(0);
        let final_damage = (base_damage - effective_armor).max(1);
        
        // Morale drop from taking damage (before applying damage to parts)
        let morale_loss = (final_damage as u32 / 3).max(1);
        defender.reduce_morale(morale_loss);
        
        // Apply damage to part
        let part_destroyed = if let Some(part) = defender.parts.iter_mut().find(|p| p.part_id == target_part_id) {
            part.hp -= final_damage;
            
            events.push(BattleEvent::Hit {
                attacker_id: attacker.id,
                defender_id: defender.id,
                part_id: part.part_id.clone(),
                damage: final_damage as u32,
                attack_name: attack.display_name.clone(),
            });
            
            part.hp <= 0
        } else {
            false
        };
        
        // Handle part destruction
        if part_destroyed {
            // Check if part should bleed
            let should_sever = attack.damage.is_sharp;
            
            if should_sever {
                events.push(BattleEvent::Sever {
                    actor_id: defender.id,
                    part_id: target_part_id.clone(),
                    gib_char: '*',
                    x: defender.x,
                    y: defender.y,
                });
                
                // Severe morale drop from losing a body part
                defender.reduce_morale(15);
            }
            
            // Remove the part and apply effects
            defender.remove_part(&target_part_id);
            
            // Check for death
            if !defender.is_alive() {
                events.push(BattleEvent::Death {
                    actor_id: defender.id,
                    x: defender.x,
                    y: defender.y,
                });
            }
        } else {
            // Check for bleeding
            if attack.damage.bleed_chance > 0.0 {
                let bleed_roll: f32 = rng.gen();
                if bleed_roll < attack.damage.bleed_chance {
                    // Increase bleed rate on the part
                    if let Some(part) = defender.parts.iter_mut().find(|p| p.part_id == target_part_id) {
                        part.bleed_rate += 1;
                        
                        events.push(BattleEvent::Bleed {
                            actor_id: defender.id,
                            amount: 1,
                        });
                    }
                }
            }
        }
        
        events
    }
    
    /// Select a target part based on hit_weight distribution
    fn select_target_part<'a, R: Rng>(rng: &mut R, parts: &'a [Part]) -> &'a Part {
        let total_weight: u32 = parts.iter().map(|p| p.hit_weight).sum();
        let mut roll = rng.gen_range(0..total_weight);
        
        for part in parts {
            if roll < part.hit_weight {
                return part;
            }
            roll -= part.hit_weight;
        }
        
        // Fallback (shouldn't happen)
        &parts[0]
    }
    
    /// Apply bleeding damage to an actor
    pub fn apply_bleeding(actor: &mut Actor) -> Vec<BattleEvent> {
        let mut events = Vec::new();
        let total_bleed = actor.get_total_bleed_rate();
        
        if total_bleed > 0 {
            let bleed_damage = total_bleed;
            actor.hp -= bleed_damage as i32;
            
            events.push(BattleEvent::Bleed {
                actor_id: actor.id,
                amount: bleed_damage,
            });
            
            if actor.hp <= 0 {
                actor.hp = 0;
                actor.alive = false;
                events.push(BattleEvent::Death {
                    actor_id: actor.id,
                    x: actor.x,
                    y: actor.y,
                });
            }
        }
        
        events
    }
    
    /// Calculate distance between two positions
    pub fn distance(x1: i32, y1: i32, x2: i32, y2: i32) -> f32 {
        let dx = (x2 - x1) as f32;
        let dy = (y2 - y1) as f32;
        (dx * dx + dy * dy).sqrt()
    }
    
    /// Check if an attack is in range
    pub fn is_in_range(attacker: &Actor, defender: &Actor, range: f32) -> bool {
        Self::distance(attacker.x, attacker.y, defender.x, defender.y) <= range
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use rand::rngs::SmallRng;
    use rand_seeder::Seeder;
    use crate::anatomy::part::Part;
    
    fn create_test_actor(id: u32) -> Actor {
        let mut actor = Actor::new(id, "test".to_string(), 'T', 0, 0, 0);
        actor.hp = 50;
        actor.max_hp = 50;
        actor.stamina = 100;
        actor.max_stamina = 100;
        
        // Add some parts
        actor.parts.push(Part {
            part_id: "torso".to_string(),
            display_name: "Torso".to_string(),
            count: 1,
            attachments: vec![],
            tags: vec!["vital".to_string()],
            hp: 20,
            max_hp: 20,
            armor: 2,
            bleed_rate: 0,
            hit_weight: 10,
        });
        
        actor.parts.push(Part {
            part_id: "head".to_string(),
            display_name: "Head".to_string(),
            count: 1,
            attachments: vec!["torso".to_string()],
            tags: vec!["brain".to_string(), "vital".to_string()],
            hp: 15,
            max_hp: 15,
            armor: 0,
            bleed_rate: 0,
            hit_weight: 5,
        });
        
        actor
    }
    
    fn create_test_attack() -> Attack {
        use crate::sim::attack::{AttackType, DamageProfile};
        
        Attack {
            attack_id: "test_attack".to_string(),
            display_name: "Test Attack".to_string(),
            attack_type: AttackType::Scratch,
            damage: DamageProfile {
                base_damage: 10,
                armor_penetration: 1,
                bleed_chance: 0.3,
                is_sharp: true,
                is_blunt: false,
            },
            accuracy: 70,
            stamina_cost: 10,
        }
    }
    
    #[test]
    fn test_resolve_attack_hit() {
        let mut rng: SmallRng = Seeder::from(12345u64).make_rng();
        let mut attacker = create_test_actor(1);
        let mut defender = create_test_actor(2);
        let attack = create_test_attack();
        
        let events = CombatResolver::resolve_attack(&mut rng, &mut attacker, &mut defender, &attack);
        
        // Should have consumed stamina
        assert!(attacker.stamina < 100);
        
        // Should have events
        assert!(!events.is_empty());
    }
    
    #[test]
    fn test_bleeding_damage() {
        let mut actor = create_test_actor(1);
        actor.parts[0].bleed_rate = 2;
        actor.parts[1].bleed_rate = 1;
        
        let initial_hp = actor.hp;
        let events = CombatResolver::apply_bleeding(&mut actor);
        
        assert_eq!(actor.hp, initial_hp - 3);
        assert!(!events.is_empty());
    }
    
    #[test]
    fn test_distance_calculation() {
        let dist = CombatResolver::distance(0, 0, 3, 4);
        assert_eq!(dist, 5.0);
    }
}
