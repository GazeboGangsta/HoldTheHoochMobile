# M5a Particles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add programmatic splash-on-spill and sparkle-on-pickup particle effects per [docs/superpowers/specs/2026-04-20-m5a-particles-design.md](../specs/2026-04-20-m5a-particles-design.md), closing the two remaining ROADMAP M5a visual checkboxes.

**Architecture:** Two components composed via Flame's built-in `Particle` primitives. `SplashEmitter` (long-lived, on GameScene) edge-detects tilt threshold crossings and emits hybrid burst+trickle particles from the tankard rim. `SparkleBurst` (static factory) returns fire-and-forget `ParticleSystemComponent`s tinted and sized per `CollectibleKind`. A small `fromSpill` branch in `GameScene._end` plays a dramatic game-over burst before the overlay covers the scene.

**Tech Stack:** Flutter 3.41.4, Dart 3.11.1, Flame 1.37 particle system (`ComputedParticle`, `ComposedParticle`, `ParticleSystemComponent`). No new dependencies.

---

## Context — read before starting

Load-bearing files you should open once before diving in:

- [docs/superpowers/specs/2026-04-20-m5a-particles-design.md](../specs/2026-04-20-m5a-particles-design.md) — the approved design. Every design-feel choice is pinned here.
- [lib/scenes/game_scene.dart](../../../lib/scenes/game_scene.dart) — the scene we're modifying. `_end`, `restart`, `onPickup` wiring all live here.
- [lib/components/gurgles.dart](../../../lib/components/gurgles.dart) — we add two methods (`tankardRimWorldPosition`, static `rimOffsetFromTankardCenter`). `_tankard` is already nullable.
- [lib/components/hooch_balance.dart](../../../lib/components/hooch_balance.dart) — read-only dependency; we reference `balance.tilt` + `balance.hasSpilled`.
- [lib/systems/collectible_manager.dart](../../../lib/systems/collectible_manager.dart) — we widen the `onPickup` callback signature to carry `CollectibleKind`.
- [test/game_scene_restart_test.dart](../../../test/game_scene_restart_test.dart) — the stub pattern established in M4c. Reuse this shape.

### Flame particle primitives quick reference

- `ComputedParticle(lifespan, renderer)` — custom per-frame render callback `(Canvas canvas, Particle particle)`. `particle.progress` is `0..1` over lifespan. **We use this for everything** — it integrates fade + motion into one render pass, avoids the fact that `CircleParticle` has no built-in alpha fade.
- `ComposedParticle(children)` — overlays multiple particles. Only used if we split into sub-particles; the spec mentions it but `ComputedParticle` with two `canvas.drawCircle` calls in one renderer is cleaner and is what the impl below uses.
- `ParticleSystemComponent(particle:)` — the actual scene-tree component that wraps a `Particle` and self-removes when the particle expires. We `.add()` instances directly to `GameScene`.

### Design-to-impl deviations from the spec

The spec suggests `ComposedParticle([creamCircle, amberCircle])` for the cream-highlighted splash droplets. **This plan uses a single `ComputedParticle` with two `canvas.drawCircle` calls** because `CircleParticle` lacks built-in alpha fade, so we'd have to reimplement fading anyway. Visual outcome is identical — amber droplet with a cream highlight, both fading together. Net code is shorter than the spec's suggestion.

---

## Task 1: GameConfig constants + invariant tests

Add the M5a tuning constants listed in the spec's "Tuning constants" section, with a test guarding each class of invariant (positivity, ordering). Keeps magic numbers out of downstream components.

**Files:**
- Modify: [lib/config/game_config.dart](../../../lib/config/game_config.dart) — append new constants at end of class
- Modify: [test/game_config_test.dart](../../../test/game_config_test.dart) — append tests to existing `GameConfig invariants` group

- [ ] **Step 1: Append constants to `GameConfig`**

Open `lib/config/game_config.dart`. At the end of the class body (after `tiltButtonTorqueRate`, before the closing `}`), append:

```dart

  // M5a — splash emitter tuning (see docs/superpowers/specs/2026-04-20-m5a-particles-design.md).
  static const int splashBurstCount = 6;
  static const int splashGameOverBurstCount = 30;
  static const double splashTrickleRateBase = 5.0;   // particles/sec at tilt == spillThreshold
  static const double splashTrickleRateMax = 15.0;   // particles/sec at tilt == 1.0
  static const int splashGameOverDelayMs = 600;      // hold the overlay this long so the burst animates
  static const double splashGravity = 800.0;         // px/s² pulling splash droplets down
  static const double splashSpeedMin = 60.0;         // px/s min initial droplet speed
  static const double splashSpeedMax = 120.0;        // px/s max initial droplet speed

  // M5a — sparkle burst tuning. Deceleration is dt-based so feel is stable across
  // framerates. 4.8/s gives the familiar 0.92-per-frame decay at 60fps.
  static const double sparkleDecelerationRate = 4.8;
```

- [ ] **Step 2: Append invariant tests**

Open `test/game_config_test.dart`. Find the final `test(...)` inside `group('GameConfig invariants', ...)`. Append before the group's closing `});`:

```dart
    test('M5a splash constants are positive and correctly ordered', () {
      expect(GameConfig.splashBurstCount, greaterThan(0));
      expect(GameConfig.splashGameOverBurstCount, greaterThan(GameConfig.splashBurstCount));
      expect(GameConfig.splashTrickleRateBase, greaterThan(0));
      expect(GameConfig.splashTrickleRateMax, greaterThan(GameConfig.splashTrickleRateBase));
      expect(GameConfig.splashGameOverDelayMs, greaterThan(0));
      expect(GameConfig.splashGravity, greaterThan(0));
      expect(GameConfig.splashSpeedMin, greaterThan(0));
      expect(GameConfig.splashSpeedMax, greaterThan(GameConfig.splashSpeedMin));
    });

    test('sparkleDecelerationRate is positive', () {
      expect(GameConfig.sparkleDecelerationRate, greaterThan(0));
    });
```

