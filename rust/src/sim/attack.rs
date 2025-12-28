use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Attack {
    pub attack_id: String,
    pub display_name: String,
    pub attack_type: AttackType,
    pub damage: DamageProfile,
    pub accuracy: u32,
    pub stamina_cost: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum AttackType {
    Peck,
    Bite,
    Scratch,
    Sting,
    Ram,
    Kick,
    Bash,
    Gore,
    Claw,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DamageProfile {
    pub base_damage: i32,
    pub armor_penetration: i32,
    pub bleed_chance: f32,
    pub is_sharp: bool,
    pub is_blunt: bool,
}

impl Attack {
    /// Derive an attack from a part's tags
    pub fn derive_from_tags(
        part_id: &str,
        part_name: &str,
        tags: &[String],
        hp: i32,
    ) -> Option<Self> {
        let has_peck = tags.iter().any(|t| t == "peck_weapon");
        let has_bite = tags.iter().any(|t| t == "bite_weapon");
        let has_scratch = tags.iter().any(|t| t == "scratch_weapon");
        let has_sting = tags.iter().any(|t| t == "sting_weapon");
        let has_bash = tags.iter().any(|t| t == "bash_weapon");
        let has_gore = tags.iter().any(|t| t == "gore_weapon");
        let has_claw = tags.iter().any(|t| t == "claw_weapon");
        let has_kick = tags.iter().any(|t| t == "kick_weapon");
        
        let has_sharp = tags.iter().any(|t| t == "sharp");
        let has_blunt = tags.iter().any(|t| t == "blunt");
        let has_strong = tags.iter().any(|t| t == "strong");
        let has_crushing = tags.iter().any(|t| t == "crushing");
        
        let (attack_type, base_name) = if has_peck {
            (AttackType::Peck, "Peck")
        } else if has_bite {
            (AttackType::Bite, "Bite")
        } else if has_scratch {
            (AttackType::Scratch, "Scratch")
        } else if has_claw {
            (AttackType::Claw, "Claw")
        } else if has_sting {
            (AttackType::Sting, "Sting")
        } else if has_bash {
            (AttackType::Bash, "Bash")
        } else if has_gore {
            (AttackType::Gore, "Gore")
        } else if has_kick {
            (AttackType::Kick, "Kick")
        } else {
            return None; // Not a weapon part
        };
        
        // Calculate damage based on part HP and tags
        let base_damage = match attack_type {
            AttackType::Peck => (hp / 4).max(2),
            AttackType::Bite => (hp / 3).max(3),
            AttackType::Scratch => (hp / 5).max(1),
            AttackType::Claw => (hp / 4).max(2),
            AttackType::Sting => (hp / 4).max(2),
            AttackType::Bash => (hp / 3).max(4),
            AttackType::Gore => (hp / 3).max(5),
            AttackType::Kick => (hp / 4).max(3),
            _ => hp / 4,
        };
        
        let armor_penetration = if has_sharp {
            3
        } else if has_blunt || has_crushing {
            2
        } else {
            0
        };
        
        let bleed_chance = if has_sharp {
            0.3
        } else if matches!(attack_type, AttackType::Bite | AttackType::Claw | AttackType::Gore) {
            0.2
        } else {
            0.05
        };
        
        let accuracy = match attack_type {
            AttackType::Peck => 75,
            AttackType::Bite => 65,
            AttackType::Scratch => 70,
            AttackType::Claw => 70,
            AttackType::Sting => 60,
            AttackType::Bash => 75,
            AttackType::Gore => 60,
            AttackType::Kick => 65,
            _ => 70,
        };
        
        let stamina_cost = if has_strong {
            15
        } else {
            match attack_type {
                AttackType::Bite => 12,
                AttackType::Bash => 14,
                AttackType::Gore => 14,
                AttackType::Kick => 12,
                AttackType::Peck => 8,
                AttackType::Scratch => 6,
                AttackType::Claw => 8,
                AttackType::Sting => 10,
                _ => 10,
            }
        };
        
        Some(Attack {
            attack_id: format!("{}_attack", part_id),
            display_name: format!("{} with {}", base_name, part_name),
            attack_type,
            damage: DamageProfile {
                base_damage,
                armor_penetration,
                bleed_chance,
                is_sharp: has_sharp,
                is_blunt: has_blunt || has_crushing,
            },
            accuracy,
            stamina_cost,
        })
    }
}

impl AttackType {
    pub fn as_str(&self) -> &str {
        match self {
            AttackType::Peck => "peck",
            AttackType::Bite => "bite",
            AttackType::Scratch => "scratch",
            AttackType::Claw => "claw",
            AttackType::Sting => "sting",
            AttackType::Ram => "ram",
            AttackType::Kick => "kick",
            AttackType::Bash => "bash",
            AttackType::Gore => "gore",
        }
    }
}

impl Attack {
    /// Get a descriptive string for the attack
    pub fn describe(&self) -> String {
        format!(
            "{} (dmg: {}, acc: {}%, cost: {})",
            self.display_name,
            self.damage.base_damage,
            self.accuracy,
            self.stamina_cost
        )
    }
}
