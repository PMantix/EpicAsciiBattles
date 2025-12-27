use crate::species::Species;
use std::collections::HashMap;
use std::fs;
use std::path::Path;

#[derive(Debug)]
pub struct SpeciesLoader {
    species_cache: HashMap<String, Species>,
}

impl SpeciesLoader {
    pub fn new() -> Self {
        Self {
            species_cache: HashMap::new(),
        }
    }
    
    /// Load a species from a YAML file
    pub fn load_from_file<P: AsRef<Path>>(&mut self, path: P) -> Result<Species, String> {
        let content = fs::read_to_string(&path)
            .map_err(|e| format!("Failed to read species file: {}", e))?;
        
        let species: Species = serde_yaml::from_str(&content)
            .map_err(|e| format!("Failed to parse species YAML: {}", e))?;
        
        // Cache the loaded species
        self.species_cache.insert(species.id.clone(), species.clone());
        
        Ok(species)
    }
    
    /// Load all species from a directory
    pub fn load_from_directory<P: AsRef<Path>>(&mut self, dir_path: P) -> Result<Vec<Species>, String> {
        let entries = fs::read_dir(&dir_path)
            .map_err(|e| format!("Failed to read species directory: {}", e))?;
        
        let mut species_list = Vec::new();
        
        for entry in entries {
            let entry = entry.map_err(|e| format!("Failed to read directory entry: {}", e))?;
            let path = entry.path();
            
            if path.extension().and_then(|s| s.to_str()) == Some("yaml") 
                || path.extension().and_then(|s| s.to_str()) == Some("yml") {
                match self.load_from_file(&path) {
                    Ok(species) => species_list.push(species),
                    Err(e) => eprintln!("Warning: Failed to load {}: {}", path.display(), e),
                }
            }
        }
        
        if species_list.is_empty() {
            return Err(format!("No valid species files found in {}", dir_path.as_ref().display()));
        }
        
        Ok(species_list)
    }
    
    /// Get a species from the cache by ID
    pub fn get_species(&self, id: &str) -> Option<&Species> {
        self.species_cache.get(id)
    }
    
    /// Get all loaded species IDs
    pub fn get_loaded_ids(&self) -> Vec<String> {
        self.species_cache.keys().cloned().collect()
    }
    
    /// Clear the species cache
    pub fn clear_cache(&mut self) {
        self.species_cache.clear();
    }
}

impl Default for SpeciesLoader {
    fn default() -> Self {
        Self::new()
    }
}

