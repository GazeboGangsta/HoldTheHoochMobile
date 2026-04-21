# Project Status — HoldTheHooch Mobile

_Last updated: 2026-04-21 (obstacle + collectible pixel-art refresh on feat/obstacle-collectible-refresh)_

Snapshot of where the project is, what's working, what isn't, and what to pick up next session. Refreshed after a full-codebase review; known doc drift corrected.

## TL;DR

Working Flutter + Flame 2D side-scrolling endless runner on Android and iOS. Samsung S26 Ultra via wireless debugging; iOS via TestFlight (`v0.1.1`, build 2 shipped 2026-04-21 — gnome animations + app icon + Pine Hills dusk-forest parallax). Core loop is playable via a dedicated bottom control strip (◀ ▶ tilt buttons + ▲ jump). Tankard leans with `balance.tilt` for visible feedback. 13-layer Pine Hills parallax scrolls beneath Gurgles. Score submits to `gurgles.beer`, leaderboard scene shows top 50.

Gurgles runs on a real 8-frame sprite animation derived from the `no_hat_gnome` frames in the purchased Game Developer Studio gnome pack. Jump arc is a 7-frame takeoff + 12-frame airborne loop + 6-frame landing. On game over: 6-frame hurt animation → held dead pose → overlay. Menu screen shows an idling Gurgles above the name field.

## What's playable today

- **Menu** → name entry (persisted locally) → **Start** → game scene → **Game Over** overlay → **Retry** / **Menu**.
- Gurgles: 8-frame run cycle + 7/12/6-frame jump arc + 6-frame hurt + held dead pose, rendered via a `GurglesAnimator` state machine driving one `SpriteAnimationComponent`. Tankard rides above his head as a separate SVG overlay that rotates with tilt.
- Bottom **control strip**: ◀ tilt-left, ▶ tilt-right, ▲ jump (right-aligned). Tap-and-hold for continuous action. Play area sits above the strip; no gestures needed in the play area, so edge back-gestures don't collide.
- **Tankard visually leans** with `balance.tilt` (up to ~34°) so the player can see which way the hooch is tipping.
- Passive hooch wobble builds tilt over time; every jump adds a random tilt impulse.
- **Spill meter** (red bar below score) fills when `|tilt| > 0.7` and drains when `|tilt| < 0.4`. 100% = game over.
- **Obstacles** — 4 kinds, weighted spawn: stone 35% (60×49 tripping stone), rock 25% (109×124, planted 30 px into dirt), mushroom 20% (82×82, 8-frame bob animation), log 20% (150×82, planted 17 px into dirt, 4-frame sway animation). Pixel-art from the Mushrooms / props packs. Per-kind tight hitboxes tuned against the actual sprite silhouette (`lib/components/obstacle.dart:hitboxFor`). `Obstacle.yOffsetFor` sinks rock + log below groundY so tall shapes read as "planted" rather than "floating".
- **Collectibles** — 5 kinds, weighted spawn: fruitCommon 55% (cherry / strawberry / tomato, 3 visual variants, 10 pts), fruitMedium 25% (apple / orange / pumpkin, 50 pts), fruitRare 10% (golden apple, 100 pts), crystal 5% (10 gem variants from Nature Full, 150 pts), potion 5% (Onocentaur red heart-bottle, 200 pts + grants 1s 4× spill-drain). Sparkle bursts colour-coded per tier: red → orange → gold → purple → blue. Crystal + potion get expanding halo rings on pickup.
- **Parallax**: 13-layer Pine Hills dusk-forest backdrop — sky gradient → back cloud field → 4 independent-speed drift clouds (8/14/22 px/s + one -10 px/s counter-breeze) → back mountains (0.12×) → mid hills (0.22×) → mid forest (0.40×) → front_trees2 (0.86×, behind Gurgles) → front_trees1 (0.85×, behind Gurgles) → front_grass (1.0×, behind Gurgles) → **[Gurgles]** → front_leafs (1.0×, only layer in front of player). Free asset pack from myaumya.itch.io, license bundled. 320×180 pixel-art, rendered with `FilterQuality.none` for crisp scaling.
- Dusk sky backdrop (`backgroundColor = 0xFF77B8DC`, matched to Pine Hills `00_background.png` top gradient). Replaces the previous `#1A1A3E` night-navy.
- Score: +10 per second elapsed + collectible points, shown top-center.
- Difficulty curve: scroll speed ramps 1.0x → 2.0x and wobble amplitude ramps 1.0× → 1.7× over 180 seconds.
- **Game Over** overlay shows score, persists best-score locally, submits to `gurgles.beer` (silently; offline still shows score but is **not** queued for retry despite [docs/BACKEND.md](BACKEND.md) promising otherwise).
- **Leaderboard** — menu button → scrollable top-50 list from `gurgles.beer`, pull-to-refresh, current player rows highlighted.
- **Splash particles** — amber droplets with occasional cream highlights burst from the tankard rim whenever the hooch tilts into the spill zone; emission rate scales with how far past threshold the tilt sits. On spill-death a 30-droplet burst plays for 600ms before the game-over overlay appears — currently subtle on-device, a full-screen "death" effect is queued in [ROADMAP.md § Post-V1 ideas](ROADMAP.md).
- **Sparkle particles** — kind-specific bursts on collectible pickup, 5 tiers: 6 small red (fruitCommon) → 8 small orange (fruitMedium) → 10 mid gold (fruitRare) → 14 mid purple + expanding halo (crystal) → 16 large blue + expanding halo (potion).

