# M5a Particles — Design Spec

> Feature: programmatic splash + sparkle particle effects for Hold the Hooch Mobile. Closes the two remaining ROADMAP M5a items: splash on spill, sparkle on collectible pickup.

**Status:** design approved 2026-04-20. Ready for implementation planning.

**Goal:** add tactile, programmatic particle feedback for the two gameplay moments that currently pass without any visual punch — the tankard spilling hooch as it tilts past threshold, and the player grabbing a collectible. Zero external assets; all effects are constructed with Flame's built-in `Particle` primitives.

**Non-goals (deferred to later M5 tasks):**
- SFX on spill or pickup — blocked on audio delivery per [AUDIO-GUIDE.md](../../AUDIO-GUIDE.md).
- Run-cycle sprite swap and hurt pose — art-dependent per [ART-GUIDE.md](../../ART-GUIDE.md).
- Trail effects behind Gurgles, ambient forest particles, or other non-checklist polish.

---

## Feature 1 — Splash on spill (hybrid reactive + dramatic game-over burst)

### Behaviour

Three distinct emission modes composed into one system:

1. **Burst on threshold crossing.** The instant `balance.tilt.abs()` crosses from `≤ GameConfig.spillThreshold` (0.7) to `> 0.7`, emit a single 6-particle burst from the tankard rim on the tilt side. Edge-triggered — does not re-fire while tilt stays over-threshold.
2. **Reactive continuous trickle.** While `balance.tilt.abs() > 0.7`, emit particles at a rate that scales linearly with how far over threshold the tilt sits: `rate = 5 + 10 * ((|tilt| - 0.7) / (1.0 - 0.7))`, giving 5/sec at exactly 0.7 tilt and 15/sec at 1.0 tilt.
3. **Dramatic game-over burst.** When `balance.hasSpilled` (spill reaches 1.0), emit a one-shot 30-particle burst with wider angular spread and larger per-particle radii. This is the death visual; the game-over overlay is delayed by 600 ms so the burst has time to animate before being covered.

### Particle visuals

Each splash particle is an `AcceleratedParticle` wrapping a `CircleParticle`:

- Colour: amber `#D4A017` (matches the hooch SVG palette and the art-guide spec for `hooch-splash.svg`).
- Radius: random 3–5 px.
- Lifespan: random 0.6–0.9 s.
- Initial velocity: direction is `Vector2(sign(tilt), -0.6)` rotated by a small random jitter (±15°), magnitude 60–120 px/s. The negative y component gives the particle a small upward pop before gravity kicks in.
- Acceleration: `Vector2(0, 800)` px/s² — the particles fall as if under real gravity.
- Fade: the particle's paint alpha ramps linearly from 255 at birth to 0 at death.

Every third particle additionally renders a smaller cream-highlight circle (`#FFF9C4`, radius 2 px) immediately behind the main droplet for the "foam on amber" reading the art guide describes. Implementation: for every third emitted particle, wrap it in a `ComposedParticle([creamCircle, amberCircle])` with the cream circle at a small offset (±2 px random). The remaining particles emit as a plain single-layer `CircleParticle`.

### Game-over burst specifics

- Count: 30 particles.
- Angular spread: ±60° around the tilt-side rim normal (vs ±15° for the trickle).
- Radii: 4–7 px (larger than trickle).
- Lifespan: 0.9–1.2 s (longer tail).
- Speed: 80–160 px/s.
- Emitted once; no repeat. The burst is fire-and-forget; the `ParticleSystemComponent` self-removes after its particles expire.

### Emission position

Computed per emission as:

```
tankardRimWorld = gurgles.position
                + tankardCenterOffset
                + Vector2(0, -tankardRadius).rotated(balance.tilt * tankardMaxLeanRadians)
```

Where:
- `gurgles.position` is the feet-anchor in world coordinates.
- `tankardCenterOffset` is the current offset of `_tankard` inside Gurgles (roughly `Vector2(size.x / 2, -size.y + 2)` — above the raised hands).
- `tankardRadius` is `_tankard.size.x / 2`.

The rotation of `Vector2(0, -tankardRadius)` by `balance.tilt * tankardMaxLeanRadians` gives the rim point on the tilt side. This requires exposing at minimum `gurgles.tankardRimWorldPosition` as a `@visibleForTesting`-or-public getter on `Gurgles` — see "Production code seams" below.

