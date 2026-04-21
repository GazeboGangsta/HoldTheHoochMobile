# Roadmap — HoldTheHooch Mobile V1

Live snapshot of progress + detailed per-milestone plans. [STATUS.md](STATUS.md) has the end-of-session summary and known issues table.

Conventions:
- ✅ Done and verified on device.
- ⏳ In progress — some items done, some not.
- ❌ Not started.
- ⚠️ Implemented but broken / needs rework.

## M1 — Project scaffold ✅

- [x] Directory layout, `CLAUDE.md`, planning docs.
- [x] `flutter create` the app, wire up Flame 1.37 + `flame_svg`.
- [x] SVG pipeline.
- [x] CI: GitHub Actions for lint + test + Android debug build.

## M2 — Core run loop ✅

- [x] Menu scene with name entry.
- [x] Game scene with scrolling ground + Gurgles running.
- [x] Tap-to-jump with variable height.
- [x] Obstacle spawner with all 4 kinds + collision → Game Over.
- [x] Score HUD + Game Over overlay + Retry/Menu flow.

## M3 — Hooch balance mechanic ✅

- [x] `HoochBalance` component with tilt + passive wobble.
- [x] Drag input on left half → counter-torque.
- [x] Spill meter UI + game-over-on-100%.
- [x] Jump impulse feeds into tilt.

## M4 — Content pass ✅

_Closed 2026-04-20 — minimum-viable test suite (M4c) landed; M4a/M4b already done._

Goal: finish the gameplay systems the design doc calls for.

### M4a — Fix collectibles (first priority)

