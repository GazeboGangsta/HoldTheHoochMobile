# M4b — Gameplay systems (multiplier, potion bonus, wobble ramp) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the three missing gameplay systems from [docs/GAME_DESIGN.md](../../GAME_DESIGN.md) that M4 requires: a score multiplier that ramps with survival time, a potion pickup bonus that drains the spill meter, and wobble-amplitude scaling with difficulty.

**Architecture:** All three hook into `HoochBalance` and/or `GameScene.update`. The score multiplier is a pure function of elapsed time; the spill-drain bonus adds transient state to `HoochBalance`; the wobble ramp wires the existing dead-stub `applyDifficulty` method into `update`. All tuning constants land in `GameConfig`. Each system gets a failing test before implementation.

**Tech Stack:** Dart / Flutter / Flame 1.37. `flutter_test` for unit tests. No new dependencies.

---

## File structure

| Path | Role | Action |
|------|------|--------|
| `lib/config/game_config.dart` | Tuning constants | Modify — add 5 new constants |
| `lib/components/hooch_balance.dart` | Tilt + spill state | Modify — wire `applyDifficulty`, add `grantSpillDrain`, track drain-bonus timer |
| `lib/scenes/game_scene.dart` | Top-level game | Modify — compute + render multiplier, call `balance.applyDifficulty`, handle potion bonus in `onPickup` |
| `lib/components/collectible.dart` | Pickup component | No change — `kind` is already in the pickup callback context via `pointsFor` (we'll extend callback signature) |
| `lib/systems/collectible_manager.dart` | Spawner | Modify — extend `onPickup` callback signature to pass `CollectibleKind` |
| `test/hooch_balance_test.dart` | Unit tests | Create — covers wobble ramp, spill drain bonus, existing behaviour |
| `test/game_config_test.dart` | Invariants | Create — split out of `widget_test.dart`, extend for new constants |
| `test/multiplier_test.dart` | Pure function tests | Create — multiplier curve |

## Decomposition notes

- **Score multiplier** is a pure function: `multiplier(elapsed) = min(maxMult, 1 + floor(elapsed / 10) * 0.1)`. Lives alongside other scoring math in `GameScene`. Testable in isolation.
- **Potion spill-drain bonus** adds transient state (`_drainBonusSeconds` remaining) to `HoochBalance`. When > 0, the drain rate is boosted; countdown per-frame in `update`.
- **Wobble amplitude ramp** means the existing passive wobble sine scales by a multiplier that grows over 180s, matching the scroll-speed curve. `HoochBalance.applyDifficulty(t)` stores the multiplier; `update` uses it in the wobble calc.
- Multiplier display: extend the existing `scoreText` to show `"${score}" if mult==1 else "${score}  ×${mult.toStringAsFixed(1)}"`. No new TextComponent; reuses existing HUD.
- The callback signature change (`onPickup(points, pos) → onPickup(kind, points, pos)`) is necessary because the potion bonus only fires for `CollectibleKind.potion`. Alternative: put the bonus trigger inside `Collectible.onCollisionStart` itself — cleaner. We'll go with the alternative.

---

### Task 1: Add tuning constants to GameConfig

**Files:**
- Modify: `lib/config/game_config.dart`
- Test: `test/game_config_test.dart`

- [ ] **Step 1: Write the failing test**

Create new file `test/game_config_test.dart` and port the existing `widget_test.dart` assertions plus new ones:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/config/game_config.dart';

void main() {
  group('GameConfig invariants', () {
    test('sane existing defaults', () {
      expect(GameConfig.baseScrollSpeed, greaterThan(0));
      expect(GameConfig.spillThreshold, lessThan(1.0));
      expect(GameConfig.spillDrainThreshold, lessThan(GameConfig.spillThreshold));
    });

    test('jump velocities are ordered (min is less-negative hop, max is full jump)', () {
      // Both are negative; min is a weaker upward velocity than max.
      expect(GameConfig.jumpVelocityMin, greaterThan(GameConfig.jumpVelocityMax));
      expect(GameConfig.jumpVelocityMax, lessThan(0));
    });

    test('score multiplier constants are sensible', () {
      expect(GameConfig.scoreMultiplierIntervalSeconds, greaterThan(0));
      expect(GameConfig.scoreMultiplierStep, greaterThan(0));
      expect(GameConfig.scoreMultiplierMax, greaterThan(1.0));
    });

    test('potion spill-drain bonus is a positive duration', () {
      expect(GameConfig.potionSpillDrainBonusSeconds, greaterThan(0));
      expect(GameConfig.potionSpillDrainBonusMultiplier, greaterThan(1.0));
    });

    test('wobble amplitude ramp caps at a sane multiplier', () {
      expect(GameConfig.wobbleAmplitudeMaxMultiplier, greaterThan(1.0));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game_config_test.dart`
Expected: FAIL with "The getter 'scoreMultiplierIntervalSeconds' isn't defined" (and similar for the other new constants).

- [ ] **Step 3: Write minimal implementation**

Append to `lib/config/game_config.dart` immediately before the final `}`:

```dart
  // Score multiplier: +0.1x per 10 survival seconds, capped 3x.
  // See docs/GAME_DESIGN.md § Scoring.
  static const double scoreMultiplierIntervalSeconds = 10.0;
  static const double scoreMultiplierStep = 0.1;
  static const double scoreMultiplierMax = 3.0;

  // Potion pickup grants N seconds of boosted spill-meter drain.
  static const double potionSpillDrainBonusSeconds = 1.0;
  static const double potionSpillDrainBonusMultiplier = 4.0;

  // Passive wobble amplitude scales with difficulty curve up to this cap
  // (evaluated at the end of difficultyRampSeconds — matches spec's 1.7x).
  static const double wobbleAmplitudeMaxMultiplier = 1.7;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/game_config_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Delete the old `test/widget_test.dart`** (the three assertions it covered are now in `game_config_test.dart`).

Run: `rm test/widget_test.dart && flutter test`
Expected: all tests (game_config_test + score_popup_test) pass.

- [ ] **Step 6: Commit**

```bash
git add test/game_config_test.dart lib/config/game_config.dart
git rm test/widget_test.dart
git commit -m "M4b task 1: GameConfig constants for multiplier / potion bonus / wobble ramp

Promoted widget_test.dart → game_config_test.dart, added coverage for
jump velocity ordering and the five new tuning constants."
```

---

### Task 2: Score multiplier (pure function + HUD wiring)

**Files:**
- Modify: `lib/scenes/game_scene.dart:33-37` (add multiplier getter), `update()` (use it), HUD render
- Test: `test/multiplier_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/multiplier_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/scenes/game_scene.dart';

void main() {
  group('GameScene.scoreMultiplier', () {
    test('starts at 1.0', () {
      expect(GameScene.multiplierFor(0), closeTo(1.0, 1e-9));
    });

    test('ticks to 1.1 at 10 seconds', () {
      expect(GameScene.multiplierFor(10), closeTo(1.1, 1e-9));
    });

    test('steps in 10s increments', () {
      expect(GameScene.multiplierFor(25), closeTo(1.2, 1e-9));
      expect(GameScene.multiplierFor(50), closeTo(1.5, 1e-9));
    });

    test('caps at the max', () {
      expect(GameScene.multiplierFor(999), closeTo(3.0, 1e-9));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/multiplier_test.dart`
Expected: FAIL — method not defined.

- [ ] **Step 3: Add the static helper to GameScene**

In `lib/scenes/game_scene.dart`, add immediately after `currentScrollSpeed`:

```dart
  /// Score multiplier as a pure function of survival time.
  /// Starts at 1.0, steps +0.1 every [GameConfig.scoreMultiplierIntervalSeconds],
  /// capped at [GameConfig.scoreMultiplierMax].
  static double multiplierFor(double elapsed) {
    final raw = 1.0 +
        (elapsed / GameConfig.scoreMultiplierIntervalSeconds).floor() *
            GameConfig.scoreMultiplierStep;
    return raw.clamp(1.0, GameConfig.scoreMultiplierMax);
  }

  double get currentMultiplier => multiplierFor(_elapsed);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/multiplier_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Apply multiplier to score + HUD**

In `lib/scenes/game_scene.dart` replace the body of the `update` method that computes score. Find the block:

```dart
    _elapsed += dt;
    score = (_elapsed * 10).floor() + _collectiblePoints;
    scoreText.text = '$score';
```

Replace with:

```dart
    _elapsed += dt;
    final mult = currentMultiplier;
    score = (_elapsed * 10 * mult).floor() + _collectiblePoints;
    scoreText.text = mult > 1.0
        ? '$score  ×${mult.toStringAsFixed(1)}'
        : '$score';
```

Collectible points are intentionally NOT multiplied — the multiplier rewards survival, not pickup volume. (Document in GAME_DESIGN.md in Task 5.)

- [ ] **Step 6: Run analyze + all tests**

Run: `flutter analyze && flutter test`
Expected: no issues, all tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/scenes/game_scene.dart test/multiplier_test.dart
git commit -m "M4b task 2: score multiplier

+0.1× per 10s survived, capped 3×. Multiplied onto time-based points
(not collectible points — rewards survival, not pickups). HUD shows
'\$score  ×1.3' when above 1×.

Tested via pure-function helper GameScene.multiplierFor."
```

---

### Task 3: Wobble amplitude difficulty ramp

**Files:**
- Modify: `lib/components/hooch_balance.dart`
- Modify: `lib/scenes/game_scene.dart` (call `balance.applyDifficulty` per frame)
- Test: `test/hooch_balance_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/hooch_balance_test.dart`:

```dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/hooch_balance.dart';
import 'package:hold_the_hooch/config/game_config.dart';

/// Sample the peak wobble swing over a full period by running update()
/// for long enough that the sine reaches its peak.
double _maxTiltOverOneSecond(HoochBalance b) {
  const dt = 1 / 60;
  const steps = 60;
  double peak = 0;
  for (var i = 0; i < steps; i++) {
    b.update(dt);
    if (b.tilt.abs() > peak) peak = b.tilt.abs();
  }
  return peak;
}

void main() {
  group('HoochBalance wobble amplitude ramp', () {
    test('at difficulty 0, wobble amplitude matches base', () {
      final b = HoochBalance();
      b.applyDifficulty(0);
      final peak0 = _maxTiltOverOneSecond(b);

      // Reset + run at the same difficulty; results consistent.
      b.tilt = 0;
      b.resetPhase();
      final peak0Again = _maxTiltOverOneSecond(b);
      expect((peak0 - peak0Again).abs(), lessThan(0.01));
    });

    test('at difficulty 1.0, wobble amplitude is larger than at 0', () {
      final b1 = HoochBalance()..applyDifficulty(0);
      final baseline = _maxTiltOverOneSecond(b1);

      final b2 = HoochBalance()..applyDifficulty(1.0);
      final ramped = _maxTiltOverOneSecond(b2);

      expect(ramped, greaterThan(baseline));
    });

    test('at difficulty 1.0, multiplier is within sane bounds', () {
      final b = HoochBalance()..applyDifficulty(1.0);
      // At max difficulty the wobble frequency and amplitude combine but
      // we expect the peak tilt from pure wobble to still be well below
      // the clamp (1.0).
      final peak = _maxTiltOverOneSecond(b);
      expect(peak, lessThan(0.5));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/hooch_balance_test.dart`
Expected: FAIL — the second test will fail because current `applyDifficulty` is a no-op (peak0 ≈ peak at difficulty 1.0).

- [ ] **Step 3: Wire `applyDifficulty` into the wobble calc**

In `lib/components/hooch_balance.dart`, replace the body of `applyDifficulty` and the `update` method's wobble line:

```dart
  double _difficulty = 0.0;

  /// Called each frame from GameScene with elapsed/rampSeconds in [0, 1].
  void applyDifficulty(double t) {
    _difficulty = t.clamp(0.0, 1.0);
  }

  double get _amplitudeMultiplier =>
      1.0 + _difficulty * (GameConfig.wobbleAmplitudeMaxMultiplier - 1.0);

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * GameConfig.wobbleBaseFrequency * 2 * pi;
    final wobble =
        sin(_phase) * GameConfig.wobbleBaseAmplitude * _amplitudeMultiplier * dt;
    tilt += wobble;
    tilt = tilt.clamp(-1.0, 1.0);
    // ... rest of spill/drain logic unchanged
```

Keep the existing `if (tilt.abs() > spillThreshold) ...` block below the edit.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/hooch_balance_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Call `applyDifficulty` from GameScene.update**

In `lib/scenes/game_scene.dart`, find the block inside `update`:

```dart
    _elapsed += dt;
    final mult = currentMultiplier;
    score = (_elapsed * 10 * mult).floor() + _collectiblePoints;
```

Insert between `_elapsed += dt;` and the `mult` line:

```dart
    balance.applyDifficulty(_elapsed / GameConfig.difficultyRampSeconds);
```

- [ ] **Step 6: Run analyze + full test suite**

Run: `flutter analyze && flutter test`
Expected: no issues, all tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/components/hooch_balance.dart lib/scenes/game_scene.dart test/hooch_balance_test.dart
git commit -m "M4b task 3: wobble amplitude difficulty ramp

HoochBalance.applyDifficulty was a dead stub; now wired from GameScene
every frame with elapsed/rampSeconds. Amplitude multiplier grows from
1.0 to wobbleAmplitudeMaxMultiplier (1.7x) over difficultyRampSeconds.
Matches the spec in docs/GAME_DESIGN.md § Difficulty curve."
```

---

### Task 4: Potion spill-drain bonus

**Files:**
- Modify: `lib/components/hooch_balance.dart`
- Modify: `lib/components/collectible.dart` (trigger on potion pickup)
- Test: `test/hooch_balance_test.dart` (extend)

- [ ] **Step 1: Write the failing test**

Append to `test/hooch_balance_test.dart` (inside new `group`):

```dart
  group('HoochBalance spill-drain bonus', () {
    test('bonus multiplies drain rate for the requested duration', () {
      final b = HoochBalance();
      // Seed: tilt below drain threshold so drain is active, spill at 1.0
      // so we can observe how fast it drops.
      b.tilt = 0.0;
      b.spill = 1.0;

      // Without bonus: drain rate is GameConfig.spillDrainRate per second.
      // Over 0.5s spill should drop by ~0.125.
      const halfSec = 0.5;
      const dt = 1 / 60;
      final baseline = HoochBalance()
        ..tilt = 0.0
        ..spill = 1.0;
      for (var i = 0; i < (halfSec / dt).round(); i++) {
        baseline.update(dt);
      }
      final baselineFinal = baseline.spill;

      b.grantSpillDrain(Duration(milliseconds: 500));
      for (var i = 0; i < (halfSec / dt).round(); i++) {
        b.update(dt);
      }

      // With bonus active, spill must drop noticeably faster than baseline.
      expect(b.spill, lessThan(baselineFinal));
    });

    test('bonus expires and drain returns to normal', () {
      final b = HoochBalance();
      b.tilt = 0.0;
      b.spill = 1.0;
      b.grantSpillDrain(Duration(milliseconds: 200));

      const dt = 1 / 60;
      // Advance past the bonus window.
      for (var i = 0; i < 30; i++) {
        b.update(dt);
      }
      final spillAfterBonusWindow = b.spill;

      // Now drain rate should be back to baseline.
      final baseline = HoochBalance()
        ..tilt = 0.0
        ..spill = spillAfterBonusWindow;

      const followUpSeconds = 0.3;
      for (var i = 0; i < (followUpSeconds / dt).round(); i++) {
        b.update(dt);
        baseline.update(dt);
      }

      expect((b.spill - baseline.spill).abs(), lessThan(0.01));
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/hooch_balance_test.dart`
Expected: FAIL — `grantSpillDrain` not defined.

- [ ] **Step 3: Implement `grantSpillDrain`**

In `lib/components/hooch_balance.dart`:

Add a field near `_difficulty`:

```dart
  double _drainBonusRemainingSec = 0.0;
```

Add a method below `applyDifficulty`:

```dart
  /// Boost the spill-meter drain rate for [duration]. Stacks by extension:
  /// if another bonus is already active, take the longer remaining time.
  void grantSpillDrain(Duration duration) {
    final sec = duration.inMilliseconds / 1000.0;
    if (sec > _drainBonusRemainingSec) _drainBonusRemainingSec = sec;
  }
```

Modify the drain branch inside `update`. Find:

```dart
    } else if (tilt.abs() < GameConfig.spillDrainThreshold) {
      spill -= GameConfig.spillDrainRate * dt;
    }
```

Replace with:

```dart
    } else if (tilt.abs() < GameConfig.spillDrainThreshold) {
      final drainMult = _drainBonusRemainingSec > 0
          ? GameConfig.potionSpillDrainBonusMultiplier
          : 1.0;
      spill -= GameConfig.spillDrainRate * drainMult * dt;
    }
    if (_drainBonusRemainingSec > 0) {
      _drainBonusRemainingSec = (_drainBonusRemainingSec - dt).clamp(0.0, double.infinity);
    }
```

Also extend `resetPhase` (rename semantics: it's called from `GameScene.restart()` and should clear the whole transient balance state) — but the restart flow already sets `tilt = 0`, `spill = 0`, `resetPhase()`. Append bonus clear to `resetPhase`:

```dart
  void resetPhase() {
    _phase = 0.0;
    _drainBonusRemainingSec = 0.0;
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/hooch_balance_test.dart`
Expected: PASS (5 tests — 3 wobble + 2 bonus).

- [ ] **Step 5: Trigger the bonus on potion pickup**

In `lib/components/collectible.dart`, find:

```dart
    if (_consumed || other is! Gurgles) return;
    _consumed = true;
    onPickup(pointsFor(kind), position.clone());
    removeFromParent();
```

Replace with:

```dart
    if (_consumed || other is! Gurgles) return;
    _consumed = true;
    onPickup(pointsFor(kind), position.clone());
    if (kind == CollectibleKind.potion) {
      _grantPotionBonus?.call();
    }
    removeFromParent();
```

Add a field + constructor param:

```dart
  final VoidCallback? _grantPotionBonus;

  Collectible({
    required this.kind,
    required Vector2 position,
    required this.scrollSpeed,
    required this.onPickup,
    VoidCallback? onPotionBonus,
    double sizeScale = 1.0,
  })  : _grantPotionBonus = onPotionBonus,
        super(
          position: position,
          size: _sizeFor(kind) * sizeScale,
          anchor: Anchor.bottomCenter,
        );
```

Add the import at the top of the file:

```dart
import 'package:flutter/foundation.dart' show VoidCallback;
```

- [ ] **Step 6: Plumb through CollectibleManager + GameScene**

In `lib/systems/collectible_manager.dart`, add:

```dart
  final VoidCallback? onPotionBonus;
```

To the constructor params + store it. Pass into `Collectible(...)` during spawn: `onPotionBonus: onPotionBonus`.

In `lib/scenes/game_scene.dart`, where `CollectibleManager` is created, add:

```dart
      onPotionBonus: () =>
          balance.grantSpillDrain(const Duration(milliseconds: 1000)),
```

- [ ] **Step 7: Run analyze + full test suite**

Run: `flutter analyze && flutter test`
Expected: no issues, all tests pass.

- [ ] **Step 8: Commit**

```bash
git add lib/components/hooch_balance.dart lib/components/collectible.dart lib/systems/collectible_manager.dart lib/scenes/game_scene.dart test/hooch_balance_test.dart
git commit -m "M4b task 4: potion spill-drain bonus

Potion pickup grants 1 second of 4x drain-rate bonus. Implemented as
transient state on HoochBalance (\_drainBonusRemainingSec) ticking down
each frame. Triggered from Collectible.onCollisionStart when kind is
potion, plumbed through CollectibleManager as onPotionBonus callback.

Bonus-expiration verified via unit test — after window closes, drain
rate matches a fresh baseline HoochBalance."
```

---

### Task 5: Documentation

**Files:**
- Modify: `docs/GAME_DESIGN.md` (two small edits)
- Modify: `docs/STATUS.md` (clear items #3 #4 #5)
- Modify: `docs/ROADMAP.md` (check off M4b)

- [ ] **Step 1: Update GAME_DESIGN.md**

Find the line about Potion:

```markdown
- **Potion bottle** — 200 pts, high tier, rare. Grants 1 second of spill-drain bonus.
```

Append to it:

```markdown
 (4× drain rate during the bonus window).
```

Find the Scoring section:

```markdown
- Multiplier: +0.1x per 10 seconds survived, capped at 3x.
- Final score submitted to leaderboard on death.
```

Insert a note between the two lines:

```markdown
- Multiplier applies to time-based points only, not collectibles. Rationale: multiplier rewards survival; collectibles already have risk/reward built in.
```

- [ ] **Step 2: Update STATUS.md**

Delete rows #3, #4, #5 from the Known Issues table. Renumber the subsequent rows (or leave numbers as-is; row numbering isn't load-bearing).

- [ ] **Step 3: Update ROADMAP.md**

In the M4b block, check off:

```markdown
- [x] **Score multiplier** (STATUS #3).
- [x] **Potion spill-drain bonus** (STATUS #4).
- [x] **Wobble amplitude difficulty ramp** (STATUS #5).
```

- [ ] **Step 4: Commit**

```bash
git add docs/GAME_DESIGN.md docs/STATUS.md docs/ROADMAP.md
git commit -m "docs: close out M4b items in STATUS + ROADMAP + GAME_DESIGN"
```

---

### Task 6: On-device verification

- [ ] **Step 1: Build and install**

```bash
flutter build apk --debug
flutter install -d 192.168.4.25:38097 --debug
```

- [ ] **Step 2: Verify on device**

Play a run and observe:
- Score HUD shows "×1.1" after ~10 seconds of survival, "×1.2" at ~20s, etc.
- Score accrual feels ~1.0× at the start and visibly faster at 30+ seconds.
- Grab a potion — spill meter (if any) visibly drains faster for ~1 second after.
- Hoochwobble feels more aggressive after ~2 minutes of survival than at the start.

If any of these fails verification, treat as a regression — return to `systematic-debugging` before marking done.

- [ ] **Step 3: Final commit for the milestone**

```bash
git commit --allow-empty -m "M4b verified on device (Samsung S26 Ultra)"
```

---

## Self-review checklist

- **Spec coverage:**
  - Score multiplier → Task 2 ✓
  - Potion spill-drain bonus → Task 4 ✓
  - Wobble amplitude difficulty ramp → Task 3 ✓
  - Config constants → Task 1 ✓
  - Docs sync → Task 5 ✓
  - Device verification → Task 6 ✓
- **Placeholder scan:** none found. Every step has exact code/commands.
- **Type consistency:** `applyDifficulty(double)`, `grantSpillDrain(Duration)`, `multiplierFor(double)` names used consistently across tasks. `CollectibleKind.potion` enum import path matches.
- **Dependencies between tasks:** Task 2 depends on Task 1's constants; Tasks 3/4 depend on Task 1's constants. Task 4 uses the new `resetPhase` behaviour added mid-task. Task 5 depends on all implementation tasks being merged first. Task 6 is verification and runs last.
