# Project Status — HoldTheHooch Mobile

_Last updated: 2026-04-19 (post code-review audit)_

Snapshot of where the project is, what's working, what isn't, and what to pick up next session. Refreshed after a full-codebase review; known doc drift corrected.

## TL;DR

Working Flutter + Flame 2D side-scrolling endless runner on Android. Installable debug APK running on Pixel 8 Pro + Samsung S26 Ultra via wireless debugging. Core loop is playable: tap right to jump, drag left to balance the hooch, don't hit obstacles, don't spill. Real SVG art from the web game is in, parallax backdrop scrolls, score submits to `gurgles.beer`. **Collectibles crash on pickup — root cause known, fix pending.** iOS not yet built.

## What's playable today

- **Menu** → name entry (persisted locally) → **Start** → game scene → **Game Over** overlay → **Retry** / **Menu**.
- Gurgles runs (sprite swaps between run and jump pose — no animated run cycle).
- **Tap right half** → variable-height jump (hold up to 220 ms for higher).
- **Drag left half horizontally** → counter-tilt the hooch toward center.
- Passive hooch wobble builds tilt over time; every jump adds a random tilt impulse.
- **Spill meter** (red bar below score) fills when `|tilt| > 0.7` and drains when `|tilt| < 0.4`. 100% = game over.
- Obstacles (root / rock / mushroom / log) spawn at speed-dependent intervals and end the run on collision. Per-obstacle tight hitboxes are authored (see `lib/components/obstacle.dart:40-63`).
- Collectibles (herb / hops / potion) spawn at three height tiers. **Pickup crashes today** (see Critical issues).
- Parallax: distant mountains (0.15x) + forest trees (0.45x) + tiled ground (1.0x).
- Dark-navy night sky backdrop (matched to `bg-mountains.svg` gradient top to avoid horizontal seam).
- Score: +10 per second elapsed + collectible points, shown top-center.
- Difficulty curve: scroll speed ramps 1.0x → 2.0x over 180 seconds. **Wobble amplitude ramp is specced but not implemented.**
- **Game Over** overlay shows score, persists best-score locally, submits to `gurgles.beer` (silently; offline still shows score but is **not** queued for retry despite [docs/BACKEND.md](BACKEND.md) promising otherwise).

## Milestone progress

See [docs/ROADMAP.md](ROADMAP.md) for the detailed per-milestone plan.

- **M1 — Scaffold** ✅ Complete.
- **M2 — Core run loop** ✅ Complete.
- **M3 — Hooch balance** ✅ Complete. (Wobble amplitude scaling per difficulty is missing — deferred to M4.)
- **M4 — Content pass** ✅ Complete.
  - All 4 obstacle kinds: ✅ in, hitboxes tuned.
  - Collectibles (herb/hops/potion): ✅ working, three reachable tiers, score popup on pickup.
  - Score multiplier (+0.1x per 10s, capped 3x): ✅ implemented.
  - Potion spill-drain bonus: ✅ implemented (4× drain rate for 1 second).
  - Wobble amplitude scaling: ✅ implemented (1.0× → 1.7× over difficultyRampSeconds).
- **M5 — Polish & assets** ⏳ Partial. Real SVGs in, parallax in, spill meter UI in, score popup in (crashes). No SFX, no run-cycle animation, no particles, no tankard rotation tied to tilt, no leaderboard scene.
- **M6 — Store prep** ❌ Not started.

## Tech stack (as built)

- Flutter 3.41.4 stable, Dart 3.11.1.
- Flame 1.37, flame_svg 1.12, flutter_svg, shared_preferences, http, sensors_plus (**unused — candidate for removal**).
- App id: `beer.gurgles.hold_the_hooch`, display name "Hold the Hooch".
- Targets: Android (tested on Pixel 8 Pro + Samsung S26 Ultra), iOS (scaffolded, not yet built).
- Backend: existing `gurgles.beer` Express+SQLite, reused unchanged.

## Directory layout

