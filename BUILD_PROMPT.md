# Build Prompt: Epic ASCII Battles iOS Prototype

## Project Overview

Build **Epic ASCII Battles**, a watchable ASCII arena battle game for iOS where players predict winners of bizarre matchups and watch deterministic "Dwarf Fortress-style" simulations unfold with animated roguelike ASCII spectacle.

### Core Concept
- **No player control** during battles - this is a spectator experience
- Player picks a side from each matchup (e.g., "5 baboons vs 15 chickens")
- Deterministic battle simulation plays out with deep anatomy and visible consequences
- Correct picks award points and continue the run; wrong picks end it
- Target feel: "Roguelike spectator sport meets procedural creature simulation"

## Technical Architecture

### Technology Stack
- **Core Simulation**: Rust (`epic_ascii_battles_core` crate)
  - Deterministic battle simulation with seeding
  - Anatomy system with part graphs and tag-based behavior derivation
  - Species data loading and validation (YAML → runtime models)
  - Event stream generation for rendering
  - RNG management
- **iOS App**: Swift + SwiftUI
  - UI screens and navigation
  - ASCII rendering (SwiftUI Canvas approach)
  - Settings and data persistence
  - FFI bridge to Rust core
- **Integration**: C-compatible FFI with static library linkage
- **Build**: Xcode project with Rust build script phase

### Project Structure
```
EpicAsciiBattles/
├── EpicAsciiBattles.xcodeproj
├── EpicAsciiBattles/              # Swift iOS app
│   ├── Views/
│   │   ├── HomeView.swift
│   │   ├── RoundOfferView.swift
│   │   ├── BattleView.swift
│   │   ├── RoundResultView.swift
│   │   ├── RunSummaryView.swift
│   │   └── LeaderboardView.swift
│   ├── Core/
│   │   ├── GameCore.swift         # Swift FFI wrapper
│   │   ├── AsciiRenderer.swift
│   │   └── GameState.swift
│   ├── Models/
│   │   ├── RunRecord.swift
│   │   ├── BattleEvent.swift
│   │   └── Settings.swift
│   ├── Persistence/
│   │   ├── LeaderboardStore.swift
│   │   └── SettingsStore.swift
│   └── Resources/
│       └── species/               # YAML species definitions
├── rust/
│   ├── Cargo.toml
│   ├── src/
│   │   ├── lib.rs                 # FFI entrypoint
│   │   ├── sim/
│   │   │   ├── mod.rs
│   │   │   ├── battle.rs
│   │   │   ├── actor.rs
│   │   │   └── grid.rs
│   │   ├── anatomy/
│   │   │   ├── mod.rs
│   │   │   ├── part.rs
│   │   │   └── tags.rs
│   │   ├── species/
│   │   │   ├── mod.rs
│   │   │   ├── loader.rs
│   │   │   └── validator.rs
│   │   └── events.rs
│   └── tests/
└── docs/                          # Existing design documents
```

## Implementation Requirements

### Phase 1: Foundation & Integration

#### 1.1 Rust Core Setup
Create the `epic_ascii_battles_core` Rust crate with:

**Core modules:**
- `sim::battle` - Battle state, tick-based simulation loop
- `sim::actor` - Combatant state (position, facing, stats, anatomy, statuses)
- `sim::grid` - Arena grid with terrain/props
- `anatomy::part` - Part graph with HP, armor, functions, tags
- `anatomy::tags` - Tag system for deriving attacks and capabilities
- `species::loader` - YAML parsing and species model construction
- `species::validator` - Graph integrity, required tags, unique IDs
- `events` - Event stream types (Move, Hit, Bleed, Sever, Death, Vomit)

**Key features:**
- Deterministic RNG (seeded, no wall-clock randomness)
- Fixed tick `dt` (100ms default)
- Stats: mass, speed, stamina, pain tolerance, morale
- Status effects: bleeding, vomiting, stunned, limping, panic/fleeing
- Morale system with fleeing threshold + rare berserk state

