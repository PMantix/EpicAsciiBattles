# ASCII Rendering + VFX

## Rendering goals
- Looks like a roguelike terminal arena.
- Smooth-ish animation without requiring “real” sprites.
- Effects communicate events (hits, gibs, blood/puke tint).

## Visual reference notes
Based on the provided reference screenshots:
- Dense, colorful ASCII fields with high contrast glyphs.
- The combat log is prominent and feels like a core part of the experience.
- Terrain variety (water, walls/structures, natural biomes) helps readability.

## Grid model
- Logical grid: `width x height`.
- Each cell renders a glyph with:
  - `char`
  - `fgColor`
  - `bgColor`
  - optional overlay glyphs (for pop-off gibs, particles)

## Layers
1. Background tiles (floor/walls).
2. Actors (combatants).
3. Overlays (gibs, particles, floating glyphs, hit flashes).
4. Global tint (blood/puke haze).

## Animation model
- Simulation emits events; renderer consumes them and plays short animations.
- Keep sim and render decoupled:
  - Sim tick: deterministic.
  - Render: interpolates between last and next sim positions.

## Event types (prototype)
- `Move(actorId, from, to)`
- `Hit(attackerId, defenderId, partId, damage)`
- `Bleed(actorId, amount)`
- `Sever(partId, gibGlyph)`
- `Death(actorId)`
- `Vomit(actorId, amount)`

## VFX ideas mapped to events
- Hit flash: defender glyph brightens for 150ms.
- Blood: increase red component of nearby cell backgrounds briefly; optionally persistent faint stain.
- Puke: similar but green.
- Gibs: spawn overlay glyphs like `'`, `,`, `2` that arc 2–5 cells then fade.

## Gore intensity setting
Expose a user setting (available from first launch) that controls:
- tint saturation/opacity
- gib particle counts and lifetime
- frequency of persistent stains

Suggested levels: `Tame`, `Normal`, `Grotesque`.

## iOS rendering approach (prototype recommendation)
- Use a single custom view that draws the whole grid each frame.
- Use a monospaced font and draw text per cell (or batched lines) for simplicity.

Implementation options:
- **SwiftUI `Canvas`** (fast iteration, acceptable for small grids).
- **UIKit CoreGraphics** (more control, predictable perf).
- SpriteKit (treat each cell as node; easiest “particles” but can be heavy).

Prototype default: **SwiftUI + `Canvas`**, grid size kept modest.

## Accessibility
- Support “reduced motion”: shorten/disable flying gibs and heavy tint pulsing.
- Ensure contrast: allow a “high contrast” toggle if needed (optional).

## Acceptance criteria (MVP)
- Actors move on a grid with readable glyphs.
- On hit: flash + small background tint.
- On sever: spawn 1–3 gib glyph particles.
- No floating damage numbers.