## Milestone progress

See [docs/ROADMAP.md](ROADMAP.md) for the detailed per-milestone plan.

- **M1 — Scaffold** ✅ Complete.
- **M2 — Core run loop** ✅ Complete.
- **M3 — Hooch balance** ✅ Complete.
- **M4 — Content pass** ✅ Complete.
  - All 4 obstacle kinds: ✅ in, hitboxes tuned.
  - Collectibles (5 kinds: fruitCommon/fruitMedium/fruitRare/crystal/potion): ✅ working, four reachable height tiers, score popup on pickup.
  - Score multiplier (+0.1x per 10s, capped 3x): ✅ implemented.
  - Potion spill-drain bonus: ✅ implemented (4× drain rate for 1 second).
  - Wobble amplitude scaling: ✅ implemented (1.0× → 1.7× over difficultyRampSeconds).
- **M5 — Polish & assets** ⏳ Partial. Real SVGs in (legacy), 13-layer Pine Hills dusk parallax + 4-cloud drift (M5a, `feat/branding-background`), spill meter UI in, score popup in, tankard rotation tied to tilt, dedicated control strip, leaderboard scene live, splash + sparkle particles live (M5a), 8-frame run cycle + 7/12/6-frame jump arc + 6-frame hurt + dead pose via the purchased `no_hat_gnome` gnome pack + menu idle animation (M5a, `feat/gnome-animations`), app icon generated via `flutter_launcher_icons` (M6b partial), obstacle + collectible pixel-art refresh (M5a, `feat/obstacle-collectible-refresh`) — dropped `root` obstacle + added `stone`, renamed `herb`/`hops` → `fruitCommon`/`fruitMedium` + added `fruitRare` and `crystal` tiers, mushroom + log now animated, per-kind sparkle burst colours + crystal halo. Sprites sliced from Nature Full + Onocentaur potions + Animated Mushrooms + individual fruit/veg packs (all commercial-OK; inventory in [OBSTACLE-COLLECTIBLE-ASSETS.md](OBSTACLE-COLLECTIBLE-ASSETS.md)). Still missing: SFX (M5b), tutorial overlay + settings (M5c), splash screen + privacy policy (M6b remainder).
- **M6 — Store prep** ⏳ Two iOS builds shipped to TestFlight: `v0.1.0` (2026-04-21) and `v0.1.1` (2026-04-21 — gnome animations + app icon + Pine Hills parallax). Signing pipeline on CodeMagic (canonical `ios_signing` managed flow) verified end-to-end with cert + profile in CodeMagic's team-level stores. App icon: ✅. M6b remainder: splash screen, privacy policy, store listings. M6a decision on Xcode Cloud vs Actions macOS runner still pending (CodeMagic is working fine meanwhile).
- **M7 — Leaderboard integrity** ❌ Not started. Planned before public M6 release — leaderboard currently accepts any unauthenticated `POST /api/scores`.

## Tech stack (as built)