**FFI surface:**
```rust
#[no_mangle]
pub extern "C" fn sim_new(seed: u64, species_yaml: *const c_char) -> *mut SimHandle;

#[no_mangle]
pub extern "C" fn sim_tick(handle: *mut SimHandle);

#[no_mangle]
pub extern "C" fn sim_get_events_json(handle: *mut SimHandle) -> *const c_char;

#[no_mangle]
pub extern "C" fn sim_get_state_json(handle: *mut SimHandle) -> *const c_char;

#[no_mangle]
pub extern "C" fn sim_is_finished(handle: *mut SimHandle) -> bool;

#[no_mangle]
pub extern "C" fn sim_get_winner(handle: *mut SimHandle) -> i32; // 0=A, 1=B, -1=ongoing

#[no_mangle]
pub extern "C" fn sim_free(handle: *mut SimHandle);

#[no_mangle]
pub extern "C" fn sim_free_string(s: *mut c_char);
```

#### 1.2 Xcode Project Setup
- Create new iOS App project in Xcode (SwiftUI lifecycle)
- Support iPhone and iPad
- Support portrait and landscape with auto-rotation
- Minimum deployment target: iOS 16.0
- Add "Run Script" build phase to compile Rust:
```bash
#!/bin/bash
set -e
cd "${SRCROOT}/rust"
if [ "${CONFIGURATION}" == "Debug" ]; then
    cargo build --target aarch64-apple-ios
else
    cargo build --target aarch64-apple-ios --release
fi
# Copy .a to Frameworks and header to bridging location
```

#### 1.3 Swift FFI Bridge
Create `GameCore.swift` wrapper class:
- Initialize with seed
- Expose `tick()`, `getEvents()`, `getState()`, `isFinished()`, `getWinner()`
- Handle C string memory management
- Parse JSON event stream into Swift structs
- Provide battle lifecycle management

### Phase 2: Anatomy System & Species Data

#### 2.1 Tag-Based Anatomy System
Implement the tag system in Rust:

**Core tags:**
- Anatomy: `head`, `neck`, `torso`, `wing`, `leg`, `foot`, `claw`, `beak`, `tail`
- Materials: `feathered`, `scaled`, `furred`, `armored`
- Capabilities: `locomotion`, `flight`, `grasp`, `biteWeapon`, `scratchWeapon`, `peckWeapon`
- Vital: `vital`, `brain`, `heart`, `lung`
- Special: `poisonGland`, `horn`, `spit`

**Attack derivation mapping:**
- `peckWeapon` → `peck` attack (pierce, short range)
- `scratchWeapon` → `scratch` attack (slash, short range)
- `biteWeapon` → `bite` attack (pierce/slash mix)

**Part loss effects:**
- Lost `wing` + `flight` → cannot fly, speed reduced
- Lost `leg` + `locomotion` → speed reduced; 0 locomotion parts → immobile
- Lost `head` + `brain`/`vital` → death
- Threshold events: wounded (reduced function), severed (gib spawn), destroyed

#### 2.2 Species Definitions
Create YAML species files (starting with chicken and baboon):