- [ ] **Step 3: Run tests**

```
flutter test test/game_config_test.dart
```

Expected: all tests pass (prior 12 + 2 new = 14 green).

- [ ] **Step 4: Run full suite + analyze**

```
flutter analyze && flutter test
```

Expected: analyze clean; total test count is `60` (prior 58 + 2 new).

- [ ] **Step 5: Commit**

```bash
git add lib/config/game_config.dart test/game_config_test.dart
git commit -m "M5a: add splash + sparkle tuning constants to GameConfig"
```

---

## Task 2: `SparkleBurst` helper + tests

A static factory that returns a `ParticleSystemComponent` for a given collectible kind at a given world position. Per-kind config is a pure lookup (table-shaped, non-tunable). Smoke-tested for mount-without-throw.

**Files:**
- Create: `lib/components/sparkle_burst.dart`
- Create: `test/sparkle_burst_test.dart`

- [ ] **Step 1: Write the failing tests first**

Create `test/sparkle_burst_test.dart`:

```dart
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/collectible.dart';
import 'package:hold_the_hooch/components/sparkle_burst.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SparkleBurst.configFor', () {
    test('particle counts strictly ordered herb < hops < potion', () {
      expect(SparkleBurst.configFor(CollectibleKind.herb).count,
          lessThan(SparkleBurst.configFor(CollectibleKind.hops).count));
      expect(SparkleBurst.configFor(CollectibleKind.hops).count,
          lessThan(SparkleBurst.configFor(CollectibleKind.potion).count));
    });

    test('radii strictly ordered herb < hops < potion', () {
      expect(SparkleBurst.configFor(CollectibleKind.herb).radius,
          lessThan(SparkleBurst.configFor(CollectibleKind.hops).radius));
      expect(SparkleBurst.configFor(CollectibleKind.hops).radius,
          lessThan(SparkleBurst.configFor(CollectibleKind.potion).radius));
    });

    test('lifespans strictly ordered herb < hops < potion', () {
      expect(SparkleBurst.configFor(CollectibleKind.herb).lifespan,
          lessThan(SparkleBurst.configFor(CollectibleKind.hops).lifespan));
      expect(SparkleBurst.configFor(CollectibleKind.hops).lifespan,
          lessThan(SparkleBurst.configFor(CollectibleKind.potion).lifespan));
    });

    test('colours are distinct across kinds', () {
      final h = SparkleBurst.configFor(CollectibleKind.herb).colour;
      final o = SparkleBurst.configFor(CollectibleKind.hops).colour;
      final p = SparkleBurst.configFor(CollectibleKind.potion).colour;
      expect(h, isNot(equals(o)));
      expect(o, isNot(equals(p)));
      expect(h, isNot(equals(p)));
    });
  });

  group('SparkleBurst.emit', () {
    test('mounts a ParticleSystemComponent for every kind without throwing', () async {
      final game = FlameGame();
      game.onGameResize(Vector2(400, 800));
      await game.onLoad();
      await game.ready();

      for (final kind in CollectibleKind.values) {
        final comp = SparkleBurst.emit(kind, Vector2(100, 100));
        await game.add(comp);
        await game.ready();
        expect(comp.isMounted, isTrue, reason: '$kind failed to mount');
      }
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/sparkle_burst_test.dart
```

Expected: FAIL — compile error "The method 'SparkleBurst' isn't defined" (import target missing).

- [ ] **Step 3: Create the implementation**

Create `lib/components/sparkle_burst.dart`:

