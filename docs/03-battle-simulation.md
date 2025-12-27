# Battle Simulation

## Simulation requirements
- **Deterministic** given a `seed` + matchup definition.
- **Step-based** time: fixed tick `dt` (e.g., 100 ms per tick) for repeatability.
- Produces an **event stream** for rendering (hits, gibs, tint changes, deaths).

## World model
- Grid arena with size chosen per matchup (scales with actor count; configurable).
- Terrain/props can provide tactical value (cover/line-blocking) and may be destructible where it makes sense.
- Biome tile sets (desert/grass/etc.) plus constructed features (walls/boulders).
- Two teams spawn in opposing zones.

## Actor model (per combatant)
- Position, facing.
- Stats: mass, speed, stamina, pain tolerance, morale.
- Anatomy: parts graph (see `04-combatant-modeling.md`).
- Capabilities: attacks derived from anatomy + tags.
- Status effects: bleeding, vomiting, stunned, limping, panic/fleeing, etc.
- Individual variation: each actor is generated from a species template plus per-individual rolls (injuries, traits, rare “standout” individuals).

## Turn/tick order (per tick)
1. Update statuses (bleed over time, vomit, recover stun).
2. Per actor:
   - If incapacitated/dead → skip.
   - Choose intent (target selection).
   - Move (pathfind short range; prototype: greedy + local avoidance).
   - If in range → attack.
3. Resolve queued attacks (hit rolls, damage, part effects).
4. Emit events.

## Target selection
- Prefer nearest enemy.
- If “fleeing” morale state: prefer moving away.

## Morale + special states
- Morale is required (panic/fleeing).
- Rare special state: berserk/bloodlust (infrequent; feels special).

## Attacks
Each attack has:
- `name`
- `rangeCells`
- `windupTicks`
- `cooldownTicks`
- `toHit` (vs defender evasion)
- `damageProfile` (pierce/slash/blunt)
- `targeting` (random part weighted by exposed parts)

Attacks are **derived** from anatomy tags (e.g., beak → peck; claws → scratch).

## Damage + anatomy
- Damage is applied to a **target part**.
- Parts have:
  - `maxHP`, `currentHP`
  - `armor` / resist multipliers
  - `functions` (e.g., “flight”, “grasp”, “locomotion”) that can be disabled
- On threshold events:
  - `wounded` (reduced function)
  - `severed` (detaches, spawns gib glyph)
  - `destroyed`

## Death / incapacitation
- Death if: core parts destroyed (e.g., head or “brain”), or blood loss beyond threshold.
- Incapacitation if: cannot move + cannot attack.

## Morale (prototype-simple)
- Morale score starts at `100`.
- Drops when:
  - losing parts, heavy pain, allies dying nearby.
- Below threshold → “fleeing” behavior.

## Battle duration
- No hard time limit (prototype), but target typical battles at ~60 seconds or less.
- Add a fatigue soft-cap to prevent runaway fights:
  - Fatigue increases over time for all actors.
  - As fatigue rises, action costs rise and recovery drops (or effective speed drops).
  - After a threshold duration, fatigue accumulation accelerates.
- Add playtest checkpoints to reassess pacing and tune fatigue.

## Acceptance criteria (MVP)
- Deterministic replay from same seed.
- Visible movement + melee combat.
- At least 2 derived attacks (peck/scratch) and one status (bleeding).
- Disabling a locomotion part affects movement.