**Chicken YAML structure:**
```yaml
id: chicken
name: Chicken
glyph: "c"
color: "yellow"
baseStats:
  massKg: 2
  speed: 6
  stamina: 50
  painTolerance: 40
  baseMorale: 100
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

**Baboon species** with appropriate stats and anatomy (stronger, more aggressive).

#### 2.3 Individual Variation
Implement instance generation system:
- Per-individual stat variance (mass, toughness, aggression)
- Pre-existing injuries (optional per matchup)
- Rare "standout" individuals (~1/1000 rarity with significantly enhanced stats)
- All generation uses seeded RNG for determinism

### Phase 3: Battle Simulation

#### 3.1 Grid & Arena System
- Scalable grid size based on actor count
- Terrain types: floor tiles (grass, desert, stone), walls, boulders (destructible)
- Future support for: rivers, lava pools
- Biome-based tile sets with tactical features (cover, line-blocking)
- Teams spawn in opposing zones

#### 3.2 Core Simulation Loop
Per tick:
1. Update statuses (bleeding, vomit, stun recovery)
2. For each actor:
   - Skip if incapacitated/dead
   - Choose target (nearest enemy; if fleeing, move away)
   - Pathfind and move (greedy + local avoidance)
   - If in range, execute attack
3. Resolve queued attacks:
   - Hit roll vs evasion
   - Damage to random target part (weighted by hitWeight)
   - Apply damage, check thresholds (wounded/severed/destroyed)
   - Update part HP and functions
4. Emit events for rendering

#### 3.3 Attack System
Each attack has:
- `name`, `rangeCells`, `windupTicks`, `cooldownTicks`
- `toHit` base chance vs defender evasion
- `damageProfile` (pierce/slash/blunt amounts)
- `targeting` strategy (weighted random part selection)

#### 3.4 Damage & Death
- Damage applied to target part's HP
- Parts have armor/resist multipliers
- Death conditions:
  - Core parts destroyed (head/brain)
  - Blood loss exceeds threshold
- Incapacitation: cannot move + cannot attack

#### 3.5 Morale System
- Morale starts at 100
- Drops on: part loss, heavy pain, nearby ally deaths
- Below threshold (e.g., 30) → "fleeing" behavior
- Rare proc (~1-2% per severe event): "berserk" state (increased aggression, reduced pain response)

#### 3.6 Fatigue Soft-Cap
To prevent runaway battles:
- Fatigue accumulates over time for all actors
- After threshold duration (~90 seconds), fatigue accelerates
- High fatigue: reduced speed, increased action costs, lower recovery

### Phase 4: Combat Log System

#### 4.1 Event-to-Prose Generation
Implement flavorful combat log text generation in Rust:

**Event types with example prose:**
- Hit: "The baboon's fist crushes the chicken's wing!" / "Chicken pecks at baboon's face!"
- Bleed: "The chicken is bleeding heavily from its torso."
- Sever: "The baboon tears off the chicken's leg!" (spawn gib)
- Death: "The chicken collapses, lifeless."
- Vomit: "The baboon retches, spewing bile."
- Status: "The chicken limps badly." / "The baboon flees in terror!"

**Verbosity levels:**
- Brief: major events only (deaths, severings)
- Normal: hits + major status changes + deaths
- Verbose: all events including minor damage

Return log entries as part of event stream JSON.

#### 4.2 Swift Combat Log UI
- Scrollable list view in Battle screen
- Color-coded entries (red for damage, yellow for status, white for movement)
- Auto-scroll to latest by default with manual scroll-lock
- Accessible via button/swipe during battle

### Phase 5: ASCII Rendering & VFX

#### 5.1 Grid Renderer (SwiftUI Canvas)
Create `AsciiRenderer` component:
- Fixed grid size (scale with device)
- Monospaced font (SF Mono or Menlo)
- Render layers:
  1. Background tiles (floor/walls)
  2. Actors (combatant glyphs with colors)
  3. Overlays (gibs, particles, hit flashes)
  4. Global tint (blood/puke haze)

**Cell data model:**
```swift
struct GridCell {
    var char: Character
    var fgColor: Color
    var bgColor: Color
    var overlays: [OverlayGlyph]
}

struct OverlayGlyph {
    var char: Character
    var color: Color
    var lifetime: TimeInterval
    var position: CGPoint // for animation
}
```

#### 5.2 VFX Implementation
Event-driven animations:
- **Hit flash**: Brighten defender glyph for 150ms
- **Blood**: Increase red component of nearby cell backgrounds; optional persistent faint stain
- **Puke**: Similar but green tint
- **Gibs**: Spawn overlay glyphs (`'`, `,`, `"`, `*`, `~`, `o`, `:`) that arc 2-5 cells then fade
- **Death**: Glyph color fade to gray, brief enlargement
- **Movement**: Interpolate position between ticks

