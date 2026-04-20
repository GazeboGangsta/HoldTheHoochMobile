# HoldTheHooch Mobile — CLAUDE.md

Mobile companion to the web game at [gurgles.beer](https://gurgles.beer) (repo: `HoldTheHooch`). Designed as a "second-screen podcast game" — something simple and repeatable to play while listening to a podcast, in the spirit of Subway Surfers / Minecraft parkour background videos.

## The game

**HoldTheHooch (Mobile V1)** — a 2D side-scrolling endless runner. Gurgles the Druid Brewer Gnome sprints through an enchanted forest holding a giant tankard of hooch above his head. Two simultaneous concerns, mapped to a dedicated bottom control strip:

- **▲ Jump button (right of strip):** tap-and-hold to clear ground obstacles (roots, rocks, mushrooms, fallen logs). Hold duration = jump height.
- **◀ ▶ Tilt buttons (left of strip):** tap-and-hold to push the hooch left/right and counter the passive drift + wobble. Tilt past threshold → spill meter fills. 100% spill = run ends. Obstacle hit = instant end.

The tankard visually leans with the current tilt so the player can see which way it's drifting at a glance. Floating collectibles (herbs, golden hops, potion bottles) at three height tiers give risk/reward bonuses (jumping disturbs the hooch). Speed and wobble intensity scale up over 3 minutes.

## Tech stack

- **Engine:** Flutter + Flame (2D game engine for Flutter)
- **Language:** Dart
- **Targets:** iOS + Android (single codebase)
- **Backend:** Reuses the existing `gurgles.beer` Express + SQLite backend (`POST /api/scores`, global leaderboard). No auth — just a name and a score.
- **Assets:** SVG placeholders pulled from the web game for V1, swappable by dropping new files into `assets/svg/`. Art briefs live at `docs/ART-GUIDE.md` (drops into `assets/svg/` + `assets/images/`) and `docs/AUDIO-GUIDE.md` (drops into `assets/audio/`).

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
  main.dart              # app entry point, MaterialApp, portrait-only
  components/            # Flame components (Gurgles, HoochBalance, Obstacle,
                         #   Collectible, Ground, ParallaxLayer, SpillMeter,
                         #   ScorePopup, TiltButton)
  scenes/                # menu_screen, game_screen, game_scene,
                         #   game_over_overlay, leaderboard_screen
  systems/               # ObstacleManager, CollectibleManager
  services/              # ApiClient, LocalStore
  widgets/               # Flutter widgets used outside Flame
                         #   (LeaderboardEntryRow)
  config/                # game_config.dart — all tuning constants
  utils/                 # routes.dart (fadeRoute), format_score.dart
assets/
  images/                # raster fallbacks / exported SVGs
  svg/                   # primary art — drop-in replaceable
  audio/                 # sfx + (optional) music
  third_party/           # licensed asset packs (with LICENSE.txt)
docs/
  STATUS.md              # live end-of-session snapshot + known issues
  GAME_DESIGN.md         # mechanics, tuning, progression
  ART-GUIDE.md           # art brief — per-asset design notes, sizes, colours
  AUDIO-GUIDE.md         # audio brief — SFX list, music spec, format rules
  BACKEND.md             # contract with gurgles.beer API
  ROADMAP.md             # V1 plan → post-V1 ideas
  PLATFORM_NOTES.md      # Windows-dev + Mac-signing workflow notes
  SIGNING.md             # one-time Play Store + TestFlight setup
  superpowers/plans/     # per-milestone implementation plans
test/                    # widget + component tests
codemagic.yaml           # CI/CD: debug + release workflows for both stores
```

## Working agreements

- Keep the V1 surface small. Resist adding features before shipping to both stores.
- Placeholder art is fine. Do NOT block on art — the engine reads from `assets/svg/` and assets are swappable without code changes.
- Reuse the existing backend. Do not build new server infrastructure for V1.
- Every new gameplay system gets a short note in `docs/GAME_DESIGN.md` so tuning values live alongside rationale.
- Prefer Flame's built-in components over hand-rolled game loops — *except* where they've been fought and lost (parallax of SVGs, effects on `TextComponent`); see `STATUS.md` gotchas before reaching for them.
- **CI/CD is CodeMagic** (`codemagic.yaml` at the repo root). Push to `main` runs Android + iOS debug builds. Release builds trigger on git tags `v*` and need the signing setup in `docs/SIGNING.md`.

## Related repos

- Web game: `HoldTheHooch` — Phaser 3, CDN-loaded, served from `gurgles.beer`.
- This repo: `HoldTheHoochMobile` — Flutter + Flame, iOS + Android.

## Current state (check before making changes)

See [docs/STATUS.md](docs/STATUS.md) for the live snapshot. Contains what's playable, which milestones are done, known issues, and — importantly — a **Gotchas** section capturing non-obvious framework quirks already hit (Flame camera viewfinder defaults, `Theme.of` in `initState`, keyboard-resized GameWidget, OpacityEffect on TextComponent, etc.). Read it before diving in so you don't rediscover the same bugs.

## Workflow

This project uses the `superpowers` plugin skills as standard practice. These are not optional "nice to have"s — they exist because earlier sessions burned hours on avoidable problems (shotgun fixing, untested claims of completion, silent doc drift). Apply them whenever they match.

### When starting a new piece of work

- **Feature / milestone:** invoke `superpowers:writing-plans`. Produce a concrete plan before touching code. Plan gets committed under `docs/superpowers/plans/` (create if missing).
- **New gameplay system:** invoke `superpowers:brainstorming` first if requirements are fuzzy; otherwise go straight to `writing-plans`.
- **Any non-trivial bug:** invoke `superpowers:systematic-debugging`. **The iron law: no fixes without root-cause investigation first.** Add diagnostic instrumentation, gather evidence, form a single hypothesis, test minimally, verify.

### When writing code

- **Before implementation code:** invoke `superpowers:test-driven-development`. Write the failing test first. This is especially important for component physics / balance logic / collision filtering — the places we've already regressed.
- **Trust internal framework guarantees.** Don't add defensive null checks for things framework contracts forbid. Validate at boundaries (user input, network, SharedPreferences).
- **No comments that restate the code.** Only comment the `WHY` when non-obvious — a hidden constraint, a subtle invariant, a workaround for a specific bug.

### When claiming something is done

- **Before saying "done":** invoke `superpowers:verification-before-completion`. Run `flutter analyze`, `flutter test`, and (for gameplay changes) **install on the device and play the affected flow**. Code that type-checks is not code that works.
- **Before committing:** invoke `superpowers:requesting-code-review` for major features, or at least for any PR-equivalent chunk of work.

### Debugging hard-earned lessons

From past sessions, these are the failure modes we have already lost time to. Match and prevent:

- **Shotgun fixing without evidence.** Symptom: proposing 4 different fixes in one response hoping one sticks. Remedy: return to Phase 1 of `systematic-debugging`. Add diagnostics; read logs; form ONE hypothesis at a time.
- **`debugPrint` / `dev.log` doesn't reach `adb logcat` reliably on Android 15 debug APKs.** On-screen diagnostic HUD (e.g. a live `TextComponent` showing state) is a more reliable feedback loop than log-chasing. Don't sink 20 minutes into logcat filters; put a yellow text overlay on the screen.
- **Doc drift is a silent tax.** At the end of each session, update `docs/STATUS.md` if state has changed. Update `docs/ROADMAP.md` if milestones have moved. Claims in docs become ground truth for the next session; keeping them honest is load-bearing.
- **Don't claim a fix works without testing it on a device.** If the task is UI or gameplay, install on the phone and play the affected flow. If the task can't be device-tested (e.g. a CI tweak), say so explicitly rather than implying a build/test pass means it works.

### Memory + persistence

- Use `docs/STATUS.md` for current-state and known-issues (long-lived, shared across sessions).
- Use `docs/ROADMAP.md` for milestone plans.
- Use tasks (TodoWrite) within a session for step-by-step progress.
- Use `memory/` (auto memory) for facts about the user or collaboration preferences that carry across sessions.

Plans, tasks, and code don't belong in memory. Memory is for durable context about the human collaborator and their environment.