- Flutter 3.41.4 stable, Dart 3.11.1.
- Flame 1.37, flame_svg 1.12, flutter_svg, shared_preferences, http, sensors_plus (**unused — candidate for removal**).
- App id: `beer.gurgles.holdTheHooch`, display name "Hold the Hooch".
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
    collectible.dart                  # 5 kinds (fruitCommon/fruitMedium/fruitRare/crystal/potion), active hitbox, per-kind sprite-variant RNG
    parallax_bg.dart                  # hand-rolled tiled SVG parallax layer
    spill_meter.dart                  # red fill bar driven by balance.spillPercent
    score_popup.dart                  # floating +N text on pickup
    splash_emitter.dart               # hybrid burst+trickle splash on spill + game-over flourish
    sparkle_burst.dart                # per-kind sparkle burst factory on pickup
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
  game_config_test.dart               # GameConfig invariants (ordering + durations + torque-beats-drift + analytic jump peak)
  hooch_balance_test.dart             # wobble ramp, drift bias, spill-drain, tilt clamp, jump impulse
  multiplier_test.dart                # score multiplier pure function
  score_popup_test.dart               # pickup-animation regression guard
  tankard_rotation_test.dart          # tankardAngleForTilt pure fn
  obstacle_hitbox_test.dart           # per-kind hitbox ⊂ sprite + area fairness
  collectible_hitbox_test.dart        # sizing inset correctness
  game_scene_restart_test.dart        # restart() clears obstacles/collectibles/popups
  gurgles_physics_test.dart           # peak-jump height guards potion-tier reach
  leaderboard_utils_test.dart         # formatScore pure fn
  leaderboard_entry_row_test.dart     # widget test: rank/name/score/highlight
  splash_emitter_test.dart            # emitter state machine + rate math
  sparkle_burst_test.dart             # per-kind config ordering + mount smoke test
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

**iOS + Android debug builds confirmed working through CodeMagic** (2026-04-20). Both workflows (`ios-debug`, `android-debug`) pass on push-to-main. Release workflows (`android-release`, `ios-release`) are configured but need signing credentials uploaded per [docs/SIGNING.md](SIGNING.md).

## Known issues & deferred work