#### 5.3 Gore Intensity Setting
User-adjustable levels affect:
- Tint saturation/opacity
- Gib particle count and lifetime
- Persistent stain frequency

**Levels:**
- **Tame**: Minimal tinting, few gibs, no stains
- **Normal**: Moderate effects
- **Grotesque**: Heavy tinting, many gibs, persistent blood pools

### Phase 6: iOS UI & Navigation

#### 6.1 Screen Implementations

**HomeView:**
- "Start Run" button (prominent)
- "Leaderboard" button
- "Settings" button
- Background: subtle animated ASCII pattern

**RoundOfferView:**
- Matchup card showing:
  - Team A: species name, count, representative glyph
  - Team B: species name, count, representative glyph
  - Current round number
  - Current score
- Two large tap areas for Team A / Team B selection
- Brief animation on selection

**BattleView:**
- Full-screen ASCII grid (AsciiRenderer)
- Overlay UI (minimal):
  - Top bar: Round number, alive counts per team
  - Bottom: Combat log toggle button
  - Recent event ticker (last 3 events, auto-fade)
- Combat log panel (slides up from bottom, dismissible)

**RoundResultView:**
- Correct/Incorrect indicator
- Points awarded (if correct)
- Brief highlight (most dramatic moment from combat log)
- "Continue" button (if correct) or "View Summary" (if incorrect)

**RunSummaryView:**
- Final score (large, prominent)
- Rounds reached
- Notable events list (most kills, longest battle, etc.)
- Leaderboard position (if in top N)
- "Back to Home" button

**LeaderboardView:**
- List of top 20 runs:
  - Rank, score, rounds reached, date
  - Tap to see run summary
- Local storage only

#### 6.2 Settings Screen
User preferences:
- Gore intensity: Tame / Normal / Grotesque
- Combat log verbosity: Brief / Normal / Verbose
- Sound: On / Off
- Haptics: On / Off
- Accessibility: Reduce motion (disables flying gibs and heavy tint pulsing)

Store via `UserDefaults` with `Codable`.

#### 6.3 Orientation Support
- Support portrait and landscape
- Auto-rotate based on device orientation
- Grid scales appropriately
- UI adapts layout (stack vs side-by-side for iPad landscape)

### Phase 7: Game Loop & Scoring

#### 7.1 Run State Management
`GameState` class to manage:
- Current run ID (UUID)
- Current round index
- Current score
- Run history (for summary)
- Matchup generation (seeded random team compositions)

#### 7.2 Matchup Generation
Per round:
- Select 2 species from available pool
- Assign counts (scale with round index)
- Add variance: pre-existing injuries, standout individuals
- Ensure different difficulty/complexity each round
- Provide seed to simulation

#### 7.3 Scoring Algorithm
```swift
func calculateScore(round: Int, isUnderdog: Bool) -> Int {
    let baseScore = 100
    let roundMultiplier = 1.0 + 0.1 * Double(round - 1)
    let underdogBonus = isUnderdog ? 1.25 : 1.0
    return Int(Double(baseScore) * roundMultiplier * underdogBonus)
}
```

Underdog determination: compare estimated team strength (sum of mass × count × aggression).

#### 7.4 Persistence
`LeaderboardStore` using file storage:
- Store array of `RunRecord` structs
- Keep top 20, sorted by score
- Persist on each run completion

```swift
struct RunRecord: Codable {
    let runId: UUID
    let timestamp: Date
    let score: Int
    let roundReached: Int
    let seed: UInt64
}
```

### Phase 8: Audio & Haptics

#### 8.1 Sound Effects
Simple "ASCII beeps/boops" using `AVAudioEngine`:
- Hit: short beep (frequency varies by damage)
- Death: descending tone
- Victory/loss: chord
- UI interactions: soft clicks
- Mute toggle in settings

