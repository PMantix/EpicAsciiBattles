# Epic Ascii Battles — Questionnaire (Fill This In)

Answering these locks decisions so a coding agent can implement the prototype cleanly.

## 1) Target + tone
- Target device(s): iPhone only / iPhone + iPad:
- Orientation: portrait only / allow landscape:
- Tone: comedic / gritty / cute / neutral:
- Gore intensity (ASCII-abstract): mild / medium / spicy:
- Any content lines you don’t want crossed:

## 2) Round offers (what the player sees before picking)
- Should the player get an “odds” hint? none / subtle / explicit odds:
- Show unit counts only, or also show a few traits per side?
- Named individuals? none / generated names / curated names:
- Matchup variety preference: real animals / fantasy / mixed:

## 3) Run structure + scoring
- How long should a good run feel (in rounds)? e.g., 3–5 / 6–10 / endless until loss:
- Scoring preference:
  - Flat per correct pick
  - Increasing per round
  - Bonus for underdog picks
- Should there be a “streak” bonus?
- Should the player ever be allowed a “continue” (one extra life) via an unlock?

## 4) Battle length + pacing
- Typical battle duration: ~10s / ~20s / ~30s / ~60s:
- Hard time limit per battle? yes/no. If yes, winner by:
  - remaining alive count
  - remaining health sum
  - “team strength” heuristic
- Playback controls: pause, 1x/2x/4x, skip-to-end — keep all?

## 5) Arena
- Arena grid size preference (rough):
  - Small (30x20)
  - Medium (40x25)
  - Large (60x40)
- Obstacles: none / a few pillars / maze-ish:
- Any special tiles (water, lava) in MVP? yes/no:

## 6) Simulation depth (pick MVP level)
Choose one:
- **A — Light anatomy**: parts exist, attacks derived, part loss is mostly cosmetic.
- **B — Medium anatomy**: part loss affects movement/attacks (limping, no flight).
- **C — Deep anatomy**: add organs + bleeding-out + more detailed incapacitation.

If B or C:
- Should morale/fleeing exist in MVP? yes/no:
- Should vomiting exist in MVP? yes/no:

## 7) Species content (MVP set)
- Confirm MVP species: Chickens + Baboons (yes/no). If no, what instead?
- Preferred visuals:
  - Chickens glyph/color:
  - Baboons glyph/color:
- Any “signature attacks” you want beyond derived basics?

## 8) Anatomy/tag authoring preferences
- Data format preference: JSON / YAML (converted to JSON) / don’t care:
- Do you want strictly a tree (single parent per part) or allow multi-attachment?
- Should parts be targetable by name in the UI/event log (e.g., “wing severed”)? yes/no:

## 9) ASCII VFX preferences
- On hit, do you want floating damage numbers? yes/no:
- How persistent should stains/tints be? momentary / fade / persist for match:
- Favorite gib glyphs (examples):
- Should there be a compact event ticker (“Chicken #3 pecks Baboon #1’s eye”)? yes/no:

## 10) Unlocks + leaderboard
- Unlock philosophy: cosmetics only / gameplay-affecting allowed (e.g., extra life):
- What should unlock first and when?
- Leaderboard: top 10 / top 20 / unlimited:
- Do you want run “replay” from seed on the leaderboard screen? yes/no:

## 11) Audio + haptics
- Haptics: light/standard/strong/off:
- Sound: none / minimal (hits) / fuller:
- Music: none / minimal loop:

## 12) Must-haves vs nice-to-haves
- Must-have for MVP:
- Nice-to-have (post-MVP):
- Absolute no-go features for now:

## 13) Visual references (optional)
- Any games/visuals that match the vibe (links or names):