| # | Issue | Severity | Where |
|---|-------|----------|-------|
| 18 | **Drift/spill curve tuning** | Low | Partially addressed: tankard now visibly leans toward drift direction (closes the legibility half). Remaining: the spill meter stays empty for the first ~10s and then fills steadily once wobble-amp ramp kicks in — pressure should ramp smoothly from t=0 instead of cliff. Retune `driftRateBase` / `wobbleAmplitudeMaxMultiplier` / spill `spillFillRate` when next in a tuning mood. |
| 6 | Score retry queue unimplemented | Med | [BACKEND.md](BACKEND.md) promises failed submissions are queued in SharedPreferences and retried. `ApiClient.submitScore` just returns false on failure. |
| 8 | `sensors_plus` dependency unused | Low | Either wire up the accelerometer tilt control (optional input per [GAME_DESIGN.md](GAME_DESIGN.md)) or remove from `pubspec.yaml`. |
| 9 | `Obstacle` / `CollectibleManager` are 90% duplicated | Low | Extract abstract `SpawnManager<T>` base before adding a third spawner. |
| 10 | Spawn cadence formulas are opaque | Low | Magic numbers in `obstacle_manager.dart:28-31` and `collectible_manager.dart:33-36`. Pull into `GameConfig` with named constants. |
| 11 | Obstacle/collectible scroll speed frozen at spawn | Low | Each instance captures `scrollSpeed` at spawn time; doesn't update as world speed ramps. Results in visible "catch up" lag at higher speeds. Pull `scrollSpeedProvider()` in `update()`. |
| 12 | `platform` field in score submission | Low | `defaultTargetPlatform.name.toLowerCase()` returns `'android'`/`'ios'` on device but `'linux'`/etc. on desktop. Fine for mobile-only ship; harden before store submission. |
| 13 | Gurgles lands 0.5px above `_groundY` | Low | Masked by 2-pixel tolerance in `onGround`. Cosmetic only. |
| ~~14~~ | ~~Run cycle sprite swap is binary (run ↔ jump)~~ | ~~Low~~ | **Closed 2026-04-21.** Replaced with 8-frame run cycle + 7/12/6-frame jump arc + 6-frame hurt + dead pose via the no_hat_gnome gnome-pack integration on `feat/gnome-animations`. See docs/ART-PACK-INVENTORY.md and docs/superpowers/plans/2026-04-21-gnome-animation-integration.md. |
| 15 | No SFX / music | Med | Brief in [AUDIO-GUIDE.md](AUDIO-GUIDE.md); nothing wired via `flame_audio`. |
| ~~16~~ | ~~Test suite is effectively empty~~ | ~~Med~~ | **Closed 2026-04-20.** M4c minimum-viable suite landed — 58 tests covering HoochBalance clamps, GameConfig invariants, Obstacle/Collectible hitbox bounds, GameScene.restart() cleanup, Gurgles peak-jump. |
| ~~17~~ | ~~No iOS build attempted~~ | ~~High (for ship)~~ | **Closed 2026-04-20.** iOS no-codesign build passes via CodeMagic `ios-debug` workflow. Release workflow (`ios-release`) configured but needs Apple Developer signing credentials per [SIGNING.md](SIGNING.md). |

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
- **`ApiClient.fetchTop` now throws on failure** (used to silently return `[]`). Callers must catch or wrap in a `FutureBuilder` with error handling.
- **Calling `parent?.add(child)` from inside `update()` causes `ConcurrentModificationError` in the test harness.** In tests without `GameWidget`, `FlameGame.isMounted` stays false so `Component.add` takes the direct-modify branch instead of the lifecycle queue. If you're already iterating the parent's children (and Flame is iterating yours via `updateTree`), the add mutates the live set. Workaround used in `SplashEmitter`: override `updateTree`, buffer adds in a `_pendingEmissions` list, flush after the children-iteration loop. Same class of issue `ScorePopup` sidesteps by computing motion in a custom `update` override rather than effects on `TextComponent`.
- **CodeMagic's "automatic iOS code signing" is broken for first-time Apple Developer accounts.** The `ios_signing` declarative block claims it auto-creates the Distribution cert + App Store provisioning profile via the App Store Connect API key integration. In practice: (a) the pre-flight profile-existence check runs before any script does, (b) `app-store-connect fetch-signing-files --create` silently fails to save the generated private key (`"Cannot save Signing Certificates without certificate private key"`), leaving orphaned certs on Apple's side that can't be used for signing on subsequent runs. **The working path** (proven 2026-04-21): generate the RSA private key + CSR on Windows with OpenSSL, upload CSR to Apple Developer Portal → download `.cer` → combine cert+key into `.p12` → upload `.p12` to CodeMagic Code signing identities → manually create the App Store provisioning profile at Apple Developer Portal → upload the `.mobileprovision` to CodeMagic's profile store. Then the canonical `ios_signing` block finds both and just works. See [SIGNING.md](SIGNING.md) + `ios-signing/` for the full OpenSSL commands + files.
- **`package:image` is a dev-only dep.** The asset curation script at `tools/build_gurgles_sprites.dart` uses it to compute the union content bounding box across all shipping frames + crop + resize. Raw frames live in `art-source/gnomes/` (gitignored) and are consumed by the script, not by the app. Do NOT import `package:image` from `lib/` — it's dev_dependencies only.
- **Flame 1.37's `SpriteAnimationWidget` requires BOTH `animation` AND `animationTicker` as constructor args.** The ticker isn't auto-created in 1.37 (unlike older versions). Construct it explicitly via `animation.createTicker()` and store it in state alongside the animation (see `lib/components/gurgles_idle_widget.dart` for the pattern).
- **Flutter asset resolver is non-recursive for trailing-slash entries.** `assets/images/` alone does NOT recursively include subfolders. Each subfolder must be listed explicitly in pubspec.yaml — see the `assets/images/gurgles/<anim>/` entries.
- **Flame's built-in `ParallaxComponent` is geometric per-layer, not arbitrary.** Velocity for layer N is `baseVelocity × velocityMultiplierDelta^N` — so you can't set layer 3 faster than layer 5. That's why `RasterParallaxLayer` (`lib/components/raster_parallax_layer.dart`) + `CloudDrift` (`lib/components/cloud_drift.dart`) are hand-rolled: they let each layer own its speed factor / px-per-second, which is required for a parallax scene where cloud drift is independent of ground scroll.
- **Slicing pixel-art atlases requires per-row y-offset calibration.** The Nature Full atlas (160×208, 16×16 cells) uses non-uniform row heights (trees span 2 cells, later rows are 1 cell). Crystal row is at y=160 (not y=144 as a uniform-grid assumption would suggest). When adding new categories from the same atlas, open `assets/third_party/nature_full/global.png` in a 1:1 viewer, count pixel rows from the top, and hardcode the row y-offset in `tools/build_obstacle_collectible_sprites.dart`. Visually spot-check each new output before committing.
- **CodeMagic's GitHub webhook didn't fire on the `v0.1.1` tag push** (2026-04-21). The `ios-release` workflow has `triggering: events: [tag]` configured correctly, but the tag push didn't automatically queue a build. Manual trigger via API worked: `curl -X POST -H "x-auth-token: $TOKEN" -H "Content-Type: application/json" https://api.codemagic.io/builds -d '{"appId":"69e5621f551ec5674ead805e","workflowId":"ios-release","tag":"v0.1.1"}'`. Webhook integration may need reconnecting in CodeMagic → app settings → repository integrations.

