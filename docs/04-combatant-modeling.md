# Combatant Modeling (Anatomy + Tags)

This is the “robust and systematic” authoring system: simple data definitions produce rich combatants.

## Goals
- Add new species by authoring **data**, not code.
- Derive attacks, vulnerabilities, and behaviors from anatomy.
- Support part loss affecting capabilities (flight, movement, grasp, etc.).

## Core concept
A combatant is defined by:
- **Identity**: `id`, `displayName`, `glyph`, `glyphColor`.
- **Body plan**: a directed graph of parts (supports multi-attachment).
- **Tags**: semantic labels that drive rules.
- **Base stats**: mass, speed, stamina, aggression.

Additionally, each **individual** combatant instance is generated from the species definition plus per-instance variation (traits, pre-existing injuries, rare standout variants).

## Part schema (data)
Each part has:
- `partId` (unique within species)
- `displayName`
- `count` (for repeated parts)
- `attachments` (one or more attachment points; supports multi-attachment)
- `tags` (examples below)
- `hp`, `armor`, `bleedRate`
- `hitWeight` (likelihood to be targeted)
- `functions` (capability toggles)
- `attacksProvided` (optional override; usually derived from tags)

## Tag system
Tags are composable and drive derived behavior.

### Examples (non-exhaustive)
- Anatomy: `head`, `neck`, `torso`, `wing`, `leg`, `foot`, `claw`, `beak`, `tail`
- Materials/covering: `feathered`, `scaled`, `furred`, `armored`
- Capabilities: `locomotion`, `flight`, `grasp`, `biteWeapon`, `scratchWeapon`, `peckWeapon`
- Vital: `vital`, `brain`, `heart`, `lung`
- Special: `poisonGland`, `horn`, `spit`

## Deriving attacks from tags
Mapping table (prototype defaults):
- `peckWeapon` → attack `peck` (pierce, short range)
- `scratchWeapon` → attack `scratch` (slash, short range)
- `biteWeapon` → attack `bite` (pierce/slash mix)

Damage tuning can scale with:
- part mass contribution
- sharpness tag (`sharp`, `blunt`)

## Deriving effects from part loss
- Lost `wing` with `flight` → cannot fly; movement speed reduced if species expects flight.
- Lost `leg` with `locomotion` → speed reduced; at 0 locomotion parts → immobile.
- Lost `head` with `brain`/`vital` → death.

## Species definition example (chicken)
Prototype YAML-like example:

```yaml
id: chicken
name: Chicken
glyph: "c"
color: "yellow"
baseStats:
  massKg: 2
  speed: 6
  stamina: 50
parts:
  - partId: torso
    displayName: Body
    tags: [torso]
    hp: 30
    armor: 0
    bleedRate: 1
    hitWeight: 5
  - partId: head
    displayName: Head
    attachments: [torso]
    tags: [head, vital, brain]
    hp: 10
    armor: 0
    bleedRate: 2
    hitWeight: 2
  - partId: beak
    displayName: Beak
    attachments: [head]
    tags: [beak, peckWeapon, sharp]
    hp: 4
    armor: 0
    bleedRate: 0
    hitWeight: 1
  - partId: wing
    displayName: Wing
    attachments: [torso]
    count: 2
    tags: [wing, flight, feathered]
    hp: 8
    armor: 0
    bleedRate: 1
    hitWeight: 2
  - partId: leg
    displayName: Leg
    attachments: [torso]
    count: 2
    tags: [leg, locomotion, scaled]
    hp: 10
    armor: 0
    bleedRate: 2
    hitWeight: 3
  - partId: claw
    displayName: Claw
    attachments: [leg]
    count: 6
    tags: [claw, scratchWeapon, sharp]
    hp: 2
    armor: 0
    bleedRate: 0
    hitWeight: 1
```

## Content pipeline (prototype)
- Store species defs as YAML (human-friendly) converted/validated into runtime models.
- Validate on launch: graph integrity, required tags, unique IDs.
- Provide “unit test” fixtures for 2–3 species.

## Instance generation (variation)
- Species data defines distributions/ranges (e.g., mass variance, toughness, aggression).
- Optional “spawn modifiers” per matchup: pre-existing injuries, elite individuals.
- Keep determinism: all generation uses the seeded RNG.

### Standout individuals
- Rare “standout/demigod-tier” variants can exist.
- Target rarity: ~`1 / 1000` individuals.

## Acceptance criteria (MVP)
- Adding a new species requires editing only a data file.
- At least chicken + baboon authored this way.
- Attacks are derived from tags (no per-species hardcoding).
- Losing a tagged part changes capabilities.
- Multi-attachment is supported (e.g., multi-headed creatures).