---

## Feature 2 — Sparkle on pickup (tinted + size-scaled per kind)

### Behaviour

One burst per pickup, emitted from the collectible's world position at the instant `Collectible.onCollisionStart` fires and calls `onPickup`. `GameScene.onPickup` already receives the world position — sparkle emission hooks into this existing callback alongside the existing `ScorePopup` add.

### Per-kind configuration table

| Kind    | Particle count | Radius (px) | Colour              | Lifespan (s) | Notes                              |
|---------|----------------|-------------|---------------------|--------------|------------------------------------|
| herb    | 6              | 2           | green `#4CAF50`     | 0.5          | low-reward feel                    |
| hops    | 10             | 3           | gold `#FFD700`      | 0.7          | medium                             |
| potion  | 16             | 4           | blue `#00BFFF`      | 1.0          | plus expanding-ring halo overlay   |

### Motion

Each sparkle particle is a `ComputedParticle`:
- Initial position: the pickup world position.
- Initial velocity: random angle 0..2π, random speed 30–80 px/s.
- Per-frame update: position advances by `velocity * dt`; velocity decays as `velocity *= (1 - GameConfig.sparkleDecelerationRate * dt)` so the feel is dt-stable across framerates (a rate of ~4.8 per second gives the familiar `0.92`-per-frame feel at 60 fps); paint alpha ramps from 255 at birth to 0 at death; no gravity.
- Radius stays constant over the lifespan.

### Potion halo overlay

For potion only, append a single additional `ComputedParticle` that renders a ring (stroke, not fill) whose radius grows from 0 to 40 px over a 0.4 s lifespan and whose alpha fades from 180 to 0 over the same window. Stroke colour: blue `#00BFFF`, stroke width 2 px. Sits behind the 16 sparkles. Gives the potion grab a "magic moment" feel distinct from the quantitative 200-point boost.

---

## Architecture

### File layout

```
lib/components/
  splash_emitter.dart    # new — long-lived stateful emitter
  sparkle_burst.dart     # new — static factory + per-kind config
lib/scenes/
  game_scene.dart        # modify — wire up emitter; branch game-over
lib/components/
  gurgles.dart           # modify — expose tankardRimWorldPosition getter
test/
  splash_emitter_test.dart    # new
  sparkle_burst_test.dart     # new
  game_scene_restart_test.dart  # modify — add ParticleSystemComponent cleanup assertion
```

No `lib/systems/` addition — `SplashEmitter` is a `Component`, not a spawner in the style of `ObstacleManager` / `CollectibleManager`. It has no children to schedule; it fires one-shot `ParticleSystemComponent`s up into the scene tree.

### `SplashEmitter` component

```dart
class SplashEmitter extends Component {
  final Gurgles gurgles;
  final HoochBalance balance;

  bool _wasOverThreshold = false;
  double _continuousAccum = 0;

  SplashEmitter({required this.gurgles, required this.balance});

  @override
  void update(double dt) { /* edge detection + reactive trickle per spec */ }

  void emitGameOverBurst() { /* 30-particle dramatic burst */ }

  void reset() {
    _wasOverThreshold = false;
    _continuousAccum = 0;
  }
}
```

`reset()` is called by `GameScene.restart()` so the emitter starts each run with a clean state machine.

### `SparkleBurst` helper

```dart
class SparkleBurst {
  static ParticleSystemComponent emit(CollectibleKind kind, Vector2 at) {
    final cfg = _configFor(kind);
    // build the particle tree and return ParticleSystemComponent
  }

  @visibleForTesting
  static ({int count, double radius, Color colour, double lifespan}) configFor(
    CollectibleKind kind,
  ) => _configFor(kind);
}
```

The test surface is the pure config-lookup function. The actual particle construction is exercised by device playtest; a mount-without-throw smoke test (see testing section) guards the plumbing.

### Production code seams (all `@visibleForTesting`-annotated)

1. **`Gurgles.tankardRimWorldPosition` getter.** Returns the world position of the rim point on the tilt side. Used by `SplashEmitter.update` to compute emission origin. Public (no underscore) because it's read by another production component, not just tests.

2. **`Gurgles.tankardRadius` getter.** Returns `_tankard.size.x / 2`. Needed by `SplashEmitter` for scaled emission offsets at non-default sizeScales. Public.