## Immediate next steps (in order)

1. **Collect TestFlight feedback** — `v0.1.1` (build 2) shipped 2026-04-21; IPA in Apple processing. Your iPhone friend is the first external tester. Their feedback steers priorities.
2. **M5c remaining UX** — tutorial overlay (first 1–2s of first run), settings (music / haptics / control toggles). Pure code, no asset blocker.
3. **M7a — Leaderboard integrity** (device-bound identity + server HMAC + admin endpoint). Before M6 public release. See [ROADMAP.md § M7a](ROADMAP.md).
4. **M5b audio pass** — wire SFX per [AUDIO-GUIDE.md](AUDIO-GUIDE.md). Blocked on audio delivery.
5. **M6b remaining** — splash screen, privacy policy, store listings. App icon ✅.
6. **Investigate CodeMagic webhook** — tag-push trigger didn't fire on `v0.1.1`. Check app → repository integrations. Workaround in place (manual API trigger).
7. **Design call on finite-hooch spill model** (see [ROADMAP.md § Design ideas to consider](ROADMAP.md)) — decide before M6 ship.

## Infrastructure state (end of session)

- GitHub repo: `https://github.com/GazeboGangsta/HoldTheHoochMobile` (public, default branch `main`).
- GitHub wiki: `https://github.com/GazeboGangsta/HoldTheHoochMobile/wiki` (art + audio briefs mirrored).
- Local CI: `.github/workflows/ci.yml` — analyze + test + debug APK on push/PR to main. Still useful as fast PR gate.
- **CodeMagic pipeline live**. App id `69e5621f551ec5674ead805e`. Four workflows in `codemagic.yaml`:
  - `android-debug` (linux_x2) — push to main, ~2 min, produces APK. ✅ verified.
  - `ios-debug` (mac_mini_m2) — push to main, ~2m23s, produces `Runner.app.zip`. ✅ verified.
  - `android-release` (linux_x2) — tag `v*` triggered. Needs env group `android_signing`. Not yet exercised.
  - `ios-release` (mac_mini_m2) — tag `v*` triggered. ✅ **Verified end-to-end on 2026-04-21 for both `v0.1.0` and `v0.1.1`**. ~5 min build time, produces a signed IPA that uploads to TestFlight. **Webhook did not fire on the v0.1.1 tag push** — had to manually trigger via the CodeMagic API (see Gotchas). Uses canonical `ios_signing` managed flow + manual one-time uploads of (a) `ios_distribution.p12` to CodeMagic Code signing identities and (b) the `beer.gurgles.holdTheHooch` App Store provisioning profile to CodeMagic's profile store (CodeMagic's documented auto-creation-via-API-key is broken for first-time accounts — see [Gotchas](#gotchas-dont-repeat-these)).
  See [docs/SIGNING.md](SIGNING.md) for the one-time setup of the release paths.
- Samsung S26 Ultra: connected at `adb-R5GL12X3ZXH-fontbc._adb-tls-connect._tcp` via mDNS auto-discovery (IP:port changes per wireless-debugging session; mDNS hostname is stable). Will need re-enable wireless debugging next session.
- **Local signing artefacts** at `c:\apps\HoldTheHoochMobile\ios-signing\` (gitignored): `ios_distribution.key` (RSA private key, keep safe!), `ios_distribution.csr`, `ios_distribution.cer` (Apple Distribution cert), `ios_distribution.p12` (cert+key bundle uploaded to CodeMagic), `p12_password.txt`. Required for re-uploading the cert to CodeMagic if the team-level store is ever cleared.
- `gurgles.beer` backend — no admin panel or reset endpoint; leaderboard clears currently require nudging the agent in the backend repo. Addressed by M7a.
- All background build processes: stopped.
- **Security:** the CodeMagic API token lives at `c:\apps\HoldTheHoochMobile\secret.md` (gitignored). Do NOT paste it into chat again — rotate via CodeMagic UI → Teams → Personal Access Tokens if ever leaked.
