# Questionnaire Answers — 2025-12-27

This captures the current decisions for the prototype build.

## 1) Target + tone
- Devices: iPhone first, include iPad.
- Orientation: support portrait + landscape; auto-rotate (accelerometer-driven).
- Tone: neutral/serious despite ASCII presentation.
- Gore: intense by default; **Home/Start** menu includes a gore intensity control to dial it down.
- Content: OK; combat log should include flavorful descriptions of “horrors of epic combat”.

## 2) Round offers
- No odds hints by default.
- Team composition shown explicitly by number only (e.g., “15 Chickens” vs “5 Baboons”).
- Variation within individuals is required (e.g., pre-existing injuries, rare “demigod” variants).
- No named individuals (at least for uncivilized creatures).
- Matchups: real animals, fantasy, humans, sci‑fi, etc.
- IP/legal: do **not** use real-world named individuals or protected character names.
- Future: unlockable “intel”/hint system may reveal strengths/weaknesses or hidden individual traits **before** the player picks.

## 3) Run structure + pacing
- Typical run length: 5–10 minutes; exceptional 20–40 minutes.
- Runs should end (losses happen easily).
- Progression in absurdity/difficulty as rounds advance.

## 4) Battle length + playback
- Target battle duration: ~60 seconds or less (validate via playtests).
- No hard time limit (reassess later).
- No special playback controls for now.
- Add an escalating fatigue soft-cap if battles run long.

## 5) Arena
- Arena size adjustable and should scale with battle size (1v1 vs 50v50).
- Arena should be varied: biome-like tiles (desert/grass) and constructions (walls/cover).
- Some terrain provides tactical benefits (cover vs breath attacks).
- Destructible terrain where it makes sense.
- Rivers/pools/lava are desired over time; tune MVP subset via playtests.

MVP terrain priorities: rivers, lava, destructible boulders, walls.

## 6) Simulation depth
- MVP intends **deep anatomy** with a structure that scales.
- Morale/fleeing/panic is required.
- Rare special states: bloodlust/berserk (infrequent).
- Ailments to support (over time): vomiting, broken limbs, bleeding, brain damage, breathing issues, torn muscles.

## 7) Creatures/content
- Start with a small set, but they should be generated from the same system (no hard-coded creature logic).
- Special attacks are allowed when thematically justified.

## 8) Authoring format
- Prefer human-readable authoring (YAML-like).
- Multi-attachment is anticipated (e.g., multi-headed creatures).
- Verbose part targeting info should appear in the event log when it makes sense.

## 9) ASCII VFX + log
- No floating damage numbers.
- Combat log is the primary explanation channel; prefer flavorful prose over numeric damage.
- Must have a combat event ticker and a scrollback log.
- Log verbosity is user-adjustable: Brief / Normal / Verbose.
- Example gib glyphs: `. , ' : ` ~ * o` and others as appropriate.

## 10) Unlocks
- Cosmetics + gameplay unlocks are interesting, but hold off for MVP (core system first).

## 11) Audio + haptics
- Haptics desired.
- ASCII “beeps/boops” desired with a mute option.
- No music for now.

## 12) Approach
- Build step-by-step; prioritize a robust system architecture that can be expanded.

## 13) Visual references
- Attached reference images emphasize: dense colored ASCII, readable glyph contrast, and a prominent combat log.

## Addendum (Open Questions Answers)
- Gore intensity labels: Tame / Normal / Grotesque.
- Standout rarity target: ~1/1000.
- Intel/hints only pre-pick; during battle, nothing is hidden.
- Content focus: animals + fantasy; occasional generic humans.

## Addendum (Tech)
- Core game/sim implementation should be in Rust.
- The iOS app should be buildable via Xcode (SwiftUI UI + Rust core via FFI).
