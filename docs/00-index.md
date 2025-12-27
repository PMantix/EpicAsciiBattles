# Epic Ascii Battles — Design Docs Index

These docs define the first-pass product, game design, and technical plan for an iOS prototype.

## Table of contents
- `QUESTIONNAIRE.md` — fill-in prompts to lock key decisions
- `QUESTIONNAIRE-ANSWERS-2025-12-27.md` — current decisions snapshot
- `01-product-vision.md` — elevator pitch, pillars, target feel
- `02-core-gameplay-loop.md` — run structure, rounds, win/lose, scoring
- `03-battle-simulation.md` — rules of time, movement, attacks, damage, morale
- `04-combatant-modeling.md` — anatomy/parts system, tags, authoring pipeline
- `05-ascii-rendering-vfx.md` — grid renderer, glyph layers, animations, “gore” effects
- `06-ios-ux.md` — screens, UI states, accessibility, haptics
- `07-progression-economy.md` — points, streaks, unlocks, meta goals
- `08-technical-architecture.md` — modules, determinism, data flow, testing
- `09-data-persistence.md` — runs, scores, seeds, replays, local storage
- `10-mvp-scope-milestones.md` — MVP definition, milestones, risks
- `11-open-questions.md` — decisions needed from you
- `12-glossary.md` — consistent terminology
- `13-rust-ios-integration.md` — Rust core ↔ Swift/Xcode FFI integration

## Definition of “Prototype”
- Single-player, offline-first.
- Deterministic battle sim with seed.
- Minimal content set (hand-authored) but a system that scales.

## Current decisions snapshot
See `QUESTIONNAIRE-ANSWERS-2025-12-27.md`.