3. **`SparkleBurst.configFor`.** Pure lookup — pass a kind, get `(count, radius, colour, lifespan)`. `@visibleForTesting` because test is the only non-internal consumer.

4. **`GameScene._end(String reason, {bool fromSpill = false})`.** Existing method gains an optional flag. Internal — not test-facing.

### Game-over hook

In `GameScene._end`:

```dart
void _end(String reason, {bool fromSpill = false}) {
  if (_gameOver) return;
  _gameOver = true;
  endReason = reason;

  if (fromSpill) {
    splashEmitter.emitGameOverBurst();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!isMounted) return;
      pauseEngine();
      overlays.add(gameOverOverlayId);
    });
    return;
  }

  pauseEngine();
  overlays.add(gameOverOverlayId);
}
```

Call-site changes:
- `if (balance.hasSpilled) _end('You spilled the hooch!', fromSpill: true);`
- Obstacle-hit path stays on the default `_end('Hit an obstacle!')`.

The `_gameOver = true` flag set at the top of `_end` already prevents duplicate death handling inside the 600 ms delay window; the `update()` guard `if (_gameOver) return` suppresses any further balance / score logic.

### Restart cleanup

`GameScene.restart()` grows three lines:

```dart
for (final p in children.whereType<ParticleSystemComponent>().toList()) {
  p.removeFromParent();
}
splashEmitter.reset();
```

`ParticleSystemComponent`s from both splash and sparkle paths live as direct children of `GameScene`, so `whereType` picks them all up.

### Construction & wiring in `GameScene.onLoad`

After `balance` is constructed and added, and after `gurgles` is constructed and added:

```dart
splashEmitter = SplashEmitter(gurgles: gurgles, balance: balance);
add(splashEmitter);
```

In the existing `onPickup` callback passed to `CollectibleManager`, alongside the existing `ScorePopup` add:

```dart
onPickup: (points, at) {
  _collectiblePoints += points;
  add(ScorePopup(points: points, position: at.clone()));
  add(SparkleBurst.emit(kind, at.clone()));    // new
},
```

Note: `CollectibleManager.onPickup` does not currently pass the `CollectibleKind` to the callback. The callback signature needs widening to `(int points, Vector2 at, CollectibleKind kind)`, or `CollectibleManager` needs to be updated to thread `kind` through. Pick the minimal change — widen the callback signature in `CollectibleManager` and the scene lambda together.

---

## Testing

### Pure-unit tests

