# MVP Scope + Milestones

## MVP definition
- Full run loop (offer → pick → battle → result → next/lose → summary → leaderboard).
- Small initial creature set (data-driven; no per-creature hardcoding).
- Deterministic battle sim with **deep anatomy**, part loss, ailments.
- Morale/panic/fleeing + rare berserk.
- ASCII renderer with hit flash + blood tint + gib particles.
- Scrollable combat log + recent event ticker.
- No special playback controls.

## Suggested milestones
1. **Scaffold app + navigation**: Home, Round Offer, Battle shell.
2. **Core sim v0**: grid, movement, melee, win condition.
3. **Deep anatomy**: organs + bleeding-out + incapacitation.
4. **Morale system**: panic/fleeing + rare berserk.
5. **Content pipeline**: YAML species + validation + per-individual generation.
6. **Combat log**: event stream → flavorful prose + scrollback.
7. **Arena v0**: scalable size + at least 2 tile themes + basic cover.
8. **VFX pass**: hit flashes, tint, gibs + gore intensity setting.
9. **Run meta**: scoring + leaderboard persistence.

## Playtest checkpoints (action item)
- After each milestone, run a short playtest and fill a follow-up questionnaire focused on pacing, readability, and “fun per minute”.

## Key risks
- Rendering performance if grid too large.
- Sim readability vs chaos.
- Content tuning (balance) requires iteration.

## Out of scope (MVP)
- Ranged attacks, complex AI tactics.
- Large bestiary.
- Online features.
