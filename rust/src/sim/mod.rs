pub mod battle;
pub mod actor;
pub mod grid;
pub mod attack;
pub mod action;
pub mod combat;
pub mod ai;

#[cfg(test)]
mod tests;

pub use battle::Battle;
pub use actor::Actor;
pub use grid::Grid;
pub use attack::{Attack, AttackType, DamageProfile};
pub use action::{Action, CombatAction};
pub use combat::CombatResolver;
pub use ai::SimpleAI;