**`splash_emitter_test.dart`:**
- No emission at `|tilt| < 0.7` (run the emitter for 1 second with `balance.tilt = 0.5`; assert zero `ParticleSystemComponent` children were added to the parent).
- Exactly one burst fires on threshold entry (start at `tilt = 0`, step to `tilt = 0.8`, run one update; assert one emission; run more updates at `tilt = 0.8`; assert at most the trickle rate's worth of additional emissions).
- No duplicate burst while steady-state over (hold `tilt = 0.8` for 1s; assert total emissions ≤ 1 burst + ~5 trickle = ~6, not ~12).
- Continuous rate at `tilt = 0.7 + epsilon` ≈ 5/sec (measure emission count over 1 second with tiny over-threshold).
- Continuous rate at `tilt = 1.0` ≈ 15/sec (measure emission count over 1 second at max tilt).
- `reset()` clears `_wasOverThreshold` so a post-reset threshold crossing re-fires the burst.

Use a minimal fake: `SplashEmitter` is constructed with a stub `_MockGurgles` (just returns a fixed `tankardRimWorldPosition`) and a plain `HoochBalance` whose `tilt` the test writes directly. Mount the emitter under a bare `FlameGame` and step `game.update(dt)`.

**`sparkle_burst_test.dart`:**
- `configFor(herb).count == 6`, `configFor(hops).count == 10`, `configFor(potion).count == 16`.
- Radii strictly ordered: `herb.radius < hops.radius < potion.radius`.
- Lifespans strictly ordered: `herb.lifespan < hops.lifespan < potion.lifespan`.
- Colours non-equal across kinds (sanity — prevents accidental dup).
- Smoke test: `SparkleBurst.emit(kind, Vector2(100, 100))` returns a non-null `ParticleSystemComponent` for each kind and mounts without throwing under a bare `FlameGame`.

### Integration test update

**`game_scene_restart_test.dart`** grows one assertion and one seeding step:

Before `restart()`:
```dart
game.add(SparkleBurst.emit(CollectibleKind.herb, Vector2(50, 50)));
await game.ready();
expect(game.children.whereType<ParticleSystemComponent>(), isNotEmpty);
```

After `restart()`:
```dart
expect(game.children.whereType<ParticleSystemComponent>(), isEmpty);
```

Also verify the new `SplashEmitter` state resets: after forcing `balance.tilt` over threshold pre-restart to flip `_wasOverThreshold`, post-restart assert that a fresh over-threshold transition re-fires a burst (this is essentially the `reset()` behavior, worth one line).

### Device playtest (what unit tests can't verify)

- Does the game-over splash land **before** the overlay covers it? If it feels clipped, bump the 600 ms delay; if it feels sluggish, trim it.
- Is 15 particles/sec at max tilt distractingly busy or appropriately tense? Tune rate constants in `GameConfig`.
- Does the potion sparkle + halo read as meaningfully special vs hops vs herb, or does it blur together? If indistinct, bump the potion count or halo brightness.
- Do the splash emission positions track the rim correctly as Gurgles jumps (tankard moves through an arc)? Watch for particles spawning inside Gurgles' hitbox or off to one side.

---

## Tuning constants (candidates for `GameConfig`)

To keep magic numbers out of the new components, introduce:

```dart
// Splash
static const int splashBurstCount = 6;
static const int splashGameOverBurstCount = 30;
static const double splashTrickleRateBase = 5.0;      // per second at threshold
static const double splashTrickleRateMax = 15.0;      // per second at tilt=1.0
static const int splashGameOverDelayMs = 600;
static const double splashGravity = 800.0;
static const double splashSpeedMin = 60.0;
static const double splashSpeedMax = 120.0;

// Sparkle deceleration, shared across kinds. dt-based rather than
// per-frame so feel is stable at any framerate. 4.8/s gives the
// familiar 0.92-per-frame decay at 60fps.
static const double sparkleDecelerationRate = 4.8;
```

Per-kind sparkle config stays inside `sparkle_burst.dart`'s switch (it's table-shaped, not a tunable).

---

## Risks & mitigations

- **Risk:** `ParticleSystemComponent` doesn't self-remove as expected and cleanup logic leaves orphans across restarts.
  **Mitigation:** the restart loop explicitly removes all `ParticleSystemComponent` children; the integration test asserts emptiness post-restart. If the baseline self-removal turns out to be reliable, the cleanup loop is cheap insurance; if it's unreliable, we've already compensated.

- **Risk:** 15 particles/sec + other overlays tank framerate on low-end Android.
  **Mitigation:** device playtest on the current test device (Samsung S26 Ultra) is in the flow; if frame drops appear, reduce `splashTrickleRateMax` or trim lifespans. Particle pooling is available in Flame but adds complexity — defer until measured as needed.

- **Risk:** the 600 ms game-over delay interacts badly with the existing `overlays.add(gameOverOverlayId)` lifecycle if the player somehow triggers another state change in that window.
  **Mitigation:** the `_gameOver = true` flag at the top of `_end` blocks re-entry; the `update()` guard already returns early on `_gameOver`. The 600 ms window is too short for the player to physically interact with the still-running game, and the overlay is not yet present so no overlay-level interactions exist.

- **Risk:** exposing `tankardRimWorldPosition` as a public getter bloats `Gurgles`' API surface.
  **Mitigation:** the getter is a pure read on already-mutable component state; it adds no new mutable surface and the dependency shape (particle emitter reads tankard pose) is fundamentally a cross-component concern. Consistent with the existing `tankardAngleForTilt` static already on `Gurgles`.

---

## Effort estimate

Approximately 300 lines across 2 new files and 3 modified files, plus ~140 lines of new tests. Aligns with the existing task cadence (M4c averaged ~50–80 lines per task commit).

Suggested task breakdown at plan time:
1. `SparkleBurst` helper + tests (simplest — pure data + smoke test).
2. `Gurgles.tankardRimWorldPosition` + `tankardRadius` getters + tests.
3. `SplashEmitter` component + unit tests.
4. GameScene wiring (emitter construction, pickup hook, restart cleanup).
5. Game-over `fromSpill` branch + delayed overlay.
6. Integration test update (`game_scene_restart_test.dart`).
7. Device playtest + tune constants.
8. ROADMAP / STATUS sync (close the two M5a checklist items).