```
lib/
  main.dart                           # app entry, portrait-only, MaterialApp
  components/
    gurgles.dart                      # Gurgles + tankard sprite + jump physics
    hooch_balance.dart                # pure state: tilt + spill, passive wobble
    ground.dart                       # tiled bg-ground.svg strip at screen bottom
    obstacle.dart                     # 4 kinds, per-kind RectangleHitbox sizing
    collectible.dart                  # 3 kinds (herb/hops/potion), active hitbox
    parallax_bg.dart                  # hand-rolled tiled SVG parallax layer
    spill_meter.dart                  # red fill bar driven by balance.spillPercent
    score_popup.dart                  # floating +N text on pickup (CRASHES, see below)
  scenes/
    menu_screen.dart                  # Flutter widget, name entry + Start
    game_screen.dart                  # hosts FlameGame, wires input via Listener
    game_scene.dart                   # FlameGame subclass, all gameplay wiring
    game_over_overlay.dart            # Flame overlay, score submit, retry/menu
  systems/
    obstacle_manager.dart             # spawn cadence based on speed
    collectible_manager.dart          # spawn cadence + height tiers per kind
  services/
    api_client.dart                   # POST /api/scores + GET /api/scores/top
    local_store.dart                  # SharedPreferences wrapper
  config/
    game_config.dart                  # all tuning constants (single source)
  utils/
    routes.dart                       # fadeRoute() helper
assets/
  svg/                                # 14 SVGs pulled from web-game master
  images/, audio/                     # placeholders (.gitkeep)
docs/
  CLAUDE.md (at root), GAME_DESIGN.md, ART-GUIDE.md, AUDIO-GUIDE.md,
  BACKEND.md, ROADMAP.md, PLATFORM_NOTES.md, STATUS.md (this file)
test/
  widget_test.dart                    # single smoke test against GameConfig
android/ ios/                         # generated by flutter create
.github/workflows/ci.yml              # analyze + test + debug APK on push/PR
```

## How to run

```bash
flutter pub get
flutter analyze
flutter test

# Android debug build on a wireless device:
$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe pair <ip>:<pair-port> <code>
$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe connect <ip>:<conn-port>
flutter devices
flutter build apk --debug
flutter install -d <device-id> --debug
```

iOS build hasn't been attempted yet. Intent per [docs/PLATFORM_NOTES.md](PLATFORM_NOTES.md): set up Xcode Cloud before M6 so TestFlight builds happen on push.

## Known issues & deferred work

| # | Issue | Severity | Where |
|---|-------|----------|-------|
| 1 | **Collectible pickup crashes the game** | **Critical** | `lib/components/score_popup.dart:30` — `OpacityEffect` requires target to implement `OpacityProvider`; `TextComponent` does not. Fix: implement `OpacityProvider` on `ScorePopup` or drop the fade effect. |
| 2 | **Potions are physically unreachable** | Critical | Peak jump height ≈ 92 px (`jumpVelocityMax² / (2·gravity)`), potion spawns at 260 px. Hops at 160 is marginal. Either raise jump ceiling or drop collectible height tiers. |
| 6 | Score retry queue unimplemented | Med | [BACKEND.md](BACKEND.md) promises failed submissions are queued in SharedPreferences and retried. `ApiClient.submitScore` just returns false on failure. |
| 7 | `ScorePopup`s mid-animation survive restart | Low | `GameScene.restart()` doesn't purge them. `balance._phase` also not reset. |
| 8 | `sensors_plus` dependency unused | Low | Either wire up the accelerometer tilt control (optional input per [GAME_DESIGN.md](GAME_DESIGN.md)) or remove from `pubspec.yaml`. |
| 9 | `Obstacle` / `CollectibleManager` are 90% duplicated | Low | Extract abstract `SpawnManager<T>` base before adding a third spawner. |
| 10 | Spawn cadence formulas are opaque | Low | Magic numbers in `obstacle_manager.dart:28-31` and `collectible_manager.dart:33-36`. Pull into `GameConfig` with named constants. |
| 11 | Obstacle/collectible scroll speed frozen at spawn | Low | Each instance captures `scrollSpeed` at spawn time; doesn't update as world speed ramps. Results in visible "catch up" lag at higher speeds. Pull `scrollSpeedProvider()` in `update()`. |
| 12 | `platform` field in score submission | Low | `defaultTargetPlatform.name.toLowerCase()` returns `'android'`/`'ios'` on device but `'linux'`/etc. on desktop. Fine for mobile-only ship; harden before store submission. |
| 13 | Gurgles lands 0.5px above `_groundY` | Low | Masked by 2-pixel tolerance in `onGround`. Cosmetic only. |
| 14 | Run cycle sprite swap is binary (run ↔ jump) | Low | Web game has one gurgles pose; a 6-frame cycle is in [ART-GUIDE.md](ART-GUIDE.md). Defer to polish pass. |
| 15 | No SFX / music | Med | Brief in [AUDIO-GUIDE.md](AUDIO-GUIDE.md); nothing wired via `flame_audio`. |
| 16 | Test suite is effectively empty | Med | One smoke test on `GameConfig`. Min viable set specced in [ROADMAP.md](ROADMAP.md) M4/M5. |
| 17 | No iOS build attempted | High (for ship) | Requires a macOS session; Xcode Cloud plan in [PLATFORM_NOTES.md](PLATFORM_NOTES.md). |

