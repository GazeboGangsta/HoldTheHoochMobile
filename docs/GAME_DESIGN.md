# Game Design — HoldTheHooch Mobile V1

## Core loop

1. Player taps **Start** from menu → enters name (persisted locally).
2. Gurgles auto-runs to the right. World scrolls left.
3. Player:
   - **Taps right half of screen** to jump (variable height with tap duration — short tap = small hop, hold = full jump).
   - **Drags on left half of screen** (or tilts device, optional) to counter-balance the hooch.
4. Run ends when:
   - Gurgles collides with a ground obstacle → instant game over.
   - Spill meter reaches 100% → game over.
5. Game over screen shows score, submits to `gurgles.beer` leaderboard, offers retry.

## Controls

| Zone | Action | Effect |
|------|--------|--------|
| Right half of screen | Tap (short) | Small jump |
| Right half of screen | Tap (hold ≤ 300ms) | Full jump |
| Left half of screen | Horizontal drag | Counter-tilt hooch toward center |
| (optional, toggle) | Device tilt (accelerometer) | Alternate balance input |

Portrait orientation only for V1.

## Hooch balance system

- Hooch has a `tilt` value in `[-1.0, 1.0]`, `0` = centered.
- Passive drift: natural wobble (sine oscillation) + bias toward outer edges as speed increases.
- Jumps apply an impulse to tilt (direction alternates or is randomized slightly).
- Player drag input applies counter-torque toward center.
- If `|tilt| > 0.7` for more than `0.1s`, spill meter fills at a rate proportional to `|tilt| - 0.7`.
- Spill meter is visible at top of screen. Drains slowly when `|tilt| < 0.4`.

## Obstacles

Spawn from the right edge at speed-dependent intervals. V1 types:

- **Root** — low, must jump (short jump enough).
- **Rock** — mid-height, requires full jump.
- **Mushroom cluster** — low, wide — full jump required.
- **Fallen log** — very wide, requires jump from early.

Spawn table weights shift as difficulty rises (more stacked/wide obstacles at higher speeds).

## Collectibles

Float at three height tiers: **ground** (safe grab), **mid** (small jump needed), **high** (full jump, big hooch disturbance).

- **Herb** — 10 pts, ground tier, common.
- **Golden hop** — 50 pts, mid tier, uncommon.
- **Potion bottle** — 200 pts, high tier, rare. Grants 1 second of spill-drain bonus.

## Scoring

- Distance score: +1 per ~frame (tuned to feel like ~10/sec at start).
- Collectibles: as above.
- Multiplier: +0.1x per 10 seconds survived, capped at 3x.
- Final score submitted to leaderboard on death.

## Difficulty curve

| Time (s) | Scroll speed | Spawn rate | Wobble amplitude |
|----------|--------------|------------|------------------|
| 0        | 1.0x         | 1.0x       | 1.0x             |
| 30       | 1.2x         | 1.2x       | 1.15x            |
| 60       | 1.45x        | 1.4x       | 1.3x             |
| 120      | 1.75x        | 1.65x      | 1.5x             |
| 180+     | 2.0x (cap)   | 1.8x (cap) | 1.7x (cap)       |

Tuning lives in `lib/config/difficulty.dart`.

## Scenes / states

- **Boot** — load assets, init services.
- **Menu** — title, name entry, **Start**, **Leaderboard** button.
- **Game** — the actual run.
- **GameOver** — score, submit state, **Retry** / **Menu**.
- **Leaderboard** — top N from `gurgles.beer`.

## Open questions

- Do we use accelerometer tilt by default, or make it an opt-in setting? (Leaning: drag is default, tilt is setting.)
- Music: reuse web game's tracks, or skip audio for V1?
- Haptics on jump / spill — yes but behind a setting.
