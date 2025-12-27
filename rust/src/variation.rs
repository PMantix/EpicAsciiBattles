use rand::Rng;

/// Generator for individual variation in combatants
pub struct VariationGenerator;

impl VariationGenerator {
    /// Generate stat variation for a combatant
    /// Returns multipliers for HP, speed, and stamina
    /// Typical range: 0.8 - 1.2 (±20%)
    /// Rare standouts (~1/1000): 1.3 - 1.5 (30-50% boost)
    pub fn generate_stat_variation<R: Rng>(rng: &mut R) -> (f32, f32, f32) {
        // Roll for rare standout individual (0.1% chance)
        if rng.gen::<f32>() < 0.001 {
            return Self::generate_standout(rng);
        }
        
        // Normal variation: ±20%
        let hp_mult = rng.gen_range(0.8..1.2);
        let speed_mult = rng.gen_range(0.8..1.2);
        let stamina_mult = rng.gen_range(0.8..1.2);
        
        (hp_mult, speed_mult, stamina_mult)
    }
    
    /// Generate standout individual with exceptional stats
    fn generate_standout<R: Rng>(rng: &mut R) -> (f32, f32, f32) {
        // Standout individuals get 30-50% boost in 1-2 stats
        let boost_count = rng.gen_range(1..=2);
        
        let mut hp_mult = 1.0;
        let mut speed_mult = 1.0;
        let mut stamina_mult = 1.0;
        
        for _ in 0..boost_count {
            let boost = rng.gen_range(1.3..1.5);
            match rng.gen_range(0..3) {
                0 => hp_mult = boost,
                1 => speed_mult = boost,
                2 => stamina_mult = boost,
                _ => unreachable!(),
            }
        }
        
        (hp_mult, speed_mult, stamina_mult)
    }
    
    /// Generate pre-existing injuries
    /// ~10% chance of having 1-2 minor injuries
    pub fn generate_injuries<R: Rng>(rng: &mut R, part_ids: &[String]) -> Vec<(String, i32)> {
        let mut injuries = Vec::new();
        
        // 10% chance of injuries
        if rng.gen::<f32>() < 0.1 && !part_ids.is_empty() {
            let injury_count = rng.gen_range(1..=2);
            
            for _ in 0..injury_count {
                // Pick a random non-vital part
                if let Some(part_id) = part_ids.iter().nth(rng.gen_range(0..part_ids.len())) {
                    // Minor injury: 20-40% of part HP
                    let damage_percent = rng.gen_range(0.2..0.4);
                    let damage = (10.0 * damage_percent) as i32; // Assuming avg part HP ~10
                    
                    injuries.push((part_id.clone(), damage));
                }
            }
        }
        
        injuries
    }
    
    /// Check if variation makes this a "named" standout individual
    pub fn is_standout(hp_mult: f32, speed_mult: f32, stamina_mult: f32) -> bool {
        hp_mult > 1.25 || speed_mult > 1.25 || stamina_mult > 1.25
    }
    
    /// Generate a name suffix for standout individuals
    pub fn generate_standout_name<R: Rng>(rng: &mut R) -> String {
        let prefixes = [
            "the Mighty", "the Swift", "the Relentless", "the Fierce",
            "the Unstoppable", "the Legendary", "the Great", "the Terrible",
            "the Bold", "the Brave", "the Cunning", "the Savage"
        ];
        
        prefixes[rng.gen_range(0..prefixes.len())].to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use rand::rngs::SmallRng;
    use rand_seeder::Seeder;
    
    #[test]
    fn test_stat_variation_range() {
        let mut rng: SmallRng = Seeder::from(12345u64).make_rng();
        
        // Test many generations to ensure range
        for _ in 0..100 {
            let (hp, speed, stamina) = VariationGenerator::generate_stat_variation(&mut rng);
            assert!(hp >= 0.7 && hp <= 1.6);
            assert!(speed >= 0.7 && speed <= 1.6);
            assert!(stamina >= 0.7 && stamina <= 1.6);
        }
    }
    
    #[test]
    fn test_standout_detection() {
        assert!(!VariationGenerator::is_standout(1.0, 1.0, 1.0));
        assert!(!VariationGenerator::is_standout(1.2, 1.1, 1.0));
        assert!(VariationGenerator::is_standout(1.3, 1.0, 1.0));
        assert!(VariationGenerator::is_standout(1.0, 1.4, 1.0));
    }
    
    #[test]
    fn test_injuries_generation() {
        let mut rng: SmallRng = Seeder::from(99999u64).make_rng();
        let part_ids = vec!["leg".to_string(), "wing".to_string(), "tail".to_string()];
        
        // Test many generations
        let mut had_injuries = false;
        for _ in 0..50 {
            let injuries = VariationGenerator::generate_injuries(&mut rng, &part_ids);
            if !injuries.is_empty() {
                had_injuries = true;
                assert!(injuries.len() <= 2);
                for (_, damage) in &injuries {
                    assert!(*damage > 0);
                }
            }
        }
        
        // Should have at least one injury in 50 tries (10% chance each)
        assert!(had_injuries);
    }
}
