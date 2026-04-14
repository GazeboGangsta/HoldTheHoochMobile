# HoldTheHooch Mobile — CLAUDE.md

Mobile companion to the web game at [gurgles.beer](https://gurgles.beer) (repo: `HoldTheHooch`). Designed as a "second-screen podcast game" — something simple and repeatable to play while listening to a podcast, in the spirit of Subway Surfers / Minecraft parkour background videos.

## The game

**HoldTheHooch (Mobile V1)** — a 2D side-scrolling endless runner. Gurgles the Druid Brewer Gnome sprints through an enchanted forest holding a giant tankard of hooch above his head. Two simultaneous concerns:

- **Tap/tap-hold (right side of screen):** jump over ground obstacles (roots, rocks, mushrooms, fallen logs).
- **Tilt/drag (left side of screen):** keep the hooch balanced. Tilt past threshold → spill meter fills. 100% spill = run ends. Obstacle hit = instant end.

Floating collectibles (herbs, golden hops, potion bottles) at varying heights give risk/reward bonuses (jumping disturbs the hooch). Speed and wobble intensity scale up over time.

## Tech stack

- **Engine:** Flutter + Flame (2D game engine for Flutter)
- **Language:** Dart
- **Targets:** iOS + Android (single codebase)
- **Backend:** Reuses the existing `gurgles.beer` Express + SQLite backend (`POST /api/scores`, global leaderboard). No auth — just a name and a score.
- **Assets:** Auto-generated SVG placeholders for V1, swappable by dropping new files into `assets/svg/`. A formal asset requirements doc lives at `docs/ASSETS.md`.

## Scope discipline

The original web game's philosophy — *"a small, charming, tightly-scoped game that captures the feel of an old Newgrounds flash game from 2005"* — holds here too. Mobile V1 is **not** Temple Run or Subway Surfers. It is the web game, plus:

- Touch controls tuned for one-handed portrait play
- Slightly richer visuals (parallax layers, particle wobble on the hooch)
- Mobile-native score submission to the same leaderboard
- App store packaging (Google Play + Apple App Store)

Things that are **out of scope** for V1: accounts, auth, IAP, ads, power-ups, character skins, 3D, multiplayer, daily challenges.

## Directory layout

```
lib/
  main.dart              # app entry point
  components/            # Flame components (Gurgles, HoochBalance, Obstacle, Collectible, Ground, Parallax)
  scenes/                # Flame "worlds" — Boot, Menu, Game, GameOver, Leaderboard
  systems/               # ObstacleManager, CollectibleManager, WobbleSystem, DifficultyCurve, ScoreTracker
  services/              # ApiClient (score submission + leaderboard fetch), LocalStore (best score, player name)
  config/                # game constants (speeds, thresholds, spawn tables)
  utils/                 # helpers
assets/
  images/                # raster fallbacks / exported SVGs
  svg/                   # primary art — drop-in replaceable
  audio/                 # sfx + (optional) music
docs/
  GAME_DESIGN.md         # mechanics, tuning, progression
  ASSETS.md              # asset requirements list (sizes, formats, per-asset spec)
  BACKEND.md             # contract with gurgles.beer API
  ROADMAP.md             # V1 plan → post-V1 ideas
test/                    # widget + component tests
```

## Working agreements

- Keep the V1 surface small. Resist adding features before shipping to both stores.
- Placeholder art is fine. Do NOT block on art — the engine reads from `assets/svg/` and assets are swappable without code changes.
- Reuse the existing backend. Do not build new server infrastructure for V1.
- Every new gameplay system gets a short note in `docs/GAME_DESIGN.md` so tuning values live alongside rationale.
- Prefer Flame's built-in components over hand-rolled game loops.

## Related repos

- Web game: `HoldTheHooch` — Phaser 3, CDN-loaded, served from `gurgles.beer`.
- This repo: `HoldTheHoochMobile` — Flutter + Flame, iOS + Android.