## Gotchas (don't repeat these)

- **Flame 1.37's default `CameraComponent` viewfinder is center-anchored.** World-(0,0) lands at screen center. Pin `camera.viewfinder.anchor = Anchor.topLeft` in `onLoad` if you want top-left origin semantics.
- **`Theme.of(context)` cannot be called from `initState`.** Use `defaultTargetPlatform` from `package:flutter/foundation.dart` if you only need the platform name.
- **Scaffold + keyboard = shrunken GameWidget.** If the name-entry TextField is still focused when navigating to the game, Scaffold resizes for the keyboard inset and Flame's canvas ends up ~2/3 height. Fix: `FocusManager.instance.primaryFocus?.unfocus()` before pushing + `resizeToAvoidBottomInset: false` on the game Scaffold.
- **Strict `y >= groundY` checks break on subpixel drift.** Add tolerance or clamp on snap.
- **Prefer `Listener` + `onPointerDown` over `GestureDetector` or Flame's `TapCallbacks`** when embedding Flame in Flutter — pointer events bypass the gesture arena.
- **`debugPrint` / `dev.log` from a debug APK on Android 15 Pixel does not surface reliably through `adb logcat`.** On-screen diagnostic HUD (live `TextComponent`) is faster than chasing logs.
- **`flame_svg`'s `Svg.render(canvas, size)` doesn't take a position argument.** Use `canvas.translate()` for layered tiling.
- **Flame's built-in `ParallaxComponent` requires rasters.** We hand-rolled `ParallaxLayer` wrapping `Svg.render` in a manual tile loop.
- **`OpacityEffect` requires its target to implement `OpacityProvider`.** `TextComponent` does not — applying `OpacityEffect` to one throws on mount. Either mix in `HasPaint` + implement `OpacityProvider`, or skip the fade.
- **Passive hitboxes only notify the active-side component.** If you want both sides to get the callback (e.g. collectible self-removing on pickup), both hitboxes need to be active.
- **Match Flame `backgroundColor()` to layered-SVG gradient tops.** `bg-mountains.svg` gradient starts at `#1A1A3E`; if Flame's canvas bg is anything else, you get a horizontal seam where the mountains layer begins.

## Immediate next steps (in order)

1. **Fix collectible crash** (#1) — minimal `ScorePopup` fix using `systematic-debugging` + `test-driven-development` per [CLAUDE.md](../CLAUDE.md).
2. **Retune collectible heights or jump physics** (#2) so potions/hops are reachable.
3. **Purge ScorePopups in restart()** (#7) — cheap, add while touching the popup code.
4. **Minimum-viable test suite** (#16) — `HoochBalance` unit tests, GameConfig invariants, ScorePopup smoke test, hitbox bounds tests, restart cleanup test.
5. **Implement score multiplier** (#3) + **potion spill-drain bonus** (#4) + **wobble ramp** (#5) — finish M4.
6. **Doc drift audit** — this pass corrected several; keep STATUS.md current at every end-of-session.

## Infrastructure state (end of session)

- GitHub repo: `https://github.com/GazeboGangsta/HoldTheHoochMobile` (public, default branch `main`).
- GitHub wiki: `https://github.com/GazeboGangsta/HoldTheHoochMobile/wiki` (art + audio briefs mirrored).
- CI: `.github/workflows/ci.yml` — analyze + test + debug APK on push/PR to main.
- Samsung S26 Ultra: connected at `192.168.4.25:38097` for wireless debugging. Will need re-pair next session.
- All background build processes: stopped.
