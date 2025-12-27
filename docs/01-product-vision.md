# Product Vision

## One-liner
A watchable ASCII arena battle game where the player predicts the winner of bizarre matchups and watches a deterministic “Dwarf Fortress–style” simulation unfold in animated roguelike ASCII spectacle.

## High-level premise
- The player does **not** control units.
- Each round presents a matchup (e.g., “5 baboons vs 15 chickens”).
- Player chooses a side, then the battle sim plays out.
- Correct picks award points and advance the run; wrong pick ends the run.
- Runs end in a score summary + local leaderboard.

## Experience pillars
1. **Readable chaos**: the battle is always understandable even when it’s wild. 
2. **Delightful ASCII VFX**: damage, gibs, blood/puke tinting, quick pop-off glyphs.
3. **Surprising simulation depth**: simple visuals, rich underlying anatomy & damage.
4. **Fast rounds**: short setup, quick resolution, easy “one more run”.

## Target feel
- “Roguelike spectator sport” meets “procedural creature simulation”.
- Serious/neutral tone despite ASCII presentation.
- Intense, abstract ASCII gore by default with a first-run visible **gore intensity** control (can dial down).
- The combat log is a core feature: vivid, flavorful descriptions of battle events.

## Non-goals (prototype)
- No multiplayer.
- No live ops.
- No user-created mods (but authoring should be internal-data-driven).
- No complex meta-economy; keep unlocks simple.

## Platform
- iOS first (SwiftUI-based UI), iPhone + iPad.
- Supports portrait + landscape and auto-rotates.
- Rendering approach is documented in `05-ascii-rendering-vfx.md`.

## Content/IP constraints
- Include real animals, fantasy creatures, humans, and sci‑fi archetypes.
- Do **not** use real-world named individuals or protected character names.

## Primary content focus
- Primarily animals + fantasy creatures.
- Occasional generic humans (e.g., “knight”, “peasant”) are allowed.