#### 8.2 Haptics
Using `UIFeedbackGenerator`:
- Light haptic on pick selection
- Medium haptic on hit (if dramatic)
- Success haptic on correct pick
- Failure haptic on incorrect pick
- Heavy haptic on death
- Respect haptics setting toggle

### Phase 9: Testing & Validation

#### 9.1 Rust Unit Tests
Required test coverage:
- **Determinism**: Same seed produces identical outcomes (winner, event sequence)
- **Species validation**: Invalid YAML rejected (missing vital tags, broken graph)
- **Part loss**: Verify capability disabling (lost locomotion → immobile)
- **Damage rules**: Hit calculations, part HP reduction, threshold events
- **Morale**: Fleeing triggers at correct threshold

#### 9.2 Swift Integration Tests
- FFI bridge memory safety (no leaks)
- Event stream parsing
- UI state transitions (Home → Offer → Battle → Result → Summary)
- Settings persistence

#### 9.3 Manual Playtest Checklist
- [ ] Complete a full run (5+ rounds)
- [ ] Test both win and loss scenarios
- [ ] Verify combat log accuracy matches visual events
- [ ] Check gore intensity settings affect rendering
- [ ] Confirm determinism: same seed replays identically
- [ ] Test on iPhone and iPad, portrait and landscape
- [ ] Verify accessibility (reduce motion)
- [ ] Check leaderboard persistence across launches

## MVP Acceptance Criteria

### Core Gameplay
- ✅ Full run loop functional: Offer → Pick → Battle → Result → Next/End → Summary → Leaderboard
- ✅ Deterministic battles (same seed = same outcome)
- ✅ At least 2 species fully implemented (chicken, baboon) with data-driven approach
- ✅ Deep anatomy system with part loss affecting capabilities
- ✅ Morale with panic/fleeing + rare berserk state

### Simulation
- ✅ Grid arena with scalable size
- ✅ Movement with pathfinding
- ✅ Melee combat with derived attacks (peck, scratch, bite)
- ✅ At least one status effect visible (bleeding)
- ✅ Death and incapacitation conditions
- ✅ Fatigue soft-cap to prevent endless battles

### Presentation
- ✅ ASCII grid rendering with colored glyphs
- ✅ VFX: hit flashes, blood tint, gib particles
- ✅ Combat log with flavorful prose
- ✅ Scrollable combat log + recent event ticker
- ✅ Gore intensity setting (Tame/Normal/Grotesque)

### UX
- ✅ All screens implemented and navigable
- ✅ Settings persist (gore, verbosity, sound, haptics)
- ✅ Leaderboard persists locally
- ✅ Portrait and landscape support with auto-rotate
- ✅ Works on iPhone and iPad

### Technical
- ✅ Rust core builds and links via FFI
- ✅ Xcode project builds for iOS simulator and device
- ✅ Species loaded from bundled YAML
- ✅ Unit tests pass (determinism, validation, damage rules)

## Build Order / Milestones

### Milestone 1: Scaffold (Week 1)
- Xcode project setup
- Rust crate with basic FFI
- Swift wrapper + basic integration test
- Navigation shell (Home → Offer → Battle → Result → Summary → Leaderboard)
- Placeholder views

### Milestone 2: Core Sim v0 (Week 1-2)
- Grid + movement + basic pathfinding
- Simple melee (no anatomy yet, just HP)
- Win condition (team elimination)
- Basic event stream
- Determinism test

### Milestone 3: Deep Anatomy (Week 2)
- Part graph system
- Tag-based attack derivation
- Part loss affecting capabilities
- Bleeding status
- Death by part destruction

### Milestone 4: Species Pipeline (Week 2-3)
- YAML loader + validator
- Chicken + baboon definitions
- Individual variation generation
- Instance testing

### Milestone 5: Morale System (Week 3)
- Morale tracking
- Panic/fleeing behavior
- Rare berserk state
- Morale drop events

### Milestone 6: Combat Log (Week 3)
- Event-to-prose generation
- Verbosity filtering
- Swift UI integration
- Scrollback