- [x] **Fix ScorePopup crash** ([STATUS #1](STATUS.md)). `OpacityEffect` on `TextComponent` throws at mount because TextComponent doesn't implement `OpacityProvider`. Either:
  - mix in `HasPaint` and implement `OpacityProvider` so the fade works, or
  - drop the fade and just use `MoveByEffect` with `onComplete: removeFromParent`.
  Use `systematic-debugging` skill + add a failing test first via `test-driven-development`.
- [x] **Potion reachability** ([STATUS #2](STATUS.md)). Peak jump ≈ 92 px, potion spawned at 260 px. Options: raise `jumpVelocityMax` / lower `gravity`, or drop `CollectibleManager._heightForKind()` tiers. Tune with the device in hand.
- [x] **Purge `ScorePopup`s in `GameScene.restart()`** ([STATUS #7](STATUS.md)). Cheap fix while the popup code is open.
- [x] **Reset `HoochBalance._phase` in restart** ([STATUS #7](STATUS.md)).

### M4b — Missing game systems

- [x] **Score multiplier** ([STATUS #3](STATUS.md)). `+0.1x per 10 seconds survived, capped at 3x`. Add `_multiplier` to `GameScene.update`; apply to per-tick and collectible points. Show multiplier in HUD.
- [x] **Potion spill-drain bonus** ([STATUS #4](STATUS.md)). `hooch_balance.dart` grows a `grantSpillDrain(Duration)` method that boosts the drain rate for N seconds. Collectible callback triggers on potion pickup.
- [x] **Wobble amplitude difficulty ramp** ([STATUS #5](STATUS.md)). `HoochBalance.applyDifficulty(double)` currently a dead stub. Wire into `GameScene.update`: `balance.applyDifficulty(_elapsed / GameConfig.difficultyRampSeconds)`. Scale `_wobble` calculation by that multiplier.

### M4c — Minimum viable test suite

Add before M5 polish. Prioritized by ROI (from code review):
- [x] `HoochBalance` unit tests: tilt clamping, spill fill/drain, wobble drift, jump impulse. (16 tests across 5 groups)
- [x] `GameConfig` invariants: `jumpVelocityMax < jumpVelocityMin < 0`, thresholds ordered, durations positive.
- [x] `Obstacle._hitboxFor` + `Collectible` sizing bounds: hitbox is strict subset of sprite size.
- [x] `ScorePopup` render smoke test (once fixed): mount without exception.
- [x] `GameScene.restart()` cleanup: no lingering Obstacles / Collectibles / ScorePopups after restart.
- [x] **Gurgles physics integration** using `flame_test`: peak jump height ≤ potion tier height (once #2 is retuned, this guards against regression).

Add `flame_test` to dev_dependencies.

### M4d — Code quality follow-ups (optional, can slip to M5)

- [ ] Extract `SpawnManager<T>` base class to dedupe obstacle/collectible managers ([STATUS #9](STATUS.md)).
- [ ] Hoist spawn cadence magic numbers into `GameConfig` with named constants ([STATUS #10](STATUS.md)).
- [ ] Pull `scrollSpeedProvider()` inside `Obstacle/Collectible.update` each frame so in-flight entities stay in sync with current world speed ([STATUS #11](STATUS.md)).
- [ ] Either wire `sensors_plus` to optional accelerometer tilt, or remove from `pubspec.yaml` ([STATUS #8](STATUS.md)).
- [ ] Implement **score retry queue** per [BACKEND.md](BACKEND.md) ([STATUS #6](STATUS.md)).

## M5 — Polish & assets ⏳

Goal: make it feel and sound finished.

### M5a — Visuals

- [x] Real SVGs from web game (Gurgles, hooch, obstacles, parallax).
- [x] **13-layer Pine Hills parallax** — dusk-forest backdrop from [myaumya.itch.io](https://myaumya.itch.io/pine-hills-background) (free, commercial-OK license). Sky + 4 independent-speed drift clouds + mountains/hills/forest + front trees (2 layers, one behind Gurgles one for occlusion) + front grass/leafs. New `RasterParallaxLayer` + `CloudDrift` components; see [docs/superpowers/plans/2026-04-21-pine-hills-parallax.md](superpowers/plans/2026-04-21-pine-hills-parallax.md). Replaces the earlier 2-layer SVG night-sky prototype.
- [x] Spill meter bar.
- [x] Dark-navy backdrop matched to mountains gradient (seamless sky).
- [x] Score popup on collectible pickup (⚠️ crashes — fix in M4a).
- [x] **Tankard rotation** tied to `balance.tilt` — visual feedback of how close to spilling. Rotate `_tankard` in `Gurgles.update`: `_tankard.angle = balance.tilt * 0.6` (~35° max lean).
- [x] **Splash particles** on spill — programmatic emission via `SplashEmitter` (hybrid burst + reactive trickle + dramatic game-over flourish, all from the tankard rim).
- [x] **Sparkle particles** on collectible pickup — programmatic, tinted + size-scaled per `CollectibleKind` via `SparkleBurst` (herb green / hops gold / potion blue + expanding halo).
- [x] **8-frame run cycle + full jump/hurt/dead arc** — derivative of `no_hat_gnome` frames from the purchased Game Developer Studio gnome pack. See [ART-PACK-INVENTORY.md](ART-PACK-INVENTORY.md) for license + inventory. Pipeline: `dart run tools/build_gurgles_sprites.dart` curates raw frames into `assets/images/gurgles/<anim>/`. Rendering is driven by `GurglesAnimator` state machine (`lib/components/gurgles_animator.dart`).
- [x] **Hurt pose + dead pose** on game-over — 6-frame hurt animation plays after obstacle hit or spill, then holds on a single-frame dead pose until the overlay appears (unified 600 ms delay via `GameConfig.gameOverHurtDelayMs`).
- [ ] **Obstacle + collectible visual refresh.** Current obstacle art (root / rock / mushroom / log SVGs from the web game) and collectible art (herb / hops / potion) are the main visual mismatch against the Pine Hills pixel-art parallax + gnome-pack character. Goal: source or commission new art that matches the pixel-art aesthetic. Likely path: find a free/commercial pixel-art asset pack on itch.io with forest props (mushrooms, rocks, logs, crystals, fruits) + drop relevant pieces into `assets/images/obstacles/` and `assets/images/collectibles/`. Scope may expand:
  - Adding **new obstacle kinds** (e.g. thorns, puddles, falling branches, hanging vines) — requires new `ObstacleKind` enum values + hitbox authoring.
  - Adding **new collectible kinds** (e.g. berries, mushrooms of different colours, crystal shards) — requires new `CollectibleKind` enum values + per-kind sparkle config + score values.
  - Reusing the asset-curation pattern from [tools/build_gurgles_sprites.dart](../tools/build_gurgles_sprites.dart) if the new pack needs trimming/resizing.
  - Art discipline per [ART-GUIDE.md](ART-GUIDE.md): maintain the hybrid pixel-art-background / smooth-cartoon-character style, OR commit fully to pixel-art for obstacles/collectibles (likely the cleaner choice given Pine Hills is already pixel-art).

### M5b — Audio

Per [AUDIO-GUIDE.md](AUDIO-GUIDE.md). Add `flame_audio` dep. Wire each as the SFX arrives:
- [ ] `sfx-jump.wav` on `handleJumpDown`.
- [ ] `sfx-land.wav` on Gurgles' onGround transition.
- [ ] `sfx-collect-herb/hops/potion.wav` on pickup.
- [ ] `sfx-spill-warning.wav` on first crossing of `spillThreshold`.
- [ ] `sfx-spill-game-over.wav` on spill death.
- [ ] `sfx-collision.wav` on obstacle hit.
- [ ] `sfx-ui-tap.wav` on Start / Retry / Menu.
- [ ] `sfx-new-best.wav` on GameOverOverlay when `score > previousBest`.
- [ ] Optional: `bgm-forest-night.ogg` with settings toggle (default off).

### M5c — Scenes + UX

- [x] **Leaderboard scene** — `GET /api/scores/top`, list top 50. Menu button pushes a new scene with loading / error / empty states and current-player highlighting.
- [x] **Menu idle animation** — Gurgles idles next to the name-entry field on the menu screen via a standalone `GurglesIdleWidget` (no FlameGame needed). 20-frame cycle from the gnome pack's idle animation.
- [ ] **Tutorial overlay** — first 1–2 seconds of first run only. `tap-hint.svg` on right, `drag-hint.svg` on left. Dismiss on first input.
- [ ] **Settings** (lightweight) — music toggle, haptics toggle, accelerometer vs drag toggle.

## M6 — Store prep ❌

### M6a — Prerequisites

- [ ] **First iOS build on the MacBook**. Open `ios/Runner.xcworkspace`, resolve signing, archive. Flush out iOS-specific issues early, ahead of store submission.
- [ ] Decide on **Xcode Cloud** vs GitHub Actions macOS runner for automated iOS builds (leaning Xcode Cloud per [PLATFORM_NOTES.md](PLATFORM_NOTES.md)).

### M6b — Branding + metadata

- [x] **App icon** — generated via `flutter_launcher_icons` from `assets/images/icon-source.png` (4267×4267 RGB, beer-mug glyph on dark brown). Non-adaptive Android icon (can upgrade to adaptive foreground/background split in V2). iOS AppIcon.appiconset full set, alpha stripped for App Store. Shipped in v0.1.1.
- [ ] Splash screen.
- [ ] Privacy policy (reuse / adapt gurgles.beer one).
- [ ] Store listings: description, feature graphic, screenshots (×3 each platform minimum).

### M6c — Release

- [ ] Android: signed AAB, Play Console internal testing → closed → production.
- [ ] iOS: TestFlight build, App Store Connect listing.
- [ ] Submit to both stores.

## M7 — Leaderboard integrity ❌

Ship before the public M6 store release so the leaderboard has basic integrity from day one. Two-stage plan: start with device-bound identity (cheapest, zero UX change), then layer OS-level attestation on top once that's in place.

Current state: `POST /api/scores` on `gurgles.beer` accepts any `{name, score, platform, version}` body with no identity or rate limit. Anyone with `curl` can submit arbitrary scores, impersonate players, or spam the top-50. Confirmed during 2026-04-20 device playtests — leaderboard filled with `e`, `hdhd`, `geggd`, `tester` entries.

### M7a — Device-bound identity + server HMAC

Mobile side:
- [ ] Generate a UUID on first launch, persist in SharedPreferences under `device_id`. Regenerate if the key is cleared.
- [ ] Sign each submission payload (`{name, score, platform, version, device_id, timestamp}`) with a shared HMAC secret baked into the app binary.
- [ ] Include `device_id`, `timestamp`, `signature` in the `POST /api/scores` request body.

`gurgles.beer` backend (separate `HoldTheHooch` repo):
- [ ] Store the HMAC secret as a server env var; reject any submission with a missing or invalid signature.
- [ ] Per-`device_id` rate limit — at most 1 submission / 30 s, 20 / hour. Rate-limit rejections return `429` silently (don't leak the constraint).
- [ ] Max-plausible-score sanity check (reject scores above a threshold tuned to realistic play — tune once we know the reachable ceiling).
- [ ] **Admin endpoint** `POST /api/scores/reset` token-gated via an `ADMIN_TOKEN` env var. Closes the gap from 2026-04-20 (had to nudge the backend repo's agent to clear test entries manually).

Blocks the casual-abuse tier: curl spam, keyboard-mashing at the submit endpoint, accidental double-submissions. Does **not** stop a determined attacker with the app binary — HMAC secret can be extracted from a decompiled APK/IPA. M7b addresses that.

### M7b — OS-level attestation (after M7a is shipped)

- [ ] **iOS**: Apple App Attest. Generate attestation key on first launch, register with `gurgles.beer`, include attestation assertion in each score submission. Server validates against Apple's endpoint.
- [ ] **Android**: Play Integrity API. Client fetches integrity verdict per submission, server verifies against Google's endpoint.
- [ ] Backend: both attestation verifiers supersede the M7a HMAC check. HMAC stays as a fallback for rare devices where attestation isn't available.

Cryptographically proves each submission comes from a genuine iOS/Android device running our unmodified app binary. Significantly more work per platform than M7a but raises the abuse bar from "trivial" to "researcher-grade".

## Post-V1 ideas (not scheduled)

- Haptics on jump / spill / collect.
- Accelerometer tilt control as an alternate input.
- Background music with settings toggle.
- Daily seed / daily challenge leaderboard.
- Character skin unlocks tied to score thresholds.
- Landscape mode.
- iPad / tablet layout pass.
- Optional 2.5D / parallax-heavy visual upgrade.
- Stats/achievements ("jumped 1000 times", "collected 100 potions", etc.).
- **Game-over death-screen effect** — current game-over splash burst is subtle on-device. Consider a whole-screen flash / desaturation / slow-zoom / "YOU SPILLED IT" stinger when `balance.hasSpilled` fires, varying by end cause (obstacle hit vs spill). Would replace or augment the 30-particle splash burst added in M5a.

## Design ideas to consider (pre-ship, not committed)

### "Finite hooch" spill model (alternative to current auto-drain)

Current model: spill meter fills on tilt, **auto-drains** when level. Reaching 100% ends the run. Potion pickup gives 1s of 4× drain.

Proposed reframe: cup starts with **100 hooch**. Tilts spill hooch out (same as today). The meter does **not** auto-refill — it's a finite resource. Collectibles *replenish* hooch, because Gurgles is a brewer druid gnome literally brewing more as he runs.

- Inverts the bar semantics: "spill meter filling up" → "hooch level draining down". Run ends at 0, not 100.
- Makes collectibles dual-purpose (points AND survival resource) — raises the stakes of the jump/grab risk/reward already in the design.
- Narratively tighter: "druid brewer brewing on the run" is a fresher hook than "hooch mysteriously un-spills itself".
- Tuning implications: per-pickup hooch restore becomes a key knob (herb = small, hops = medium, potion = large?). Retire the potion spill-drain bonus since the potion's effect is now intrinsic.
- UI: swap the red fill bar for a tankard-fill visual (liquid level inside the tankard sprite), or keep the bar but flip direction + recolour.

Consider before M6 ship. Decision point: does auto-drain or finite-with-refill produce the more engaging risk/reward curve in 30–60s play sessions?
