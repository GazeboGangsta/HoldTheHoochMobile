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
- [x] Parallax background (mountains + trees).
- [x] Spill meter bar.
- [x] Dark-navy backdrop matched to mountains gradient (seamless sky).
- [x] Score popup on collectible pickup (⚠️ crashes — fix in M4a).
- [x] **Tankard rotation** tied to `balance.tilt` — visual feedback of how close to spilling. Rotate `_tankard` in `Gurgles.update`: `_tankard.angle = balance.tilt * 0.6` (~35° max lean).
- [x] **Splash particles** on spill — programmatic emission via `SplashEmitter` (hybrid burst + reactive trickle + dramatic game-over flourish, all from the tankard rim).
- [x] **Sparkle particles** on collectible pickup — programmatic, tinted + size-scaled per `CollectibleKind` via `SparkleBurst` (herb green / hops gold / potion blue + expanding halo).
- [ ] **6-frame run cycle** sprite swap. Requires art delivery ([ART-GUIDE.md](ART-GUIDE.md)).
- [ ] **Hurt pose** on game-over (gurgles-hurt.svg — needs art).

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
- [ ] **Tutorial overlay** — first 1–2 seconds of first run only. `tap-hint.svg` on right, `drag-hint.svg` on left. Dismiss on first input.
- [ ] **Settings** (lightweight) — music toggle, haptics toggle, accelerometer vs drag toggle.

## M6 — Store prep ❌

### M6a — Prerequisites

- [ ] **First iOS build on the MacBook**. Open `ios/Runner.xcworkspace`, resolve signing, archive. Flush out iOS-specific issues early, ahead of store submission.
- [ ] Decide on **Xcode Cloud** vs GitHub Actions macOS runner for automated iOS builds (leaning Xcode Cloud per [PLATFORM_NOTES.md](PLATFORM_NOTES.md)).

### M6b — Branding + metadata

- [ ] App icon (Android adaptive + iOS flat). Master SVG per [ART-GUIDE.md](ART-GUIDE.md).
- [ ] Splash screen.
- [ ] Privacy policy (reuse / adapt gurgles.beer one).
- [ ] Store listings: description, feature graphic, screenshots (×3 each platform minimum).

### M6c — Release

- [ ] Android: signed AAB, Play Console internal testing → closed → production.
- [ ] iOS: TestFlight build, App Store Connect listing.
- [ ] Submit to both stores.

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