### Milestone 7: Arena v0 (Week 4)
- Scalable grid sizing
- At least 2 tile themes (grass, desert)
- Basic cover/walls
- Team spawn zones

### Milestone 8: VFX Pass (Week 4)
- Hit flashes
- Blood/puke tinting
- Gib particle system
- Gore intensity setting

### Milestone 9: Run Meta (Week 4-5)
- Scoring implementation
- Leaderboard persistence
- Run summary highlights
- Settings persistence

### Milestone 10: Polish (Week 5)
- Audio/haptics
- Orientation handling
- Accessibility (reduce motion)
- Icon + launch screen
- Final playtesting and tuning

## Technical Constraints & Guidelines

### Performance Targets
- Grid size: max 80×40 for iPhone, 120×60 for iPad
- Frame rate: 60 fps rendering
- Simulation: 10 ticks per second (100ms tick)
- Battle duration: target 30-60 seconds typical

### Code Style
- **Rust**: Follow standard rustfmt, use `Result` types, comprehensive error messages
- **Swift**: SwiftUI best practices, prefer `@StateObject`/`@ObservedObject`, avoid force unwraps
- Clear separation: Sim logic in Rust, UI logic in Swift, minimal FFI surface

### Memory Safety
- All C strings from Rust must be explicitly freed by Swift
- Use opaque pointers for sim handles
- No shared mutable state across FFI boundary
- Event stream copied to Swift as JSON, then Rust buffer freed

### Determinism Requirements
- Single RNG instance seeded at sim creation
- No `std::time` or wall-clock dependencies in sim
- Fixed `dt` tick
- All randomness via seeded RNG

### Data Validation
- Species YAML validated at load time (Rust side)
- Clear error messages for invalid definitions
- Validate: graph cycles, required vital parts, unique IDs, valid tags

## Out of Scope (Post-MVP)

These features are explicitly deferred:
- Ranged attacks
- Complex AI tactics / formations
- Large bestiary (>5 species)
- Multiplayer or online features
- User-created content
- Replay saving/sharing
- Complex unlocks or meta-progression
- Advanced terrain (rivers, lava - basic support only)
- Sound/music beyond simple beeps

## Reference Documents

All detailed specifications are in `/docs`:
- `01-product-vision.md` - Core concept and pillars
- `02-core-gameplay-loop.md` - Run structure and rounds
- `03-battle-simulation.md` - Simulation rules and mechanics
- `04-combatant-modeling.md` - Anatomy system and species authoring
- `05-ascii-rendering-vfx.md` - Rendering approach and effects
- `06-ios-ux.md` - Screen designs and UX flow
- `07-progression-economy.md` - Scoring and unlocks
- `08-technical-architecture.md` - Architecture decisions
- `09-data-persistence.md` - Storage and replay
- `10-mvp-scope-milestones.md` - MVP definition
- `13-rust-ios-integration.md` - FFI integration details
- `QUESTIONNAIRE-ANSWERS-2025-12-27.md` - All design decisions locked

## Success Criteria

The prototype is complete when:
1. A player can start a run, complete 5+ rounds, and see their score on the leaderboard
2. Battles are readable and feel intense/dramatic despite ASCII presentation
3. Combat log provides clear, flavorful explanations of what's happening
4. Anatomy system demonstrably affects battles (visible limping, death by part loss)
5. Same seed produces identical battles (verifiable via replay)
6. App runs smoothly on iPhone and iPad in both orientations
7. All acceptance criteria in MVP section are met

## Final Notes

- **Prioritize iteration speed**: Use SwiftUI Canvas over SpriteKit for faster prototyping
- **Test determinism early and often**: This is a core technical requirement
- **Playtest after each milestone**: Validate pacing and readability
- **Keep content minimal**: Focus on robust systems over large bestiary
- **Document FFI carefully**: This is the critical integration point
- **Embrace constraints**: ASCII limitations force creative solutions

Build incrementally, test continuously, and maintain the separation between deterministic simulation (Rust) and presentation (Swift).