```dart
import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import '../config/game_config.dart';
import 'collectible.dart';

/// Fire-and-forget sparkle burst played on collectible pickup. Tinted and
/// sized per [CollectibleKind]: herb = small green, hops = medium gold,
/// potion = large blue plus an expanding halo ring.
class SparkleBurst {
  static final Random _rng = Random();

  /// Build a self-removing ParticleSystemComponent positioned at [at].
  /// Add the returned component to the scene to play the burst.
  static ParticleSystemComponent emit(CollectibleKind kind, Vector2 at) {
    final cfg = configFor(kind);
    final particles = <Particle>[
      for (var i = 0; i < cfg.count; i++) _sparkle(cfg, at),
    ];
    if (kind == CollectibleKind.potion) {
      particles.add(_potionHalo(at));
    }
    return ParticleSystemComponent(
      particle: ComposedParticle(children: particles),
    );
  }

  @visibleForTesting
  static ({int count, double radius, Color colour, double lifespan}) configFor(
    CollectibleKind kind,
  ) =>
      switch (kind) {
        CollectibleKind.herb => (
            count: 6,
            radius: 2.0,
            colour: const Color(0xFF4CAF50),
            lifespan: 0.5,
          ),
        CollectibleKind.hops => (
            count: 10,
            radius: 3.0,
            colour: const Color(0xFFFFD700),
            lifespan: 0.7,
          ),
        CollectibleKind.potion => (
            count: 16,
            radius: 4.0,
            colour: const Color(0xFF00BFFF),
            lifespan: 1.0,
          ),
      };

  /// Single sparkle with closed-form exponential-decay outward motion.
  /// Position at time t is `at + v0 * (1 - e^(-kt)) / k` where k is the
  /// deceleration rate. Alpha ramps linearly 255 → 0 across the lifespan.
  static Particle _sparkle(
    ({int count, double radius, Color colour, double lifespan}) cfg,
    Vector2 at,
  ) {
    final angle = _rng.nextDouble() * 2 * pi;
    final speed = 30 + _rng.nextDouble() * 50; // 30..80 px/s
    final v0 = Vector2(cos(angle), sin(angle)) * speed;
    final k = GameConfig.sparkleDecelerationRate;
    return ComputedParticle(
      lifespan: cfg.lifespan,
      renderer: (canvas, particle) {
        final t = particle.progress * cfg.lifespan;
        final disp = v0 * ((1 - exp(-k * t)) / k);
        final cx = at.x + disp.x;
        final cy = at.y + disp.y;
        final alpha = (255 * (1 - particle.progress)).round().clamp(0, 255);
        final paint = Paint()..color = cfg.colour.withAlpha(alpha);
        canvas.drawCircle(Offset(cx, cy), cfg.radius, paint);
      },
    );
  }

  /// Potion-only expanding ring halo: radius 0 → 40 px over 0.4s,
  /// stroke alpha 180 → 0. Sits behind the sparkles.
  static Particle _potionHalo(Vector2 at) {
    const haloLifespan = 0.4;
    const haloMaxRadius = 40.0;
    const haloMaxAlpha = 180;
    const haloColour = Color(0xFF00BFFF);
    return ComputedParticle(
      lifespan: haloLifespan,
      renderer: (canvas, particle) {
        final r = particle.progress * haloMaxRadius;
        final alpha = (haloMaxAlpha * (1 - particle.progress)).round().clamp(0, 255);
        final paint = Paint()
          ..color = haloColour.withAlpha(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(Offset(at.x, at.y), r, paint);
      },
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```
flutter test test/sparkle_burst_test.dart
```

Expected: all 5 tests pass.

- [ ] **Step 5: Run full suite + analyze**

```
flutter analyze && flutter test
```

Expected: analyze clean; total 65 tests green (60 + 5 new).

- [ ] **Step 6: Commit**

```bash
git add lib/components/sparkle_burst.dart test/sparkle_burst_test.dart
git commit -m "M5a: SparkleBurst factory + per-kind config tests"
```

---

## Task 3: Gurgles tankard-rim getters + tests

Expose two pieces of geometry that `SplashEmitter` (next task) needs: the world-space position of the tankard rim on the tilt side, and — factored out for testability — the rim-offset pure function.

**Files:**
- Modify: [lib/components/gurgles.dart](../../../lib/components/gurgles.dart)
- Modify: [test/tankard_rotation_test.dart](../../../test/tankard_rotation_test.dart) (same domain as existing `tankardAngleForTilt` tests)

- [ ] **Step 1: Write the failing tests first**

Open `test/tankard_rotation_test.dart`. Append new groups at the end of `void main()`, before the final closing `}`:

```dart

  group('Gurgles.rimOffsetFromTankardCenter', () {
    test('at tilt=0, rim offset is straight up (y negative, x zero)', () {
      final offset = Gurgles.rimOffsetFromTankardCenter(0, 10);
      expect(offset.x, closeTo(0, 1e-9));
      expect(offset.y, closeTo(-10, 1e-9));
    });

    test('at positive tilt, rim offset rotates toward +x', () {
      final offset = Gurgles.rimOffsetFromTankardCenter(1.0, 10);
      expect(offset.x, greaterThan(0), reason: 'positive tilt → rim shifts right');
      expect(offset.y, lessThan(0), reason: 'rim stays above center');
    });

    test('at negative tilt, rim offset rotates toward -x', () {
      final offset = Gurgles.rimOffsetFromTankardCenter(-1.0, 10);
      expect(offset.x, lessThan(0));
      expect(offset.y, lessThan(0));
    });

    test('magnitude equals tankardRadius regardless of tilt', () {
      for (final tilt in [-1.0, -0.5, 0.0, 0.5, 1.0]) {
        final offset = Gurgles.rimOffsetFromTankardCenter(tilt, 10);
        expect(offset.length, closeTo(10, 1e-9), reason: 'tilt=$tilt');
      }
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/tankard_rotation_test.dart
```

Expected: FAIL — "The method 'rimOffsetFromTankardCenter' isn't defined for 'Gurgles'."

- [ ] **Step 3: Add the getters**

Open `lib/components/gurgles.dart`. Two additions:

First, after the existing `static double tankardAngleForTilt(double tilt)` method (around line 95), add a new static pure function:

```dart

  /// Pure function: offset from tankard center to the point on the rim
  /// pointing in the tilt direction. When [tilt] is 0, that's straight up
  /// at `(0, -tankardRadius)`; the vector rotates by
  /// `tilt * GameConfig.tankardMaxLeanRadians` so the emission point
  /// tracks the lean. Tested in test/tankard_rotation_test.dart.
  @visibleForTesting
  static Vector2 rimOffsetFromTankardCenter(double tilt, double tankardRadius) =>
      Vector2(0, -tankardRadius)..rotate(tilt * GameConfig.tankardMaxLeanRadians);
```

Second, after the existing `setTankardAngle(double angle)` method, add:

```dart

  /// World-space position of the tankard rim on the tilt side.
  /// Used by [SplashEmitter] to spawn droplets where the hooch would
  /// physically spill out. Returns Gurgles' own position if the tankard
  /// hasn't loaded yet (pre-onLoad), matching the existing null-safe
  /// pattern for _tankard.
  Vector2 tankardRimWorldPosition(double tilt) {
    final t = _tankard;
    if (t == null) return position.clone();
    final tankardRadius = t.size.x / 2;
    final tankardCenterLocal = Vector2(size.x / 2, -2 - t.size.y / 2);
    return position + tankardCenterLocal + rimOffsetFromTankardCenter(tilt, tankardRadius);
  }
```

Make sure `Vector2` is already imported via `package:flame/components.dart` (it is).

- [ ] **Step 4: Run the new tests**

```
flutter test test/tankard_rotation_test.dart
```

Expected: all pre-existing tankard-rotation tests still pass, plus the 4 new `rimOffsetFromTankardCenter` tests.

- [ ] **Step 5: Run full suite + analyze**

```
flutter analyze && flutter test
```

Expected: analyze clean; 69 tests green (65 + 4 new).

- [ ] **Step 6: Commit**

```bash
git add lib/components/gurgles.dart test/tankard_rotation_test.dart
git commit -m "M5a: expose tankardRimWorldPosition + rimOffsetFromTankardCenter on Gurgles"
```

---

## Task 4: `SplashEmitter` component + unit tests

The stateful hybrid emitter: edge-detects threshold crossings for the one-shot burst, accumulates the reactive trickle at a rate that scales with `|tilt|`, exposes `emitGameOverBurst()` for the dramatic death flourish, and `reset()` for restart integration. Tests use the stub pattern established in M4c.

**Files:**
- Create: `lib/components/splash_emitter.dart`
- Create: `test/splash_emitter_test.dart`

- [ ] **Step 1: Write the failing tests first**

Create `test/splash_emitter_test.dart`:

```dart
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/gurgles.dart';
import 'package:hold_the_hooch/components/hooch_balance.dart';
import 'package:hold_the_hooch/components/splash_emitter.dart';
import 'package:hold_the_hooch/config/game_config.dart';

/// Gurgles stub that skips SVG loading and returns a fixed world rim position,
/// so the emitter can be unit-tested without the asset bundle.
class _StubGurgles extends Gurgles {
  _StubGurgles()
      : super(
          position: Vector2(200, 600),
          groundY: 600,
          size: Vector2(80, 144),
        );

  @override
  Future<void> onLoad() async {}

  @override
  Vector2 tankardRimWorldPosition(double tilt) => Vector2(200, 500);
}

int _emissions(FlameGame game) =>
    game.children.whereType<ParticleSystemComponent>().length;

Future<({FlameGame game, SplashEmitter emitter, HoochBalance balance})> _setup() async {
  final game = FlameGame();
  game.onGameResize(Vector2(400, 800));
  await game.onLoad();
  await game.ready();
  final balance = HoochBalance();
  final emitter = SplashEmitter(gurgles: _StubGurgles(), balance: balance);
  await game.add(emitter);
  await game.ready();
  return (game: game, emitter: emitter, balance: balance);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('no emission while tilt stays below spillThreshold', () async {
    final s = await _setup();
    s.balance.tilt = 0.5;
    for (var i = 0; i < 60; i++) {
      s.game.update(1 / 60);
    }
    expect(_emissions(s.game), 0);
  });

  test('exactly one burst fires on threshold crossing', () async {
    final s = await _setup();
    s.balance.tilt = 0.5;
    s.game.update(1 / 60);
    final before = _emissions(s.game);

    s.balance.tilt = 0.8;
    s.game.update(1 / 60);
    // One burst is one ParticleSystemComponent carrying splashBurstCount droplets.
    expect(_emissions(s.game) - before, 1);
  });

  test('no re-burst while tilt stays over threshold', () async {
    final s = await _setup();
    s.balance.tilt = 0.8;
    s.game.update(1 / 60);  // entry burst
    final afterBurst = _emissions(s.game);

    // Five more frames at 0.8 tilt. Trickle rate at tilt=0.8 ≈
    //   5 + 10 * (0.8-0.7)/(1-0.7) = 8.33 particles/sec.
    // Over 5 frames (~0.083s) that's ~0.7 particles expected — so
    // total additional emissions should be 0 or 1, NEVER another burst.
    for (var i = 0; i < 5; i++) {
      s.game.update(1 / 60);
    }
    expect(_emissions(s.game) - afterBurst, lessThanOrEqualTo(1));
  });

  test('continuous rate at tilt=threshold+epsilon ≈ 5 per second', () async {
    final s = await _setup();
    s.balance.tilt = GameConfig.spillThreshold + 1e-6;
    for (var i = 0; i < 60; i++) {
      s.game.update(1 / 60);
    }
    // 1 burst + ~5 trickle particles ≈ total 5–7 particle systems.
    expect(_emissions(s.game), inInclusiveRange(5, 7));
  });

  test('continuous rate at tilt=1.0 ≈ 15 per second', () async {
    final s = await _setup();
    s.balance.tilt = 1.0;
    for (var i = 0; i < 60; i++) {
      s.game.update(1 / 60);
    }
    // 1 burst + ~15 trickle particles ≈ total 15–17.
    expect(_emissions(s.game), inInclusiveRange(15, 17));
  });

  test('reset() clears edge detector — re-entry re-fires the burst', () async {
    final s = await _setup();
    s.balance.tilt = 0.8;
    s.game.update(1 / 60);  // burst
    s.emitter.reset();
    s.balance.tilt = 0;
    s.game.update(1 / 60);  // nothing
    final beforeReEntry = _emissions(s.game);

    s.balance.tilt = 0.8;
    s.game.update(1 / 60);
    expect(_emissions(s.game) - beforeReEntry, 1);
  });

  test('emitGameOverBurst adds exactly one ParticleSystemComponent', () async {
    final s = await _setup();
    s.balance.tilt = 1.0;
    final before = _emissions(s.game);
    s.emitter.emitGameOverBurst();
    await s.game.ready();
    expect(_emissions(s.game) - before, 1);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/splash_emitter_test.dart
```

Expected: FAIL — "Target of URI doesn't exist: 'package:hold_the_hooch/components/splash_emitter.dart'."

- [ ] **Step 3: Create the implementation**

Create `lib/components/splash_emitter.dart`:

```dart
import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import '../config/game_config.dart';
import 'gurgles.dart';
import 'hooch_balance.dart';

/// Emits hooch droplet particles whenever the tankard tilts past
/// [GameConfig.spillThreshold]. Emission pattern is hybrid:
/// - **Burst** (splashBurstCount) on each threshold entry (edge-triggered)
/// - **Trickle** at a rate that scales linearly with how far over threshold
///   the tilt sits (splashTrickleRateBase → splashTrickleRateMax)
/// - **Game-over burst** (splashGameOverBurstCount, wider spread, larger
///   radii) via explicit [emitGameOverBurst] call
///
/// Call [reset] on restart to clear the edge detector and rate accumulator.
class SplashEmitter extends Component {
  final Gurgles gurgles;
  final HoochBalance balance;
  final Random _rng;

  bool _wasOverThreshold = false;
  double _continuousAccum = 0;

  SplashEmitter({
    required this.gurgles,
    required this.balance,
    Random? rng,
  }) : _rng = rng ?? Random();

  @override
  void update(double dt) {
    super.update(dt);
    final over = balance.tilt.abs() > GameConfig.spillThreshold;

    if (over && !_wasOverThreshold) {
      _emitBurst(GameConfig.splashBurstCount, gameOver: false);
    }
    _wasOverThreshold = over;

    if (over) {
      final excess = (balance.tilt.abs() - GameConfig.spillThreshold) /
          (1.0 - GameConfig.spillThreshold);
      final rate = GameConfig.splashTrickleRateBase +
          excess *
              (GameConfig.splashTrickleRateMax -
                  GameConfig.splashTrickleRateBase);
      _continuousAccum += rate * dt;
      while (_continuousAccum >= 1.0) {
        _emitBurst(1, gameOver: false);
        _continuousAccum -= 1.0;
      }
    } else {
      _continuousAccum = 0;
    }
  }

  void emitGameOverBurst() {
    _emitBurst(GameConfig.splashGameOverBurstCount, gameOver: true);
  }

  void reset() {
    _wasOverThreshold = false;
    _continuousAccum = 0;
  }

  void _emitBurst(int count, {required bool gameOver}) {
    final origin = gurgles.tankardRimWorldPosition(balance.tilt);
    // Base velocity direction: sideways in the tilt direction + small upward pop.
    final tiltSign = balance.tilt == 0 ? 1.0 : balance.tilt.sign;
    final baseAngle = atan2(-0.6, tiltSign);
    final spread = gameOver ? pi / 3 : pi / 12; // 60° or 15°
    final speedMin = gameOver ? GameConfig.splashSpeedMin + 20 : GameConfig.splashSpeedMin;
    final speedMax = gameOver ? GameConfig.splashSpeedMax + 40 : GameConfig.splashSpeedMax;
    final radiusMin = gameOver ? 4.0 : 3.0;
    final radiusMax = gameOver ? 7.0 : 5.0;
    final lifespanMin = gameOver ? 0.9 : 0.6;
    final lifespanMax = gameOver ? 1.2 : 0.9;

    final particles = <Particle>[
      for (var i = 0; i < count; i++)
        _droplet(
          origin: origin,
          baseAngle: baseAngle,
          spread: spread,
          speedMin: speedMin,
          speedMax: speedMax,
          radius: radiusMin + _rng.nextDouble() * (radiusMax - radiusMin),
          lifespan: lifespanMin + _rng.nextDouble() * (lifespanMax - lifespanMin),
          creamHighlight: i % 3 == 0,
        ),
    ];
    parent?.add(ParticleSystemComponent(
      particle: ComposedParticle(children: particles),
    ));
  }

  /// Single amber droplet with closed-form ballistic motion:
  /// `pos(t) = origin + v0 * t + 0.5 * g * t²`.
  /// Every third droplet additionally renders a small cream highlight
  /// for foam-on-amber texture. Both circles fade together.
  Particle _droplet({
    required Vector2 origin,
    required double baseAngle,
    required double spread,
    required double speedMin,
    required double speedMax,
    required double radius,
    required double lifespan,
    required bool creamHighlight,
  }) {
    final angle = baseAngle + (_rng.nextDouble() * 2 - 1) * spread;
    final speed = speedMin + _rng.nextDouble() * (speedMax - speedMin);
    final v0 = Vector2(cos(angle), sin(angle)) * speed;
    final creamOffset = creamHighlight
        ? Vector2(
            (_rng.nextDouble() * 2 - 1) * 2,
            (_rng.nextDouble() * 2 - 1) * 2,
          )
        : Vector2.zero();
    const amber = Color(0xFFD4A017);
    const cream = Color(0xFFFFF9C4);

    return ComputedParticle(
      lifespan: lifespan,
      renderer: (canvas, particle) {
        final t = particle.progress * lifespan;
        final cx = origin.x + v0.x * t;
        final cy = origin.y + v0.y * t + 0.5 * GameConfig.splashGravity * t * t;
        final alpha = (255 * (1 - particle.progress)).round().clamp(0, 255);
        if (creamHighlight) {
          final creamPaint = Paint()..color = cream.withAlpha(alpha);
          canvas.drawCircle(
            Offset(cx + creamOffset.x, cy + creamOffset.y),
            2,
            creamPaint,
          );
        }
        final amberPaint = Paint()..color = amber.withAlpha(alpha);
        canvas.drawCircle(Offset(cx, cy), radius, amberPaint);
      },
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```
flutter test test/splash_emitter_test.dart
```

Expected: all 7 tests pass.

If the trickle-rate tests (`~5/sec`, `~15/sec`) fail with counts off by 1-2, the implementation is correct but the accumulator rounding drifts — widen the `inInclusiveRange` bounds by one and re-run. Do **not** alter the trickle-rate math itself.

- [ ] **Step 5: Run full suite + analyze**

```
flutter analyze && flutter test
```

Expected: analyze clean; 76 tests green (69 + 7 new).

- [ ] **Step 6: Commit**

```bash
git add lib/components/splash_emitter.dart test/splash_emitter_test.dart
git commit -m "M5a: SplashEmitter — hybrid burst+trickle with game-over flourish"
```

---

## Task 5: Wire SparkleBurst into pickup flow

`CollectibleManager`'s `onPickup` callback currently carries `(points, worldPos)`. We widen it to `(points, worldPos, kind)` so the scene can emit a kind-specific sparkle burst alongside the existing `ScorePopup`.

**Files:**
- Modify: [lib/systems/collectible_manager.dart](../../../lib/systems/collectible_manager.dart)
- Modify: [lib/scenes/game_scene.dart](../../../lib/scenes/game_scene.dart)

- [ ] **Step 1: Widen the `CollectibleManager.onPickup` signature**

Open `lib/systems/collectible_manager.dart`. Change the field declaration:

```dart
final void Function(int points, Vector2 worldPos) onPickup;
```

to:

```dart
final void Function(int points, Vector2 worldPos, CollectibleKind kind) onPickup;
```

In `_spawn`, change the Collectible constructor's `onPickup` argument:

```dart
      onPickup: onPickup,
```

to:

```dart
      onPickup: (pts, at) => onPickup(pts, at, kind),
```

This threads the `kind` local variable (already in scope from `_rollKind()`) through the callback while leaving `Collectible`'s own signature untouched.

- [ ] **Step 2: Update `GameScene` to consume the new signature**

Open `lib/scenes/game_scene.dart`. Add the import:

```dart
import '../components/sparkle_burst.dart';
```

Find the `CollectibleManager` construction in `onLoad` (around line 139). Change the `onPickup` callback:

```dart
      onPickup: (points, at) {
        _collectiblePoints += points;
        add(ScorePopup(points: points, position: at.clone()));
      },
```

to:

```dart
      onPickup: (points, at, kind) {
        _collectiblePoints += points;
        add(ScorePopup(points: points, position: at.clone()));
        add(SparkleBurst.emit(kind, at.clone()));
      },
```

- [ ] **Step 3: Run analyze + full suite**

```
flutter analyze && flutter test
```

Expected: analyze clean. 76 tests green — no new tests for this mechanical wiring since `SparkleBurst.emit` is already unit-tested and `CollectibleManager._spawn` isn't directly exercised in any test today.

- [ ] **Step 4: Commit**

```bash
git add lib/systems/collectible_manager.dart lib/scenes/game_scene.dart
git commit -m "M5a: thread CollectibleKind through pickup callback + emit SparkleBurst"
```

---

## Task 6: Wire SplashEmitter into GameScene + restart cleanup

Construct `SplashEmitter` in `GameScene.onLoad` after `gurgles` and `balance` are ready; clear in-flight particle components and reset emitter state in `restart()`. Extend the existing restart integration test with a particle-cleanup assertion.

**Files:**
- Modify: [lib/scenes/game_scene.dart](../../../lib/scenes/game_scene.dart)
- Modify: [test/game_scene_restart_test.dart](../../../test/game_scene_restart_test.dart)

- [ ] **Step 1: Extend the restart integration test**

Open `test/game_scene_restart_test.dart`. Add the import near the top (alongside the others):

```dart
import 'package:hold_the_hooch/components/sparkle_burst.dart';
```

Also add the Flame particles import (required for `ParticleSystemComponent`):

```dart
import 'package:flame/particles.dart';
```

Update `_StubGameScene.onLoad` to construct `splashEmitter` alongside the existing `gurgles` and `balance` initialisations. Change:

```dart
class _StubGameScene extends GameScene {
  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;

    const groundY = 600.0;
    groundYForTesting = groundY;
    gurgles = Gurgles(
      position: Vector2(88, groundY),
      groundY: groundY,
      size: Vector2(80, 144),
    );
    balance = HoochBalance();
  }
}
```

to:

```dart
class _StubGameScene extends GameScene {
  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;

    const groundY = 600.0;
    groundYForTesting = groundY;
    gurgles = Gurgles(
      position: Vector2(88, groundY),
      groundY: groundY,
      size: Vector2(80, 144),
    );
    balance = HoochBalance();
    splashEmitter = SplashEmitter(gurgles: gurgles, balance: balance);
  }
}
```

Add `import 'package:hold_the_hooch/components/splash_emitter.dart';` at the top.

In the main `test('GameScene.restart() removes obstacles, collectibles, and score popups', ...)` block, expand the seeding step. After the existing `game.add(ScorePopup(...))` line, add:

```dart
    game.add(SparkleBurst.emit(CollectibleKind.herb, Vector2(25, 25)));
    await game.ready();
```

In the pre-restart assertions, add:

```dart
    expect(game.children.whereType<ParticleSystemComponent>(), isNotEmpty);
```

Update the test's name to reflect the new coverage. Change:

```dart
  test('GameScene.restart() removes obstacles, collectibles, and score popups',
      () async {
```

to:

```dart
  test('GameScene.restart() removes obstacles, collectibles, score popups, and particle systems',
      () async {
```

In the post-restart assertions (after `await game.restart(); await game.ready();`), add:

```dart
    expect(game.children.whereType<ParticleSystemComponent>(), isEmpty);
```

- [ ] **Step 2: Run the test to verify it fails**

```
flutter test test/game_scene_restart_test.dart
```

Expected: FAIL — either `_StubGameScene` compilation error (SplashEmitter not yet added to production GameScene), or pre-restart `isNotEmpty` passes but post-restart `isEmpty` fails because production `restart()` doesn't clean particle systems.

- [ ] **Step 3: Add `splashEmitter` field to `GameScene`**

Open `lib/scenes/game_scene.dart`. At the top, add the import:

```dart
import '../components/splash_emitter.dart';
```

In the class body, alongside the other `late` fields (around line 28), add:

```dart
  late SplashEmitter splashEmitter;
```

In `onLoad`, after `balance = HoochBalance(); balance.setDriftDirection(...); add(balance);` (around line 128–130), add:

```dart
    splashEmitter = SplashEmitter(gurgles: gurgles, balance: balance);
    add(splashEmitter);
```

- [ ] **Step 4: Update `restart()` to clean particle systems + reset emitter**

Also in `lib/scenes/game_scene.dart`, find `restart()` (around line 234). Add the particles-cleanup import at the top of the file if not already present:

```dart
import 'package:flame/particles.dart';
```

In `restart()`, after the existing cleanup loops for Obstacle / Collectible / ScorePopup and before `_elapsed = 0;`, add:

```dart
    for (final p in children.whereType<ParticleSystemComponent>().toList()) {
      p.removeFromParent();
    }
    splashEmitter.reset();
```

- [ ] **Step 5: Run the integration test to verify it now passes**

```
flutter test test/game_scene_restart_test.dart
```

Expected: the updated test passes.

- [ ] **Step 6: Run the full suite + analyze**

```
flutter analyze && flutter test
```

Expected: analyze clean; 76 tests green (no net new tests — the restart test just grew assertions).

- [ ] **Step 7: Commit**

```bash
git add lib/scenes/game_scene.dart test/game_scene_restart_test.dart
git commit -m "M5a: mount SplashEmitter on GameScene + particle-aware restart"
```

---

## Task 7: Game-over `fromSpill` branch + delayed overlay

Add an optional `fromSpill` flag to `GameScene._end` so the spill-death path can fire the dramatic splash burst before the overlay covers the scene. Obstacle-hit path stays instant.

**Files:**
- Modify: [lib/scenes/game_scene.dart](../../../lib/scenes/game_scene.dart)

- [ ] **Step 1: Update `_end` signature + branch**

Open `lib/scenes/game_scene.dart`. Find `_end` (around line 226):

```dart
  void _end(String reason) {
    if (_gameOver) return;
    _gameOver = true;
    endReason = reason;
    pauseEngine();
    overlays.add(gameOverOverlayId);
  }
```

Replace with:

```dart
  void _end(String reason, {bool fromSpill = false}) {
    if (_gameOver) return;
    _gameOver = true;
    endReason = reason;

    if (fromSpill) {
      // Dramatic splash burst, then let it animate before the overlay covers it.
      // _gameOver = true above already blocks further update() logic during the
      // delay window; we deliberately keep the engine running so the particles
      // can animate.
      splashEmitter.emitGameOverBurst();
      Future.delayed(
        Duration(milliseconds: GameConfig.splashGameOverDelayMs),
        () {
          if (!isMounted) return;
          pauseEngine();
          overlays.add(gameOverOverlayId);
        },
      );
      return;
    }

    pauseEngine();
    overlays.add(gameOverOverlayId);
  }
```

- [ ] **Step 2: Update the spill call site**

In the same file, find the line in `update()` (around line 223):

```dart
    if (balance.hasSpilled) _end('You spilled the hooch!');
```

Change to:

```dart
    if (balance.hasSpilled) _end('You spilled the hooch!', fromSpill: true);
```

Leave the obstacle call site (`gurgles.onObstacleHit = () => _end('Hit an obstacle!')`) unchanged.

- [ ] **Step 3: Run full suite + analyze**

```
flutter analyze && flutter test
```

Expected: analyze clean; 76 tests green. No unit test for the delayed-overlay path — `Future.delayed` + `FlameGame` test lifecycle interactions are brittle. Device playtest in Task 8 covers the feel.

- [ ] **Step 4: Commit**

```bash
git add lib/scenes/game_scene.dart
git commit -m "M5a: dramatic game-over splash with delayed overlay on spill death"
```

---

## Task 8: Device playtest + tune pass

Code-complete at this point. Remaining work is the feel confirmation no unit test can do. Expect to adjust 0–3 constants in `GameConfig` after seeing the effects on the phone.

- [ ] **Step 1: Re-pair Samsung S26 Ultra**

Settings → Developer options → Wireless debugging. Get the current IP:port from the phone. Then:

```bash
"$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe" connect <ip>:<port>
flutter devices
```

Confirm the SM S948B appears.

- [ ] **Step 2: Build + install**

```bash
flutter build apk --debug
flutter install -d <ip>:<port> --debug
```

- [ ] **Step 3: Playtest the four moments**

Launch the game on the phone. Run through a full game-over and observe:

1. **Threshold-entry burst** — hold a tilt button until the spill meter just starts filling. Should see ~6 amber-with-cream-flecks droplets pop off the tankard rim in the tilt direction. Gravity pulls them down.
2. **Reactive trickle** — hold deeper into the spill zone (tilt near 1.0). The droplet stream should visibly intensify compared to just-over-threshold. Not a flood — should read as "stream", not "curtain".
3. **Pickup sparkles** — grab each of the three collectible kinds. Herb should feel modest (6 small green dots); hops should feel noticeable (10 mid gold); potion should feel distinctly special (16 big blue + halo ring).
4. **Game-over splash** — deliberately spill the hooch to game-over. A fat 30-particle amber burst should fire; 600ms later the game-over overlay appears. The burst should be clearly visible before the overlay covers it.

- [ ] **Step 4: Tune if needed**

Common adjustments in `lib/config/game_config.dart`:

- Trickle too busy: lower `splashTrickleRateMax` from 15 → 10 or 12.
- Game-over burst feels clipped by the overlay: increase `splashGameOverDelayMs` from 600 → 800.
- Potion sparkle not special enough: increase potion `count` in `sparkle_burst.dart:configFor` or `lifespan`.
- Game-over burst too subtle: increase `splashGameOverBurstCount` from 30 → 40 or radii in `SplashEmitter._emitBurst` (the `gameOver ? ...` ternaries).

Any tuning change should have the relevant invariant test still passing (`flutter test test/game_config_test.dart`) — the existing invariants allow re-tuning within the ordered ranges.

- [ ] **Step 5: Commit tuning (only if values changed)**

If no tuning was needed, skip this step. Otherwise:

```bash
git add lib/config/game_config.dart lib/components/sparkle_burst.dart
git commit -m "M5a: device-playtest tuning — <brief note>"
```

- [ ] **Step 6: Final verification run**

```bash
flutter analyze && flutter test
```

Expected: analyze clean; full suite green. This is the pre-docs-sync sanity gate.

---

## Task 9: Close M5a in ROADMAP + STATUS

Tick the two M5a visual checkboxes that we closed, refresh the STATUS test-file listing, and update the "Immediate next steps" to push M5a off the top of the list. Same retro-driven re-sweep pattern used to close M4c.

**Files:**
- Modify: [docs/ROADMAP.md](../../../docs/ROADMAP.md)
- Modify: [docs/STATUS.md](../../../docs/STATUS.md)

- [ ] **Step 1: Tick the M5a checkboxes in ROADMAP**

Open `docs/ROADMAP.md`. In the `### M5a — Visuals` section (around line 79), change:

```markdown
- [ ] **Splash particles** on spill (hooch-splash.svg emission when `|tilt| > threshold`).
- [ ] **Sparkle particles** on collectible pickup (sparkle.svg from art guide).
```

to:

```markdown
- [x] **Splash particles** on spill — programmatic emission via `SplashEmitter` (hybrid burst + trickle + dramatic game-over).
- [x] **Sparkle particles** on collectible pickup — programmatic, tinted + size-scaled per `CollectibleKind` via `SparkleBurst`.
```

(We replaced the SVG-asset phrasing with the actual programmatic implementation.)

- [ ] **Step 2: Update STATUS.md**

Open `docs/STATUS.md`. Bump the last-updated line at the top:

```markdown
_Last updated: 2026-04-20 (post M5a particles close)_
```

In the `## What's playable today` section (starts around line 11), add after the existing parallax bullet:

```markdown
- **Splash particles** — amber droplets with cream highlights burst from the tankard rim whenever the hooch tilts into the spill zone; rate scales with danger. Dramatic 30-droplet burst plays on spill-death before the game-over overlay appears.
- **Sparkle particles** — kind-specific bursts on collectible pickup: small green for herb, mid gold for hops, large blue with expanding halo for potion.
```

In the `## Directory layout` `lib/components/` block (around line 57), append:

```
    splash_emitter.dart               # hybrid burst+trickle splash on spill + game-over flourish
    sparkle_burst.dart                # per-kind sparkle burst factory on pickup
```

In the `test/` block (around line 87), append:

```
    splash_emitter_test.dart          # emitter state machine + rate math
    sparkle_burst_test.dart           # per-kind config ordering + mount smoke test
```

Find the `## Immediate next steps (in order)` section (around line 148). Replace with:

```markdown
## Immediate next steps (in order)

1. **M5a remaining polish** — 6-frame run cycle + hurt pose. Both art-dependent per [ART-GUIDE.md](ART-GUIDE.md); unblocked only when art lands.
2. **M5b audio pass** — wire SFX per [AUDIO-GUIDE.md](AUDIO-GUIDE.md). Blocked on audio delivery.
3. **M5c remaining UX** — tutorial overlay (first 1–2s of first run), settings (music / haptics / control toggles).
4. **First iOS build on the MacBook** ahead of M6 store prep.
5. **Design call on finite-hooch spill model** (see [ROADMAP.md § Design ideas to consider](ROADMAP.md)) — decide before M6 ship whether to swap the auto-drain spill mechanic for a finite-resource refill-via-collectibles model.
```

- [ ] **Step 3: Sanity re-run**

```
flutter analyze && flutter test
```

Expected: analyze clean; full suite green. This task is docs-only but we don't want to ship with a broken tree.

- [ ] **Step 4: Commit**

```bash
git add docs/ROADMAP.md docs/STATUS.md
git commit -m "docs: close M5a particles (splash + sparkle) in ROADMAP + STATUS"
```

---

## Final verification

After all 9 tasks land:

- [ ] `flutter analyze` clean
- [ ] `flutter test` — 76 tests green (60 + 5 SparkleBurst + 4 tankard rim + 7 SplashEmitter = 76)
- [ ] `git log --oneline -9` shows the nine new commits in order
- [ ] Device playtest confirmed all four moments (threshold burst, reactive trickle, per-kind sparkle, game-over burst) look right
- [ ] CodeMagic `android-debug` + `ios-debug` workflows pass on push to main

## Self-review checklist (run after writing the plan)

- [x] **Spec coverage:** every spec section maps to a task — splash hybrid emission (T4), game-over burst + delay (T7), sparkle per-kind table (T2), tankard rim math (T3), tuning constants (T1), CollectibleManager callback widening (T5), restart cleanup (T6), device playtest (T8), docs sync (T9).
- [x] **Placeholder scan:** no TBD/TODO/"handle edge cases". Every code block contains full content.
- [x] **Type consistency:** `SparkleBurst.configFor` returns `({int count, double radius, Color colour, double lifespan})` in Task 2 and is consumed with the same record shape in the implementation. `tankardRimWorldPosition(double tilt)` signature used consistently in Tasks 3 and 4. `onPickup` widened signature `(int, Vector2, CollectibleKind)` used identically in Task 5's two files. `splashEmitter` field type `SplashEmitter` consistent across Tasks 4, 6, 7.
- [x] **Deviation from spec noted:** the spec's `ComposedParticle([creamCircle, amberCircle])` suggestion is replaced with a single `ComputedParticle` rendering both circles, documented in the Context section. Behavior is identical; implementation is shorter and handles alpha fade in one place.
