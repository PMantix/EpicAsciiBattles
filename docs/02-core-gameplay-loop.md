# Core Gameplay Loop

## Run loop
1. **Round Offer**: game shows a matchup card (teams, counts).
2. **Pick Winner**: player taps Team A or Team B.
3. **Battle Playback**: ASCII arena sim runs to completion.
4. **Round Result**:
   - If player picked correctly → award points → next round.
   - If incorrect → run ends.
5. **Run Summary**: final score + streak + notable events.
6. **Leaderboard**: local top scores.

## Round Offer content
- Team composition summary:
  - Species/archetype name, count (e.g., “15 Chickens” vs “5 Baboons”).
- No odds hints and no trait reveals by default.
- Individual variation exists under the hood (pre-existing injuries, rare standout individuals).
- Optional post-MVP: unlockable “intel” can reveal some info **before** you pick.
- Once battle begins, nothing is hidden; standout behavior is revealed through the sim + VFX + combat log (still not via explicit stats).

## Scoring (prototype defaults)
- Base score per correct pick: `100`.
- Bonus multiplier by round index: `1.0 + 0.1 * (round-1)`.
- Bonus for “underdog” (optional): if your pick’s estimated strength < opponent strength, add `+25%`.

## Loss / end conditions
- Wrong pick ends run immediately.

## Content pacing
- Early rounds: simple, readable matchups.
- Later rounds: larger teams, more exotic creatures, more statuses.

## Session pacing targets
- Typical run: 5–10 minutes.
- Strong/lucky run: 20–40 minutes.

## Battle presentation goals
- Always show:
  - Who is alive.
  - Who is fighting whom.
  - Major damage events.
- Primary explanation channel is the combat log (flavor text), not numeric damage.

## Acceptance criteria (MVP)
- Can start a run, complete multiple rounds, and end a run.
- Points increase on correct picks.
- Run ends on incorrect pick.
- Local leaderboard persists between launches.
