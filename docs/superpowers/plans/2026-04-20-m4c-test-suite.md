# M4c — Minimum-Viable Test Suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the remaining M4c checklist items so M4 is fully green and regressions in core gameplay math / lifecycle cleanup / jump physics are guarded against before M5 polish lands.

**Architecture:** All additions are pure-function or component-level tests under `test/`. Two tasks require trivial source-side changes: one `@visibleForTesting` exposure on `Obstacle._hitboxFor`, one `@visibleForTesting` extraction of `Collectible` hitbox sizing. Two tasks add a lightweight Flame integration harness via `flame_test` for scene-level assertions that would otherwise require hand-rolled lifecycle scaffolding. Final task syncs `ROADMAP.md` / `STATUS.md` with the now-complete M4c state.

**Tech Stack:** Flutter 3.41.4, Dart 3.11.1, Flame 1.37, `flutter_test` (already present), `flame_test` 1.x (to be added in Task 4), `package:flutter/foundation.dart` for `@visibleForTesting`.

---

## Context summary (read before diving in)

The "minimum-viable test suite" goal was specified in [docs/ROADMAP.md § M4c](../../../docs/ROADMAP.md#m4c--minimum-viable-test-suite). Roughly half was completed in prior sessions and the checklist drifted. The current test baseline after this plan ships should be:

| Area | Status before this plan | Covered by existing test file |
|------|-------------------------|-------------------------------|
| HoochBalance wobble ramp / drift bias / spill-drain bonus / drift-crosses-threshold | ✅ | [test/hooch_balance_test.dart](../../../test/hooch_balance_test.dart) |
| HoochBalance tilt clamp / jump impulse | ❌ | — |
| GameConfig baseline ordering (jump vel, spill thresholds, multiplier, potion bonus) | ✅ | [test/game_config_test.dart](../../../test/game_config_test.dart) |
| GameConfig duration positivity + "torque beats drift" invariant | ❌ | — |
| Score multiplier pure fn | ✅ | [test/multiplier_test.dart](../../../test/multiplier_test.dart) |
| ScorePopup render smoke test | ✅ | [test/score_popup_test.dart](../../../test/score_popup_test.dart) |
| Tankard rotation pure fn | ✅ | [test/tankard_rotation_test.dart](../../../test/tankard_rotation_test.dart) |
| Leaderboard utils + widget row | ✅ | [test/leaderboard_utils_test.dart](../../../test/leaderboard_utils_test.dart), [test/leaderboard_entry_row_test.dart](../../../test/leaderboard_entry_row_test.dart) |
| **Obstacle hitbox ⊂ sprite bounds** | ❌ | — |
| **Collectible hitbox ⊂ sprite bounds** | ❌ | — |
| **GameScene.restart() cleanup** | ❌ | — |
| **Gurgles peak-jump height (physics integration)** | ❌ | — |

Six tasks below, each one commit. Start with the zero-dependency unit tests (Tasks 1–3), add the Flame harness once (Task 4) and reuse it for Task 5, close the books in Task 6.

---

## Task 1: HoochBalance tilt-clamp + jump-impulse regression guard

Current `hooch_balance_test.dart` exercises wobble amplitude, drift, and drain bonus. It does NOT cover:
- `applyTiltTorque` clamping to `[-1.0, 1.0]`
- `applyJumpImpulse` adding `±0.18` and respecting the same clamp

Both are load-bearing — a regression in either would silently break the spill meter ceiling or the jump-adds-chaos mechanic.

**Files:**
- Modify: [test/hooch_balance_test.dart](../../../test/hooch_balance_test.dart) (append new groups; do NOT touch existing groups)

- [ ] **Step 1: Append the new test groups**

Append to `test/hooch_balance_test.dart` AFTER the closing `});` of the final existing group (`HoochBalance directional drift bias`) and BEFORE the closing `}` of `void main()`:

```dart
  group('HoochBalance applyTiltTorque clamp', () {
    test('positive torque past 1.0 clamps at 1.0', () {
      final b = HoochBalance();
      b.applyTiltTorque(1.5);
      expect(b.tilt, 1.0);
    });

    test('negative torque past -1.0 clamps at -1.0', () {
      final b = HoochBalance();
      b.applyTiltTorque(-1.5);
      expect(b.tilt, -1.0);
    });

    test('small torque accumulates without clamp', () {
      final b = HoochBalance();
      b.applyTiltTorque(0.3);
      b.applyTiltTorque(0.3);
      expect((b.tilt - 0.6).abs(), lessThan(1e-9));
    });
  });

  group('HoochBalance applyJumpImpulse', () {
    test('impulse moves tilt by exactly 0.18 in some direction', () {
      // applyJumpImpulse picks a random direction, so run enough trials that
      // we cover both signs; every single call must move |tilt| by 0.18.
      for (var i = 0; i < 20; i++) {
        final b = HoochBalance();
        b.applyJumpImpulse();
        expect(b.tilt.abs(), closeTo(0.18, 1e-9));
      }
    });

    test('impulse applied near +1.0 clamps rather than overshooting', () {
      // Seed tilt so any positive-direction impulse would push past the clamp.
      // We re-try until the random direction is positive (usually in <5 tries).
      for (var i = 0; i < 50; i++) {
        final b = HoochBalance();
        b.tilt = 0.95;
        b.applyJumpImpulse();
        // If the random direction was negative, tilt fell to 0.77 — retry.
        if (b.tilt < 0.95) continue;
        expect(b.tilt, 1.0);
        return;
      }
      fail('applyJumpImpulse never rolled a positive direction in 50 trials');
    });

    test('impulse applied near -1.0 clamps rather than overshooting', () {
      for (var i = 0; i < 50; i++) {
        final b = HoochBalance();
        b.tilt = -0.95;
        b.applyJumpImpulse();
        if (b.tilt > -0.95) continue;
        expect(b.tilt, -1.0);
        return;
      }
      fail('applyJumpImpulse never rolled a negative direction in 50 trials');
    });
  });
```

- [ ] **Step 2: Run the new tests and the whole file**

Run: `flutter test test/hooch_balance_test.dart`
Expected: all tests pass (existing 9 + 6 new = 15 green). The clamp behaviour is already implemented in [lib/components/hooch_balance.dart](../../../lib/components/hooch_balance.dart); these are regression guards on existing code, so they should pass first try.

- [ ] **Step 3: Commit**

```bash
git add test/hooch_balance_test.dart
git commit -m "M4c: regression guards for HoochBalance tilt clamp + jump impulse"
```

---

## Task 2: GameConfig expanded invariants

Current `game_config_test.dart` covers ordering and positivity for the most-touched constants. Missing:
- Duration/rate positivity (`difficultyRampSeconds`, `jumpHoldMaxMs`, `gravity`, `wobbleBaseAmplitude`, `wobbleBaseFrequency`)
- Spill thresholds sit in `[0, 1]` (not just ordered)
- `driftRateMax > driftRateBase > 0`
- `tiltButtonTorqueRate > driftRateMax` — the comment in [lib/config/game_config.dart:66-67](../../../lib/config/game_config.dart#L66-L67) promises "player can always out-correct the drift". If someone tunes `driftRateMax` above `tiltButtonTorqueRate`, the player would lose this guarantee silently.

**Files:**
- Modify: [test/game_config_test.dart](../../../test/game_config_test.dart)

- [ ] **Step 1: Append the new invariant tests**

Append new `test(...)` entries INSIDE the existing `group('GameConfig invariants', () { ... })`, just before its closing `});`:

```dart
    test('difficulty and hold durations are positive', () {
      expect(GameConfig.difficultyRampSeconds, greaterThan(0));
      expect(GameConfig.jumpHoldMaxMs, greaterThan(0));
    });

    test('gravity and wobble base magnitudes are positive', () {
      expect(GameConfig.gravity, greaterThan(0));
      expect(GameConfig.wobbleBaseAmplitude, greaterThan(0));
      expect(GameConfig.wobbleBaseFrequency, greaterThan(0));
    });

    test('spill thresholds live in [0, 1]', () {
      expect(GameConfig.spillThreshold, inInclusiveRange(0.0, 1.0));
      expect(GameConfig.spillDrainThreshold, inInclusiveRange(0.0, 1.0));
    });

    test('drift rates are ordered and positive', () {
      expect(GameConfig.driftRateBase, greaterThan(0));
      expect(GameConfig.driftRateMax, greaterThan(GameConfig.driftRateBase));
    });

    test('tiltButtonTorqueRate beats driftRateMax so player can out-correct drift', () {
      // If this invariant breaks, the tilt buttons would apply torque slower
      // than the passive drift fills it — the player would be unable to
      // correct a drifting hooch, making runs impossible to sustain.
      expect(GameConfig.tiltButtonTorqueRate, greaterThan(GameConfig.driftRateMax));
    });

    test('control-strip layout constants are positive', () {
      expect(GameConfig.controlStripHeightFraction, inExclusiveRange(0.0, 1.0));
      expect(GameConfig.tiltButtonSize, greaterThan(0));
      expect(GameConfig.tiltButtonInset, greaterThanOrEqualTo(0));
      expect(GameConfig.tiltButtonGap, greaterThanOrEqualTo(0));
    });

    test('tankard lean is a sensible radian value (not degrees by mistake)', () {
      // 0.6 rad ≈ 34°. If someone set it to 34 expecting degrees, the tankard
      // would spin wildly. Guard: value must be well under π.
      expect(GameConfig.tankardMaxLeanRadians, inExclusiveRange(0.0, 1.5));
    });
```

- [ ] **Step 2: Run the tests**

Run: `flutter test test/game_config_test.dart`
Expected: all tests pass (existing 5 + 7 new = 12 green). These are pure constant assertions.

- [ ] **Step 3: Commit**

```bash
git add test/game_config_test.dart
git commit -m "M4c: expand GameConfig invariants (durations, drift ordering, torque guarantee)"
```

---

## Task 3: Obstacle + Collectible hitbox-sizing bounds

`Obstacle._hitboxFor(kind, size)` returns `(pos, size)` for a `RectangleHitbox`. The hitbox must always be a strict subset of the sprite bounds — otherwise grazes along sprite edges register as hits and "fair platformer" feel breaks. The method is currently private (`_hitboxFor`), which prevents direct test access. Same situation for `Collectible`'s inline hitbox-sizing logic in `onLoad` (hardcoded 90% / 5% inset).

Strategy: rename to non-underscore names and annotate with `@visibleForTesting` on both, then assert the per-kind bounds.

**Files:**
- Modify: [lib/components/obstacle.dart](../../../lib/components/obstacle.dart) (rename `_hitboxFor` → `hitboxFor` + add `@visibleForTesting`)
- Modify: [lib/components/collectible.dart](../../../lib/components/collectible.dart) (extract inline sizing into `@visibleForTesting static hitboxFor(Vector2 size)`)
- Create: `test/obstacle_hitbox_test.dart`
- Create: `test/collectible_hitbox_test.dart`

- [ ] **Step 1: Write the failing Obstacle test**

Create `test/obstacle_hitbox_test.dart`:

```dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/obstacle.dart';

void main() {
  group('Obstacle hitbox is a strict subset of the sprite rect', () {
    final spriteSize = Vector2(100, 100);

    for (final kind in ObstacleKind.values) {
      test('$kind hitbox sits fully inside [0..size] on both axes', () {
        final hb = Obstacle.hitboxFor(kind, spriteSize);
        expect(hb.pos.x, greaterThanOrEqualTo(0));
        expect(hb.pos.y, greaterThanOrEqualTo(0));
        expect(hb.size.x, greaterThan(0));
        expect(hb.size.y, greaterThan(0));
        expect(hb.pos.x + hb.size.x, lessThanOrEqualTo(spriteSize.x));
        expect(hb.pos.y + hb.size.y, lessThanOrEqualTo(spriteSize.y));
      });
    }

    test('hitbox area is meaningfully smaller than sprite area (fair grazes)', () {
      for (final kind in ObstacleKind.values) {
        final hb = Obstacle.hitboxFor(kind, spriteSize);
        final hbArea = hb.size.x * hb.size.y;
        final spriteArea = spriteSize.x * spriteSize.y;
        // No hitbox should fill more than 80% of its sprite — otherwise
        // edge-grazes start registering as hits and the game feels unfair.
        expect(hbArea / spriteArea, lessThan(0.80), reason: '$kind too generous');
      }
    });
  });
}
```

- [ ] **Step 2: Run the test (expect FAIL — symbol private)**

Run: `flutter test test/obstacle_hitbox_test.dart`
Expected: FAIL — compile error "The method 'hitboxFor' isn't defined for the class 'Obstacle'."

- [ ] **Step 3: Make `hitboxFor` visible**

In [lib/components/obstacle.dart](../../../lib/components/obstacle.dart), change the `_hitboxFor` declaration and the single call site.

Add this import near the top (after existing imports):

```dart
import 'package:flutter/foundation.dart' show visibleForTesting;
```

Replace the declaration (currently on line 40):

```dart
  /// Hitbox as fractions of the sprite bounds, tuned per-obstacle from the
  /// actual SVG silhouette (see docs/GAME_DESIGN.md). Values here are
  /// intentionally smaller than the visual — platformers feel fairer when
  /// grazes don't register as hits.
  static ({Vector2 pos, Vector2 size}) _hitboxFor(ObstacleKind k, Vector2 s) => switch (k) {
```

with:

```dart
  /// Hitbox as fractions of the sprite bounds, tuned per-obstacle from the
  /// actual SVG silhouette (see docs/GAME_DESIGN.md). Values here are
  /// intentionally smaller than the visual — platformers feel fairer when
  /// grazes don't register as hits.
  @visibleForTesting
  static ({Vector2 pos, Vector2 size}) hitboxFor(ObstacleKind k, Vector2 s) => switch (k) {
```

Then in `onLoad` (line 69), change:

```dart
    final hb = _hitboxFor(kind, size);
```

to:

```dart
    final hb = hitboxFor(kind, size);
```

- [ ] **Step 4: Re-run the Obstacle test (expect PASS)**

Run: `flutter test test/obstacle_hitbox_test.dart`
Expected: all 5 tests pass (4 per-kind + 1 area).

- [ ] **Step 5: Write the failing Collectible test**

Create `test/collectible_hitbox_test.dart`:

```dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/collectible.dart';

void main() {
  group('Collectible hitbox is a strict subset of the sprite rect', () {
    final sizes = [
      Vector2(48, 48),   // herb reference size
      Vector2(48, 56),   // hops
      Vector2(40, 56),   // potion
      Vector2(100, 100), // arbitrary scale
    ];

    for (final s in sizes) {
      test('hitbox for sprite ${s.x}x${s.y} fits inside bounds', () {
        final hb = Collectible.hitboxFor(s);
        expect(hb.pos.x, greaterThanOrEqualTo(0));
        expect(hb.pos.y, greaterThanOrEqualTo(0));
        expect(hb.size.x, greaterThan(0));
        expect(hb.size.y, greaterThan(0));
        expect(hb.pos.x + hb.size.x, lessThanOrEqualTo(s.x));
        expect(hb.pos.y + hb.size.y, lessThanOrEqualTo(s.y));
      });
    }

    test('hitbox is centered inside sprite (symmetric insets)', () {
      final s = Vector2(100, 100);
      final hb = Collectible.hitboxFor(s);
      final rightInset = s.x - (hb.pos.x + hb.size.x);
      final bottomInset = s.y - (hb.pos.y + hb.size.y);
      expect((hb.pos.x - rightInset).abs(), lessThan(1e-9));
      expect((hb.pos.y - bottomInset).abs(), lessThan(1e-9));
    });
  });
}
```

- [ ] **Step 6: Run the test (expect FAIL — symbol missing)**

Run: `flutter test test/collectible_hitbox_test.dart`
Expected: FAIL — "The method 'hitboxFor' isn't defined for the class 'Collectible'."

- [ ] **Step 7: Extract Collectible `hitboxFor`**

In [lib/components/collectible.dart](../../../lib/components/collectible.dart), add the same `visibleForTesting` import if not already present:

```dart
import 'package:flutter/foundation.dart' show VoidCallback, visibleForTesting;
```

(The file already imports `VoidCallback` from `package:flutter/foundation.dart`; just extend the show clause.)

Add a new static method below the existing `pointsFor` (around line 46):

```dart
  /// Active hitbox for pickup detection. 90% of sprite, centered via 5% inset
  /// on each side, so edge-grazes don't award points and clipping-in visually
  /// always corresponds to a real pickup.
  @visibleForTesting
  static ({Vector2 pos, Vector2 size}) hitboxFor(Vector2 spriteSize) => (
        pos: Vector2(spriteSize.x * 0.05, spriteSize.y * 0.05),
        size: Vector2(spriteSize.x * 0.9, spriteSize.y * 0.9),
      );
```

Then in `onLoad` (currently lines 48-59), replace:

```dart
    // Active hitbox (default) so Collectible.onCollisionStart fires when
    // Gurgles overlaps — with passive we'd only get the callback on
    // Gurgles' side and onPickup would never run.
    add(RectangleHitbox(
      size: Vector2(size.x * 0.9, size.y * 0.9),
      position: Vector2(size.x * 0.05, size.y * 0.05),
    ));
```

with:

```dart
    // Active hitbox (default) so Collectible.onCollisionStart fires when
    // Gurgles overlaps — with passive we'd only get the callback on
    // Gurgles' side and onPickup would never run.
    final hb = hitboxFor(size);
    add(RectangleHitbox(size: hb.size, position: hb.pos));
```

- [ ] **Step 8: Re-run the Collectible test (expect PASS)**

Run: `flutter test test/collectible_hitbox_test.dart`
Expected: all 5 tests pass (4 per-size + 1 centering).

- [ ] **Step 9: Verify nothing else broke**

Run: `flutter analyze && flutter test`
Expected: analyze clean; full test suite green.

- [ ] **Step 10: Commit**

```bash
git add lib/components/obstacle.dart lib/components/collectible.dart test/obstacle_hitbox_test.dart test/collectible_hitbox_test.dart
git commit -m "M4c: expose + test Obstacle/Collectible hitbox sizing bounds"
```

---

## Task 4: Add `flame_test` + GameScene.restart() cleanup integration test

`GameScene.restart()` walks `children.whereType<Obstacle>()`, `whereType<Collectible>()`, and `whereType<ScorePopup>()` and removes each. The regression risk: when a new gameplay entity is added later (e.g. a splash particle effect in M5), it's easy to forget to include it in the cleanup loop. A dead entity persisting through restart creates score pollution or visual artefacts on the next run.

This task adds `flame_test` as a dev dep (used here and in Task 5), then writes a test that:
1. Constructs a `GameScene` via `FlameTester`
2. Seeds it with an `Obstacle`, a `Collectible`, and a `ScorePopup` added directly
3. Calls `restart()`
4. Asserts no instances of any of the three types remain

**Files:**
- Modify: [pubspec.yaml](../../../pubspec.yaml) (add `flame_test` under `dev_dependencies`)
- Create: `test/game_scene_restart_test.dart`

- [ ] **Step 1: Add `flame_test` to dev_dependencies**

In [pubspec.yaml](../../../pubspec.yaml), find the `dev_dependencies:` section (line 44). Add `flame_test` alongside `flutter_test` and `flutter_lints`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter

  flame_test: ^1.18.0

  # The "flutter_lints" package below contains a set of recommended lints to
  # encourage good coding practices. The lint set provided by the package is
  # activated in the `analysis_options.yaml` file located at the root of your
  # package. See that file for information about deactivating specific lint
  # rules and activating additional ones.
  flutter_lints: ^6.0.0
```

Then run:

```bash
flutter pub get
```

Expected: dependency resolves without conflict. (`flame_test ^1.18.0` is the 1.x line compatible with `flame ^1.37.0`; if pub solver complains, fall back to `flame_test: any` and pin once `flutter pub deps` shows the resolved version.)

- [ ] **Step 2: Write the failing test**

Create `test/game_scene_restart_test.dart`:

```dart
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/collectible.dart';
import 'package:hold_the_hooch/components/obstacle.dart';
import 'package:hold_the_hooch/components/score_popup.dart';
import 'package:hold_the_hooch/scenes/game_scene.dart';

void main() {
  final tester = FlameTester<GameScene>(
    () => GameScene(),
    pumpOnCreation: false,
  );

  tester.testGameWidget(
    'GameScene.restart() removes obstacles, collectibles, and score popups',
    verify: (game, _) async {
      game.onGameResize(Vector2(400, 800));
      await game.onLoad();
      await game.ready();

      // Seed one of each entity type directly. We use .ready() instead of
      // awaiting .add so the scheduler has a chance to mount them before
      // restart() queries children.whereType.
      final ob = Obstacle(
        kind: ObstacleKind.rock,
        position: Vector2(100, 100),
        scrollSpeed: 0,
      );
      final co = Collectible(
        kind: CollectibleKind.herb,
        position: Vector2(200, 100),
        scrollSpeed: 0,
        onPickup: (_, __) {},
      );
      final sp = ScorePopup(points: 10, position: Vector2(50, 50));

      game.add(ob);
      game.add(co);
      game.add(sp);
      await game.ready();

      expect(game.children.whereType<Obstacle>(), isNotEmpty);
      expect(game.children.whereType<Collectible>(), isNotEmpty);
      expect(game.children.whereType<ScorePopup>(), isNotEmpty);

      await game.restart();
      await game.ready();

      expect(game.children.whereType<Obstacle>(), isEmpty);
      expect(game.children.whereType<Collectible>(), isEmpty);
      expect(game.children.whereType<ScorePopup>(), isEmpty);
    },
  );
}
```

- [ ] **Step 3: Run the test**

Run: `flutter test test/game_scene_restart_test.dart`
Expected result: PASS. `restart()` already clears all three types per [lib/scenes/game_scene.dart:234-257](../../../lib/scenes/game_scene.dart#L234-L257); this is a regression guard, not a new feature.

**If it fails with an asset-loading error** (e.g. `Unable to load asset: svg/...`): the Flame SVG loader needs the Flutter asset bundle bound. Add `TestWidgetsFlutterBinding.ensureInitialized();` as the first line inside `void main() {}` and re-run.

**If it fails because `Obstacle`/`Collectible` can't mount without SVG loads in test:** fall back to seeding stub subclasses. Replace the seeding block with:

```dart
      // Minimal stubs that skip SVG loading but retain the real type so
      // restart()'s whereType<Obstacle>() still matches them.
      game.add(_StubObstacle());
      game.add(_StubCollectible());
      game.add(ScorePopup(points: 10, position: Vector2(50, 50)));
```

And add at the bottom of the file:

```dart
class _StubObstacle extends Obstacle {
  _StubObstacle()
      : super(
          kind: ObstacleKind.rock,
          position: Vector2.zero(),
          scrollSpeed: 0,
        );
  @override
  Future<void> onLoad() async {}
}

class _StubCollectible extends Collectible {
  _StubCollectible()
      : super(
          kind: CollectibleKind.herb,
          position: Vector2.zero(),
          scrollSpeed: 0,
          onPickup: _noop,
        );
  @override
  Future<void> onLoad() async {}
}

void _noop(int points, Vector2 at) {}
```

- [ ] **Step 4: Verify the whole suite stays green**

Run: `flutter analyze && flutter test`
Expected: analyze clean; all tests pass.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock test/game_scene_restart_test.dart
git commit -m "M4c: add flame_test + GameScene.restart() cleanup integration test"
```

---

## Task 5: Gurgles peak-jump height integration test

The comment in [lib/systems/collectible_manager.dart:50-54](../../../lib/systems/collectible_manager.dart#L50-L54) claims Gurgles' hitbox top reaches ~208px above ground at peak jump (feet peak ~92px + ~116px body clearance). Collectible height tiers are set relative to that — potion tier sits at `groundY - 180 × sizeScale`. If jump tuning drifts and the potion tier stops being reachable, the top collectible becomes unachievable silently.

This test drives Gurgles through a max-hold jump and asserts feet peak clears a threshold that keeps the potion tier in reach.

**Files:**
- Create: `test/gurgles_physics_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/gurgles_physics_test.dart`:

```dart
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/gurgles.dart';
import 'package:hold_the_hooch/config/game_config.dart';

/// Drives Gurgles through a full-hold jump arc and records the feet-peak
/// height (groundY - minimum y observed).
///
/// Assertion: peak feet height >= 90px at sizeScale 1.0. Potion tier sits
/// at groundY - 180px from [CollectibleManager], but the *hitbox top*
/// clears ~208px above ground at peak (feet peak + body-above-feet). The
/// 90px floor here is a conservative peak-feet guard — if this drops,
/// we've broken the physics contract even before potion reachability.
class _PhysicsHost extends FlameGame {
  late Gurgles gurgles;
  final double groundY = 600.0;

  @override
  Future<void> onLoad() async {
    gurgles = _StubGurgles(groundY: groundY);
    await add(gurgles);
  }
}

/// Skip SVG loads; keep the physics math intact. Gurgles.onLoad loads SVGs
/// and initialises `_runSvg` / `_jumpSvg` which are then touched in
/// `_swapSprite()` every update — we stub both out so the physics loop
/// runs in isolation.
class _StubGurgles extends Gurgles {
  _StubGurgles({required double groundY})
      : super(
          position: Vector2(200, groundY),
          groundY: groundY,
          size: Vector2(80, 100),
        );

  @override
  Future<void> onLoad() async {
    // Intentionally skip SVG loads. Physics (velocityY, y, jump state)
    // lives on Gurgles itself; no visual components required.
  }
}

void main() {
  final tester = FlameTester<_PhysicsHost>(
    () => _PhysicsHost(),
    pumpOnCreation: false,
  );

  tester.testGameWidget(
    'Gurgles peak feet height on max-hold jump clears the 90px floor',
    verify: (host, _) async {
      host.onGameResize(Vector2(400, 800));
      await host.onLoad();
      await host.ready();

      final g = host.gurgles;
      g.startJump();

      double minY = g.y;
      const dt = 1 / 60;
      // 1.5s is well beyond full hold (220ms) + descent back to ground.
      for (var i = 0; i < 90; i++) {
        host.update(dt);
        if (g.y < minY) minY = g.y;
      }

      final peakFeetHeight = host.groundY - minY;

      // Primary guard: must clear 90px at sizeScale 1.0. If this regresses,
      // the potion tier (180px + body clearance) becomes unreachable.
      expect(peakFeetHeight, greaterThanOrEqualTo(90.0),
          reason: 'feet peak $peakFeetHeight < 90px — jump too weak');

      // Secondary guard: must return to ground by end of simulation.
      expect(g.y, closeTo(host.groundY, 1.0),
          reason: 'Gurgles did not return to ground after jump');
    },
  );

  tester.testGameWidget(
    'Short-tap jump (no hold) peaks lower than full-hold jump',
    verify: (host, _) async {
      host.onGameResize(Vector2(400, 800));
      await host.onLoad();
      await host.ready();

      final g = host.gurgles;
      g.startJump();
      g.endJump(); // Release immediately — velocity stays at jumpVelocityMin.

      double minY = g.y;
      const dt = 1 / 60;
      for (var i = 0; i < 90; i++) {
        host.update(dt);
        if (g.y < minY) minY = g.y;
      }
      final shortHop = host.groundY - minY;

      // Expected: short-hop feet peak lives in the 30–60px band. Max full
      // jump (prev test) clears 90px. If these cross, tap-and-hold lost
      // its role.
      expect(shortHop, lessThan(90.0));
      expect(shortHop, greaterThan(20.0));
    },
  );

  test('GameConfig jump constants still produce a positive peak analytically', () {
    // Sanity check independent of the simulation: 0.5 * v0^2 / g gives the
    // theoretical minimum peak (instant release). If this drops below 30px
    // someone has turned jumps into nudges.
    final v0 = GameConfig.jumpVelocityMin.abs();
    final g = GameConfig.gravity;
    final theoreticalMinPeak = (v0 * v0) / (2 * g);
    expect(theoreticalMinPeak, greaterThan(30.0));
  });
}
```

- [ ] **Step 2: Run the test**

Run: `flutter test test/gurgles_physics_test.dart`
Expected: all 3 tests pass. Current tuning (`jumpVelocityMin = -480`, `jumpVelocityMax = -720`, `jumpHoldMaxMs = 220`, `gravity = 2800`) produces feet peaks well above 90px on full hold and well under that on short tap.

**If the test fails with peak ≈ 0:** Gurgles.update() likely errored silently on `_swapSprite` touching `_runSvg`. Confirm by temporarily wrapping `_swapSprite(!onGround)` with a `try/catch` print in Gurgles.update — if the stub needs more shielding, override `update` in `_StubGurgles` to call only the physics half (or override `_swapSprite` via a protected hook).

If you need to gate `_swapSprite` in production code, the minimal safe change is in [lib/components/gurgles.dart](../../../lib/components/gurgles.dart) — wrap the body of `_swapSprite` with `if (!contains(_runSvg) && !contains(_jumpSvg)) return;`. Document this as a regression-safety guard (runs pre-onLoad or in stubbed tests).

- [ ] **Step 3: Full suite green check**

Run: `flutter analyze && flutter test`
Expected: analyze clean; all tests green.

- [ ] **Step 4: Commit**

```bash
git add test/gurgles_physics_test.dart
# If gurgles.dart was touched for the _swapSprite guard, add it too:
# git add lib/components/gurgles.dart
git commit -m "M4c: Gurgles peak-jump integration test via flame_test"
```

---

## Task 6: Close M4c in docs + update STATUS snapshot

All M4c items are now green. ROADMAP and STATUS need to reflect that, or the next session inherits stale "❌ not done" claims — the exact doc-drift failure mode retro called out.

**Files:**
- Modify: [docs/ROADMAP.md](../../../docs/ROADMAP.md) (check off all M4c items; optionally mark M4 as ✅)
- Modify: [docs/STATUS.md](../../../docs/STATUS.md) (update TL;DR, "What's playable today", "Milestone progress", "Immediate next steps", test-suite line in the layout block)

- [ ] **Step 1: Tick the M4c checklist**

In [docs/ROADMAP.md](../../../docs/ROADMAP.md) find the `### M4c — Minimum viable test suite` section (line ~53). Replace all six `- [ ]` entries with `- [x]` entries. Keep the text identical otherwise.

Also update the parent `## M4 — Content pass ⏳` (if still showing `⏳`) to `## M4 — Content pass ✅` and add a trailing line noting completion date:

```markdown
## M4 — Content pass ✅

_Closed 2026-04-20 — minimum-viable test suite (M4c) landed; M4a/M4b already done._
```

- [ ] **Step 2: Update STATUS.md**

In [docs/STATUS.md](../../../docs/STATUS.md):

1. Bump the "Last updated" line to `_Last updated: 2026-04-20 (post M4c test-suite close)_`.
2. In the **Milestone progress** section, leave `M4 — Content pass ✅ Complete.` as-is (already correct).
3. Update the **Immediate next steps** section (line ~148) — strike #2 (M4c work), re-number remaining items. New list:

   ```markdown
   ## Immediate next steps (in order)

   1. **M5 polish** — splash particles on spill, sparkle on pickup, tutorial overlay, settings. SFX pass blocked on audio delivery per [AUDIO-GUIDE.md](AUDIO-GUIDE.md).
   2. **First iOS build on the MacBook** ahead of M6 store prep.
   3. **Design call on finite-hooch spill model** (see [ROADMAP.md § Design ideas to consider](ROADMAP.md)) — decide before M6 ship whether to swap the auto-drain spill mechanic for a finite-resource refill-via-collectibles model.
   ```

4. In the **Directory layout** test list (around line 87-94), add the new test files. Replace the block:

   ```
   test/
     game_config_test.dart               # GameConfig invariants
     hooch_balance_test.dart             # wobble ramp + drift bias + spill-drain
     multiplier_test.dart                # score multiplier pure function
     score_popup_test.dart               # pickup-animation regression guard
     tankard_rotation_test.dart          # tankardAngleForTilt pure fn
     leaderboard_utils_test.dart         # formatScore pure fn
     leaderboard_entry_row_test.dart     # widget test: rank/name/score/highlight
   ```

   with:

   ```
   test/
     game_config_test.dart               # GameConfig invariants (ordering + durations + torque-beats-drift)
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
   ```

5. In the **Known issues & deferred work** table, drop issue `#16` ("Test suite is effectively empty") — it's now false. Or replace its row with a note that it's closed:

   ```markdown
   | ~~16~~ | ~~Test suite is effectively empty~~ | ~~Med~~ | **Closed 2026-04-20.** M4c minimum-viable suite landed (HoochBalance clamps, GameConfig invariants, Obstacle/Collectible hitbox bounds, GameScene.restart() cleanup, Gurgles peak-jump). |
   ```

- [ ] **Step 3: Verify nothing broke**

Run: `flutter analyze && flutter test`
Expected: full suite green. (Sanity run; this task is docs-only.)

- [ ] **Step 4: Commit**

```bash
git add docs/ROADMAP.md docs/STATUS.md
git commit -m "docs: close M4c in ROADMAP + STATUS (test suite landed)"
```

---

## Final verification

After all six tasks commit:

- [ ] Run `flutter analyze` → expect clean
- [ ] Run `flutter test` → expect ~50+ tests, all green
- [ ] `git log --oneline -6` shows the six new commits in order
- [ ] CodeMagic `android-debug` and `ios-debug` workflows pass on push to main (wait ~2–3 min after push; check dashboard)

## Self-review checklist (run after writing the plan)

- [x] **Spec coverage:** every M4c checklist item from ROADMAP has a corresponding task (HoochBalance clamps → T1, GameConfig → T2, hitbox sizing → T3, ScorePopup already done, restart() → T4, Gurgles physics → T5, docs → T6).
- [x] **Placeholder scan:** no TBD/TODO, no "handle edge cases", all code blocks contain full content.
- [x] **Type consistency:** `hitboxFor` named consistently across Tasks 3 (both Obstacle + Collectible use that name); `FlameTester` usage identical in Tasks 4 & 5.
