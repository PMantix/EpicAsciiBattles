# iOS UX

## Screen list (MVP)
1. **Home**: Start Run, Leaderboard, Settings.
2. **Round Offer**: matchup card + pick buttons.
3. **Battle**: ASCII arena view + combat log.
4. **Round Result**: correct/incorrect + points.
5. **Run Summary**: score + highlights + continue (back to Home).
6. **Leaderboard**: local top runs.

## Settings (MVP)
- Gore intensity: Tame / Normal / Grotesque.
- Combat log verbosity: Brief / Normal / Verbose.
- Sound: on/off (ASCII beeps/boops).
- Haptics: on/off.

## Navigation
- Stack-based navigation.
- Battle screen is full-screen focused content.

## Controls (Battle)
- No special playback controls for MVP.
- Provide a simple way to open/close the combat log panel.

## UI data shown during battle (keep minimal)
- Team alive counts.
- Current round.
- A small event ticker (recent events).
- Scrollable combat log (full scrollback for the current battle).

## Feedback
- Haptics:
  - light on pick selection
  - success/failure at round end
- Sound: ASCII beeps/boops; can be silenced.

## Orientation
- Support portrait + landscape; auto-rotate.
- Arena scales to fit; use monospaced font scaling.

## Acceptance criteria (MVP)
- Entire loop playable with standard iOS navigation.
- Battle view is readable on iPhone and iPad.
- Combat log is readable and scrollable.
