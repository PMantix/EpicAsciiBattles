use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum Tag {
    // Anatomy
    Head,
    Neck,
    Torso,
    Wing,
    Leg,
    Foot,
    Claw,
    Beak,
    Tail,
    
    // Materials/Covering
    Feathered,
    Scaled,
    Furred,
    Armored,
    
    // Capabilities
    Locomotion,
    Flight,
    Grasp,
    BiteWeapon,
    ScratchWeapon,
    PeckWeapon,
    
    // Vital
    Vital,
    Brain,
    Heart,
    Lung,
    
    // Special
    PoisonGland,
    Horn,
    Spit,
    
    // Damage types
    Sharp,
    Blunt,
}

impl Tag {
    pub fn from_string(s: &str) -> Option<Self> {
        match s.to_lowercase().as_str() {
            "head" => Some(Tag::Head),
            "neck" => Some(Tag::Neck),
            "torso" => Some(Tag::Torso),
            "wing" => Some(Tag::Wing),
            "leg" => Some(Tag::Leg),
            "foot" => Some(Tag::Foot),
            "claw" => Some(Tag::Claw),
            "beak" => Some(Tag::Beak),
            "tail" => Some(Tag::Tail),
            "feathered" => Some(Tag::Feathered),
            "scaled" => Some(Tag::Scaled),
            "furred" => Some(Tag::Furred),
            "armored" => Some(Tag::Armored),
            "locomotion" => Some(Tag::Locomotion),
            "flight" => Some(Tag::Flight),
            "grasp" => Some(Tag::Grasp),
            "biteweapon" => Some(Tag::BiteWeapon),
            "scratchweapon" => Some(Tag::ScratchWeapon),
            "peckweapon" => Some(Tag::PeckWeapon),
            "vital" => Some(Tag::Vital),
            "brain" => Some(Tag::Brain),
            "heart" => Some(Tag::Heart),
            "lung" => Some(Tag::Lung),
            "poisongland" => Some(Tag::PoisonGland),
            "horn" => Some(Tag::Horn),
            "spit" => Some(Tag::Spit),
            "sharp" => Some(Tag::Sharp),
            "blunt" => Some(Tag::Blunt),
            _ => None,
        }
    }
}
