# Technical Architecture (iOS Prototype)

## Top-level goals
- Deterministic sim with seed.
- Data-driven species.
- Decoupled sim ↔ renderer.

## Language split
- **Rust**: core game sim, anatomy system, species validation, RNG.
- **Swift + SwiftUI**: iOS UI shell, navigation, settings, render loop.
- See `13-rust-ios-integration.md` for FFI + build details.

## Suggested module boundaries
- `epic_ascii_battles_core` (Rust crate):
  - RNG + seeding
  - species loader + validation (YAML → models)
  - sim state + tick
  - event stream generation
- `GameUI` (SwiftUI):
  - screens + navigation
  - run state
- `AsciiRenderer` (Swift):
  - grid buffer
  - event-to-VFX translation
  - draw loop (SwiftUI Canvas or UIKit)
- `Persistence` (Swift):
  - runs, scores, unlocks

## Determinism strategy
- Single RNG implementation used by sim.
- No wall-clock randomness.
- Sim step uses integer tick counts.

## Testing strategy (prototype)
- Unit tests for:
  - species validation
  - determinism (same seed → same winner + key events)
  - damage rules (part loss disables capability)

## Performance assumptions
- Small grid + small actor count.
- Render at device refresh; sim can run at fixed tick and “catch up” on fast speeds.

## Acceptance criteria (MVP)
- Same seed reproduces same battle outcome.
- Species loaded from local bundled YAML (parsed by Rust).
- Basic unit test coverage exists for core sim rules (Rust-side).
- Xcode project builds and runs on iOS simulator + device.
