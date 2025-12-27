#[cfg(test)]
mod integration_tests {
    use crate::sim::battle::Battle;

    #[test]
    fn test_chicken_vs_baboon_simulation() {
        // Create a battle with seed for reproducibility
        let mut battle = Battle::new(42);
        
        // Team A: 3 chickens
        let team_a_json = r#"[
            {"species_id": "chicken", "variation": null},
            {"species_id": "chicken", "variation": null},
            {"species_id": "chicken", "variation": null}
        ]"#;
        
        // Team B: 1 baboon
        let team_b_json = r#"[
            {"species_id": "baboon", "variation": null}
        ]"#;
        
        // Initialize battle with species from data directory
        let result = battle.init_with_species("../data/species", team_a_json, team_b_json);
        assert!(result.is_ok(), "Failed to initialize battle: {:?}", result);
        
        // Run simulation for up to 1000 ticks
        let mut tick_count = 0;
        while !battle.is_finished() && tick_count < 1000 {
            let events = battle.tick();
            tick_count += 1;
            
            // Print key events to verify combat is happening
            if tick_count <= 10 {
                for event in events {
                    match event {
                        crate::events::BattleEvent::Hit { attacker_id, defender_id, damage, .. } => {
                            println!("Tick {}: Actor {} hit Actor {} for {} damage", 
                                tick_count, attacker_id, defender_id, damage);
                        }
                        crate::events::BattleEvent::Death { actor_id, .. } => {
                            println!("Tick {}: Actor {} died", tick_count, actor_id);
                        }
                        crate::events::BattleEvent::Sever { actor_id, part_id, .. } => {
                            println!("Tick {}: Actor {} lost {}", tick_count, actor_id, part_id);
                        }
                        _ => {}
                    }
                }
            }
        }
        
        // Verify battle completed
        assert!(battle.is_finished(), "Battle did not finish within 1000 ticks");
        assert!(battle.get_winner() >= 0, "Battle has no winner");
        
        println!("Battle finished in {} ticks. Winner: Team {}", 
            tick_count, 
            if battle.get_winner() == 0 { "A (Chickens)" } else { "B (Baboon)" });
    }
}
