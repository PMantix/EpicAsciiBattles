# Data + Persistence

## Data types

### Species definitions (bundled)
- Stored in app bundle as JSON.
- Versioned with a schema version.

### Run record (stored)
- `runId`
- `timestamp`
- `score`
- `roundReached`
- `seed`
- `notableUnlocks` (optional)

### Leaderboard
- Store top `N` (e.g., 20) runs.

### Unlocks
- Boolean flags keyed by id.

## Persistence mechanism (prototype)
- Use `Codable` + file storage or `UserDefaults` for simple key/value.
- Prefer file storage for leaderboard array + unlock dictionary.

## Replay support (optional but aligns with determinism)
- Store just `seed` + matchup definition per round.
- Re-simulate to replay.

## Acceptance criteria (MVP)
- Leaderboard persists between app launches.
- Unlock flags persist.
