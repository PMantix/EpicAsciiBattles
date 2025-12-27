mod species;
pub mod loader;
pub mod validator;

#[cfg(test)]
mod tests;

pub use species::{Species, BaseStats, PartDefinition};
pub use loader::SpeciesLoader;
pub use validator::SpeciesValidator;
