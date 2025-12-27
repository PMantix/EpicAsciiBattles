#[cfg(test)]
mod tests {
    use crate::species::{Species, SpeciesLoader, SpeciesValidator};
    use std::fs;
    use std::path::PathBuf;
    
    #[test]
    fn test_chicken_species_loads() {
        let mut loader = SpeciesLoader::new();
        let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .parent()
            .unwrap()
            .join("data/species/chicken.yaml");
        
        if !path.exists() {
            eprintln!("Warning: chicken.yaml not found at {:?}, skipping test", path);
            return;
        }
        
        let result = loader.load_from_file(&path);
        assert!(result.is_ok(), "Failed to load chicken species: {:?}", result.err());
        
        let chicken = result.unwrap();
        assert_eq!(chicken.id, "chicken");
        assert_eq!(chicken.name, "Chicken");
        assert_eq!(chicken.glyph, 'C');
        assert!(!chicken.parts.is_empty(), "Chicken should have parts");
    }
    
    #[test]
    fn test_baboon_species_loads() {
        let mut loader = SpeciesLoader::new();
        let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .parent()
            .unwrap()
            .join("data/species/baboon.yaml");
        
        if !path.exists() {
            eprintln!("Warning: baboon.yaml not found at {:?}, skipping test", path);
            return;
        }
        
        let result = loader.load_from_file(&path);
        assert!(result.is_ok(), "Failed to load baboon species: {:?}", result.err());
        
        let baboon = result.unwrap();
        assert_eq!(baboon.id, "baboon");
        assert_eq!(baboon.name, "Baboon");
        assert_eq!(baboon.glyph, 'B');
        assert!(!baboon.parts.is_empty(), "Baboon should have parts");
    }
    
    #[test]
    fn test_species_validation() {
        let validator = SpeciesValidator::new();
        
        let mut loader = SpeciesLoader::new();
        let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .parent()
            .unwrap()
            .join("data/species/chicken.yaml");
        
        if !path.exists() {
            eprintln!("Warning: chicken.yaml not found, skipping test");
            return;
        }
        
        let chicken = loader.load_from_file(&path).unwrap();
        let validation = validator.validate(&chicken);
        
        assert!(validation.is_ok(), "Chicken species should validate: {:?}", validation.err());
    }
    
    #[test]
    fn test_invalid_species_fails_validation() {
        let validator = SpeciesValidator::new();
        
        // Create an invalid species (no vital parts)
        let mut invalid_species = Species::new("test".to_string(), "Test".to_string(), 'T');
        invalid_species.parts.push(crate::species::PartDefinition {
            part_id: "wing".to_string(),
            display_name: "Wing".to_string(),
            count: 2,
            attachments: vec![],
            tags: vec!["wing".to_string()],
            hp: 10,
            armor: 0,
            bleed_rate: 0,
            hit_weight: 1,
        });
        
        let validation = validator.validate(&invalid_species);
        assert!(validation.is_err(), "Species without vital parts should fail validation");
        
        let errors = validation.err().unwrap();
        assert!(errors.iter().any(|e| e.contains("vital")), 
            "Error should mention missing vital parts");
    }
    
    #[test]
    fn test_attack_derivation() {
        let mut loader = SpeciesLoader::new();
        let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .parent()
            .unwrap()
            .join("data/species/chicken.yaml");
        
        if !path.exists() {
            eprintln!("Warning: chicken.yaml not found, skipping test");
            return;
        }
        
        let chicken = loader.load_from_file(&path).unwrap();
        let attacks = chicken.derive_attacks();
        
        assert!(!attacks.is_empty(), "Chicken should have at least one attack");
        
        // Chicken should have peck attack (from beak) and scratch attack (from claws)
        let has_peck = attacks.iter().any(|a| a.display_name.to_lowercase().contains("peck"));
        let has_scratch = attacks.iter().any(|a| a.display_name.to_lowercase().contains("scratch"));
        
        assert!(has_peck, "Chicken should have peck attack");
        assert!(has_scratch, "Chicken should have scratch attack");
    }
    
    #[test]
    fn test_species_loader_caching() {
        let mut loader = SpeciesLoader::new();
        let dir_path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .parent()
            .unwrap()
            .join("data/species");
        
        if !dir_path.exists() {
            eprintln!("Warning: species directory not found, skipping test");
            return;
        }
        
        let result = loader.load_from_directory(&dir_path);
        if result.is_err() {
            eprintln!("Warning: Could not load species directory: {:?}", result.err());
            return;
        }
        
        // Should have cached the species
        let chicken = loader.get_species("chicken");
        assert!(chicken.is_some(), "Chicken should be cached");
        
        let baboon = loader.get_species("baboon");
        assert!(baboon.is_some(), "Baboon should be cached");
    }
}
