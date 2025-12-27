# Rust ↔ iOS Integration

## Overview
The core game simulation, anatomy system, and data pipeline are implemented in **Rust**, while the iOS app shell (UI, navigation, settings) is written in **Swift + SwiftUI**. This doc describes how to bridge Rust ↔ Swift so the project is buildable in Xcode.

## Architecture

### Rust side
- **Crate**: `epic_ascii_battles_core`
- Exposes a C-compatible FFI API via `#[no_mangle]` + `extern "C"`.
- Built as a static library (`.a`) or XCFramework.
- Manages:
  - RNG + seeding
  - Species loading (YAML → validated models)
  - Simulation state + tick
  - Event stream generation

### Swift side
- **Target**: iOS App (SwiftUI)
- Links against the Rust static lib or XCFramework.
- Wraps C-ABI calls in a Swift-friendly facade (e.g., `GameCore` class).
- Manages:
  - UI screens + navigation
  - Render loop (ASCII grid → SwiftUI `Canvas` or UIKit)
  - Settings persistence

## Build strategy

### Option A: Static library per architecture
1. Use `cargo build --target aarch64-apple-ios --release` (device) and `--target x86_64-apple-ios` (simulator).
2. Use `lipo` to create a universal `.a` if needed.
3. Add the `.a` + generated header to Xcode project.

### Option B: XCFramework (recommended for multi-arch simplicity)
1. Use `cargo-xcode` or a custom build script to produce an `.xcframework`.
2. Add the `.xcframework` to Xcode as a framework dependency.

### Prototype approach (MVP)
- Start with **Option A** (simpler for rapid iteration).
- Use a build phase script in Xcode that runs `cargo build` automatically if Rust sources change.
- Commit the generated header (`epic_ascii_battles_core.h`) to source control for convenience.

## FFI surface (minimal example)

### Rust FFI (simplified)
```rust
// lib.rs
use std::os::raw::c_char;
use std::ffi::CString;

#[repr(C)]
pub struct SimHandle {
    // opaque pointer to Rust sim state
}

#[no_mangle]
pub extern "C" fn sim_new(seed: u64) -> *mut SimHandle {
    // allocate + return opaque pointer
}

#[no_mangle]
pub extern "C" fn sim_tick(handle: *mut SimHandle) {
    // advance one tick
}

#[no_mangle]
pub extern "C" fn sim_get_events(handle: *mut SimHandle) -> *const c_char {
    // return JSON string of events
}

#[no_mangle]
pub extern "C" fn sim_free(handle: *mut SimHandle) {
    // deallocate
}
```

### Swift wrapper
```swift
// GameCore.swift
import Foundation

class GameCore {
    private var handle: OpaquePointer?
    
    init(seed: UInt64) {
        handle = sim_new(seed)
    }
    
    func tick() {
        sim_tick(handle)
    }
    
    func getEvents() -> String {
        guard let cStr = sim_get_events(handle) else { return "" }
        return String(cString: cStr)
    }
    
    deinit {
        sim_free(handle)
    }
}
```

## Data flow
1. SwiftUI calls `GameCore.tick()`.
2. Rust advances sim state, emits events.
3. Swift retrieves event JSON, decodes, and passes to renderer.

## Species data bundling
- YAML files are bundled in the iOS app's resource bundle.
- Swift reads YAML → passes as string to Rust FFI for parsing + validation.
- Alternatively: Rust reads directly from a resource path passed via FFI.

## Determinism + testing
- Rust unit tests validate determinism (same seed → same events).
- Swift integration tests can call FFI and assert event sequences.

## Performance notes
- FFI overhead is negligible for tick-based sim.
- Avoid crossing the FFI boundary per-cell or per-actor; batch into events.

## Xcode project structure
```
EpicAsciiBattles/
├── EpicAsciiBattles.xcodeproj
├── EpicAsciiBattles/            # Swift app target
│   ├── Views/
│   ├── GameCore.swift           # Swift FFI wrapper
│   └── Info.plist
├── rust/
│   ├── Cargo.toml
│   ├── src/
│   │   └── lib.rs               # Rust FFI entrypoint
│   └── species/                 # YAML species data
└── Frameworks/                   # (optional) XCFramework location
```

## Build automation (Xcode script phase)
Add a "Run Script" build phase before "Compile Sources":

```bash
#!/bin/bash
set -e

cd "${SRCROOT}/rust"

if [ "${CONFIGURATION}" == "Debug" ]; then
    cargo build --target aarch64-apple-ios
else
    cargo build --target aarch64-apple-ios --release
fi

# Copy .a to a known location for Xcode linker
cp target/aarch64-apple-ios/debug/libepic_ascii_battles_core.a "${SRCROOT}/Frameworks/" || \
cp target/aarch64-apple-ios/release/libepic_ascii_battles_core.a "${SRCROOT}/Frameworks/"
```

Ensure Xcode's "Library Search Paths" includes `$(SRCROOT)/Frameworks`.

## Acceptance criteria (MVP)
- Xcode project builds successfully on your Mac.
- Can run on iOS simulator + device.
- Swift can call Rust sim via FFI and retrieve events.
- Species YAML is loaded from app bundle and parsed by Rust.

## Tooling notes
- Requires Rust toolchain with iOS targets installed:
  ```bash
  rustup target add aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim
  ```
- For M1/M2 Macs, simulator uses `aarch64-apple-ios-sim`.

## Future enhancements (post-MVP)
- Use `uniffi-rs` or `swift-bridge` for automatic Swift bindings generation (reduces manual FFI boilerplate).
- Add CI to build XCFramework and validate determinism tests on every commit.
