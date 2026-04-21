# Gnome Animation Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current binary SVG run/jump sprite with a real per-frame sprite animation pipeline using the purchased `no_hat_gnome` frames — giving Gurgles run/jump/hurt/dead animations in-game and an idle animation on the menu screen.

**Architecture:**
- **Asset pipeline** — a reproducible Dart build script (`tools/build_gurgles_sprites.dart`) reads raw frames from `art-source/gnomes/PNG_sequences/no_hat_gnome/` (gitignored), computes a **union bounding box** across all shipping frames (so every frame shares a consistent canvas → no drift between frames), crops + resizes to 256 px tall, writes to `assets/images/gurgles/<anim>/<NNN>.png`.
- **State machine** — a pure `GurglesAnimator` class owns the current animation state (`idle | run | jumpStart | jumpCycle | jumpLand | hurt | dead`). Transitions driven by physics (`onGround`, `velocityY`) + explicit triggers (`triggerHurt()`). Unit-testable without Flame.
- **Rendering** — `Gurgles` swaps its two `SvgComponent`s for one `SpriteAnimationComponent` whose `.animation` is rewritten whenever the animator's state changes. Tankard overlay and tilt rotation are untouched — they already live as separate children.
- **Menu** — a `FutureBuilder<SpriteAnimation>` + Flame's `SpriteAnimationWidget` shows the idle cycle next to the name-entry field.

**Tech Stack:** Flutter 3.41.4 · Dart 3.11.1 · Flame 1.37 · pure-Dart `image` package (added as dev dep — no system ImageMagick needed, keeps the pipeline portable on Windows + CI).

---

## File Structure

### New files
- `tools/build_gurgles_sprites.dart` — one-shot asset curation script (invoked via `dart run tools/build_gurgles_sprites.dart`).
- `lib/components/gurgles_animator.dart` — pure state-machine class + `GurglesAnimation` enum.
- `lib/components/gurgles_idle_widget.dart` — Flutter widget embedding the idle SpriteAnimation for the menu screen.
- `test/gurgles_animator_test.dart` — unit tests for every state transition.
- `assets/images/gurgles/idle/000.png…019.png` (20 frames, generated)
- `assets/images/gurgles/run/000.png…007.png` (8)
- `assets/images/gurgles/jump_start/000.png…006.png` (7)
- `assets/images/gurgles/jump_cycle/000.png…011.png` (12)
- `assets/images/gurgles/jump_land/000.png…005.png` (6)
- `assets/images/gurgles/hurt/000.png…005.png` (6)
- `assets/images/gurgles/dead/000.png` (1)

### Modified files
- `lib/components/gurgles.dart` — replace `_runSvg`/`_jumpSvg` with a single `SpriteAnimationComponent` driven by `GurglesAnimator`. Keep tankard overlay + tilt rotation unchanged.
- `lib/scenes/menu_screen.dart` — add `GurglesIdleWidget` between the "Best: N" line and the name TextField.
- `lib/scenes/game_scene.dart` — unified `_end()` path triggers `gurgles.triggerHurt()`, then delays overlay for `GameConfig.gameOverHurtDelayMs`.
- `lib/config/game_config.dart` — add `gameOverHurtDelayMs = 600` constant + three animation-duration constants.
- `pubspec.yaml` — register `assets/images/gurgles/` subpaths; add `image: ^4.3.0` to dev_dependencies.
- `docs/STATUS.md` — flip "run-cycle animation" and "hurt pose" out of Known Issues; note the new asset pipeline.
- `docs/ROADMAP.md` — tick the M5a "6-frame run cycle" and "Hurt pose" items.
- `docs/ART-GUIDE.md` — add a note at the top that Gurgles now uses derivative frames of `no_hat_gnome` from the Game Developer Studio gnome pack.

### Untouched (but read during implementation)
- `lib/components/splash_emitter.dart` — still receives Gurgles via its constructor; tankard-rim math is unchanged.
- `test/tankard_rotation_test.dart` — unchanged; tests `tankardAngleForTilt` pure fn.
- `test/game_scene_restart_test.dart` — will need a `triggerHurt`-safe stub; see Task 7.

---

## Task 1: Add `image` dev dependency and scaffold the asset curation script

**Files:**
- Modify: `pubspec.yaml:43-46`
- Create: `tools/build_gurgles_sprites.dart`

- [ ] **Step 1: Add `image` to dev dependencies**

Edit `pubspec.yaml:43-46`, change the `dev_dependencies` block to:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  image: ^4.3.0

  # The "flutter_lints" package below contains a set of recommended lints to
```

- [ ] **Step 2: Fetch packages**

Run: `flutter pub get`
Expected: success, `image 4.x.x` resolved.

- [ ] **Step 3: Scaffold the curation script**

Create `tools/build_gurgles_sprites.dart`:

```dart
/// One-shot asset curation script.
///
/// Reads raw gnome frames from `art-source/gnomes/PNG_sequences/no_hat_gnome/`
/// (gitignored), computes the union content bounding box across all shipping
/// frames, crops each frame to that box, resizes to 256 px tall, and writes
/// them to `assets/images/gurgles/<anim>/<NNN>.png`.
///
/// Run from the repo root: `dart run tools/build_gurgles_sprites.dart`
///
/// Not intended to run in CI — raw pack is not checked in. Regenerate locally
/// whenever the source frames change.

import 'dart:io';
import 'package:image/image.dart' as img;

const String srcDir = 'art-source/gnomes/PNG_sequences/no_hat_gnome';
const String dstDir = 'assets/images/gurgles';
const int outputHeight = 256;

// Animations we ship in V1. Order is irrelevant here; sorted glob picks frames.
const Map<String, int> animations = {
  'idle': 20,
  'run': 8,
  'jump_start': 7,
  'jump_cycle': 12,
  'jump_land': 6,
  'hurt': 6,
  'dead': 1,
};

Future<void> main() async {
  stderr.writeln('TODO: implement in Task 2');
  exit(1);
}
```

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock tools/build_gurgles_sprites.dart
git commit -m "feat: add image dev dep + scaffold gurgles sprite curation script"
```

---

## Task 2: Implement asset curation (union bbox + crop + resize)

**Files:**
- Modify: `tools/build_gurgles_sprites.dart`

- [ ] **Step 1: Replace the `main()` body with full implementation**

Replace the `main()` body in `tools/build_gurgles_sprites.dart` with:

```dart
Future<void> main() async {
  final source = Directory(srcDir);
  if (!source.existsSync()) {
    stderr.writeln('ERROR: $srcDir not found. Extract gnomes.zip first.');
    exit(1);
  }

  // Collect all frames we'll ship, in per-animation order.
  final allFramePaths = <String>[];
  final framesByAnim = <String, List<String>>{};
  for (final anim in animations.keys) {
    final frames = source
        .listSync()
        .whereType<File>()
        .map((f) => f.path)
        .where((p) => p.contains('__no_hat_gnome_${anim}_') && p.endsWith('.png'))
        .toList()
      ..sort();
    if (frames.length != animations[anim]) {
      stderr.writeln(
          'ERROR: expected ${animations[anim]} frames for $anim, found ${frames.length}');
      exit(1);
    }
    framesByAnim[anim] = frames;
    allFramePaths.addAll(frames);
  }

  // Pass 1: compute union content bbox across every shipping frame.
  int minX = 1 << 30, minY = 1 << 30, maxX = -1, maxY = -1;
  for (final path in allFramePaths) {
    final image = img.decodePng(File(path).readAsBytesSync())!;
    final bbox = _contentBounds(image);
    if (bbox == null) continue; // fully-transparent frame (shouldn't happen)
    if (bbox.minX < minX) minX = bbox.minX;
    if (bbox.minY < minY) minY = bbox.minY;
    if (bbox.maxX > maxX) maxX = bbox.maxX;
    if (bbox.maxY > maxY) maxY = bbox.maxY;
  }
  // Pad 4 px so anti-aliased edges don't kiss the canvas edge.
  minX = (minX - 4).clamp(0, 1 << 30);
  minY = (minY - 4).clamp(0, 1 << 30);
  maxX = (maxX + 4);
  maxY = (maxY + 4);
  final cropW = maxX - minX + 1;
  final cropH = maxY - minY + 1;
  stdout.writeln('Union bbox: ${cropW}x${cropH} at ($minX, $minY)');

  // Pass 2: crop every frame to that box, resize, write to assets.
  int total = 0;
  for (final anim in animations.keys) {
    final outSubdir = Directory('$dstDir/$anim');
    if (outSubdir.existsSync()) outSubdir.deleteSync(recursive: true);
    outSubdir.createSync(recursive: true);
    int i = 0;
    for (final srcPath in framesByAnim[anim]!) {
      final image = img.decodePng(File(srcPath).readAsBytesSync())!;
      final cropped = img.copyCrop(image,
          x: minX, y: minY, width: cropW, height: cropH);
      final resized = img.copyResize(cropped, height: outputHeight);
      final outPath = '$dstDir/$anim/${i.toString().padLeft(3, '0')}.png';
      File(outPath).writeAsBytesSync(img.encodePng(resized));
      i++;
      total++;
    }
    stdout.writeln('  $anim: $i frames -> $dstDir/$anim/');
  }
  stdout.writeln('Done: $total frames written.');
}

class _Bounds {
  final int minX, minY, maxX, maxY;
  _Bounds(this.minX, this.minY, this.maxX, this.maxY);
}

/// Returns the inclusive bounding box of non-transparent pixels, or null if
/// the whole image is transparent.
_Bounds? _contentBounds(img.Image image) {
  int? minX, minY, maxX, maxY;
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final a = image.getPixel(x, y).a;
      if (a == 0) continue;
      minX = (minX == null || x < minX) ? x : minX;
      minY = (minY == null || y < minY) ? y : minY;
      maxX = (maxX == null || x > maxX) ? x : maxX;
      maxY = (maxY == null || y > maxY) ? y : maxY;
    }
  }
  if (minX == null) return null;
  return _Bounds(minX, minY!, maxX!, maxY!);
}
```

- [ ] **Step 2: Run it**

Run: `dart run tools/build_gurgles_sprites.dart`
Expected output (roughly):
```
Union bbox: <W>x<H> at (<x>, <y>)
  idle: 20 frames -> assets/images/gurgles/idle/
  run: 8 frames -> assets/images/gurgles/run/
  jump_start: 7 frames -> assets/images/gurgles/jump_start/
  jump_cycle: 12 frames -> assets/images/gurgles/jump_cycle/
  jump_land: 6 frames -> assets/images/gurgles/jump_land/
  hurt: 6 frames -> assets/images/gurgles/hurt/
  dead: 1 frames -> assets/images/gurgles/dead/
Done: 60 frames written.
```

- [ ] **Step 3: Verify output by opening one frame**

Run: `ls assets/images/gurgles/run/`
Expected: `000.png 001.png 002.png 003.png 004.png 005.png 006.png 007.png`

Open `assets/images/gurgles/run/000.png` in a viewer. Should be ~256 px tall, show the red-haired gnome running, minimal transparent padding.

- [ ] **Step 4: Commit script + generated frames**

```bash
git add tools/build_gurgles_sprites.dart assets/images/gurgles/
git commit -m "feat: generate curated gurgles sprite frames from gnome pack"
```

---

## Task 3: Register new asset paths in pubspec.yaml

**Files:**
- Modify: `pubspec.yaml:65-68`

- [ ] **Step 1: Expand the `assets:` block**

Flutter's asset resolver is non-recursive for trailing-slash entries — each subdirectory must be listed individually. Replace lines 65–68:

```yaml
  assets:
    - assets/svg/
    - assets/images/
    - assets/images/gurgles/idle/
    - assets/images/gurgles/run/
    - assets/images/gurgles/jump_start/
    - assets/images/gurgles/jump_cycle/
    - assets/images/gurgles/jump_land/
    - assets/images/gurgles/hurt/
    - assets/images/gurgles/dead/
    - assets/audio/
```

- [ ] **Step 2: Verify pub gets it**

Run: `flutter pub get && flutter analyze`
Expected: no errors. Asset paths parsed cleanly.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml
git commit -m "chore: register gurgles sprite asset paths in pubspec"
```

---

## Task 4: `GurglesAnimator` state machine — TDD

**Files:**
- Create: `test/gurgles_animator_test.dart`
- Create: `lib/components/gurgles_animator.dart`
- Modify: `lib/config/game_config.dart`

- [ ] **Step 1: Add animation duration constants to GameConfig**

Append to `lib/config/game_config.dart` before the final `}`:

```dart

  // Gnome-pack animation durations. Each source clip plays at ~20fps.
  // These are totals from first frame to last. Tune on-device if needed.
  static const double jumpStartDurationSeconds = 0.35;   // 7 frames
  static const double jumpLandDurationSeconds = 0.30;    // 6 frames
  static const double hurtDurationSeconds = 0.30;        // 6 frames

  // Delay between game-over trigger and the overlay appearing. Covers the
  // hurt animation + splash-emitter flourish. Value was splashGameOverDelayMs
  // before Gurgles had a hurt animation; now applies to both spill and
  // obstacle endings.
  static const int gameOverHurtDelayMs = 600;
```

- [ ] **Step 2: Write failing tests**

Create `test/gurgles_animator_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/gurgles_animator.dart';
import 'package:hold_the_hooch/config/game_config.dart';

void main() {
  group('GurglesAnimator', () {
    test('starts in run state', () {
      final a = GurglesAnimator();
      expect(a.state, GurglesAnimation.run);
    });

    test('run -> jumpStart when leaving ground', () {
      final a = GurglesAnimator();
      a.update(0.016, onGround: false, velocityY: -500);
      expect(a.state, GurglesAnimation.jumpStart);
    });

    test('jumpStart -> jumpCycle after jumpStartDuration elapses', () {
      final a = GurglesAnimator();
      a.update(0.016, onGround: false, velocityY: -500);
      // Tick past the transition boundary.
      a.update(GameConfig.jumpStartDurationSeconds + 0.01,
          onGround: false, velocityY: 0);
      expect(a.state, GurglesAnimation.jumpCycle);
    });

    test('jumpCycle -> jumpLand when ground re-acquired', () {
      final a = GurglesAnimator();
      a.update(0.016, onGround: false, velocityY: -500);
      a.update(GameConfig.jumpStartDurationSeconds + 0.01,
          onGround: false, velocityY: 0);
      // Now land.
      a.update(0.016, onGround: true, velocityY: 0);
      expect(a.state, GurglesAnimation.jumpLand);
    });

    test('jumpLand -> run after jumpLandDuration elapses', () {
      final a = GurglesAnimator();
      a.update(0.016, onGround: false, velocityY: -500);
      a.update(GameConfig.jumpStartDurationSeconds + 0.01,
          onGround: false, velocityY: 0);
      a.update(0.016, onGround: true, velocityY: 0);
      a.update(GameConfig.jumpLandDurationSeconds + 0.01,
          onGround: true, velocityY: 0);
      expect(a.state, GurglesAnimation.run);
    });

    test('triggerHurt -> hurt from any non-terminal state', () {
      final a = GurglesAnimator();
      a.triggerHurt();
      expect(a.state, GurglesAnimation.hurt);
    });

    test('hurt -> dead after hurtDuration elapses', () {
      final a = GurglesAnimator();
      a.triggerHurt();
      a.update(GameConfig.hurtDurationSeconds + 0.01,
          onGround: true, velocityY: 0);
      expect(a.state, GurglesAnimation.dead);
    });

    test('dead is terminal — update is a no-op', () {
      final a = GurglesAnimator();
      a.triggerHurt();
      a.update(GameConfig.hurtDurationSeconds + 0.01,
          onGround: true, velocityY: 0);
      expect(a.state, GurglesAnimation.dead);
      // Even with onGround=false and velocityY<0, should stay dead.
      a.update(0.5, onGround: false, velocityY: -500);
      expect(a.state, GurglesAnimation.dead);
    });

    test('triggerHurt after dead is a no-op', () {
      final a = GurglesAnimator();
      a.triggerHurt();
      a.update(GameConfig.hurtDurationSeconds + 0.01,
          onGround: true, velocityY: 0);
      a.triggerHurt();
      expect(a.state, GurglesAnimation.dead);
    });

    test('reset returns to run', () {
      final a = GurglesAnimator();
      a.triggerHurt();
      a.reset();
      expect(a.state, GurglesAnimation.run);
    });

    test('setIdle puts animator in idle (menu use)', () {
      final a = GurglesAnimator();
      a.setIdle();
      expect(a.state, GurglesAnimation.idle);
    });

    test('idle -> jumpStart if onGround becomes false (defensive)', () {
      final a = GurglesAnimator();
      a.setIdle();
      a.update(0.016, onGround: false, velocityY: -500);
      expect(a.state, GurglesAnimation.jumpStart);
    });
  });
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/gurgles_animator_test.dart`
Expected: FAIL — `gurgles_animator.dart` doesn't exist yet.

- [ ] **Step 4: Implement GurglesAnimator**

Create `lib/components/gurgles_animator.dart`:

```dart
import '../config/game_config.dart';

enum GurglesAnimation {
  idle,
  run,
  jumpStart,
  jumpCycle,
  jumpLand,
  hurt,
  dead,
}

/// Pure state machine for Gurgles' visible animation.
///
/// Takes physics inputs (`onGround`, `velocityY`) + explicit triggers
/// (`triggerHurt`, `setIdle`, `reset`). Emits the current [state] which the
/// renderer swaps into a [SpriteAnimationComponent.animation].
///
/// No Flame, no async, no mutable external state — unit-testable.
class GurglesAnimator {
  GurglesAnimation _state = GurglesAnimation.run;
  double _stateElapsed = 0;

  GurglesAnimation get state => _state;

  void update(double dt, {required bool onGround, required double velocityY}) {
    _stateElapsed += dt;
    switch (_state) {
      case GurglesAnimation.dead:
        return;
      case GurglesAnimation.hurt:
        if (_stateElapsed >= GameConfig.hurtDurationSeconds) {
          _transition(GurglesAnimation.dead);
        }
        return;
      case GurglesAnimation.idle:
      case GurglesAnimation.run:
        if (!onGround) _transition(GurglesAnimation.jumpStart);
        return;
      case GurglesAnimation.jumpStart:
        if (_stateElapsed >= GameConfig.jumpStartDurationSeconds) {
          _transition(GurglesAnimation.jumpCycle);
        }
        return;
      case GurglesAnimation.jumpCycle:
        if (onGround) _transition(GurglesAnimation.jumpLand);
        return;
      case GurglesAnimation.jumpLand:
        if (_stateElapsed >= GameConfig.jumpLandDurationSeconds) {
          _transition(GurglesAnimation.run);
        }
        return;
    }
  }

  void triggerHurt() {
    if (_state == GurglesAnimation.hurt || _state == GurglesAnimation.dead) {
      return;
    }
    _transition(GurglesAnimation.hurt);
  }

  void setIdle() => _transition(GurglesAnimation.idle);

  void reset() => _transition(GurglesAnimation.run);

  void _transition(GurglesAnimation next) {
    _state = next;
    _stateElapsed = 0;
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/gurgles_animator_test.dart`
Expected: PASS — 11 tests green.

- [ ] **Step 6: Full analyze + test sweep**

Run: `flutter analyze && flutter test`
Expected: no analyzer warnings; previous test count (76) + 11 new = **87 tests passing**.

- [ ] **Step 7: Commit**

```bash
git add lib/components/gurgles_animator.dart test/gurgles_animator_test.dart lib/config/game_config.dart
git commit -m "feat: GurglesAnimator state machine (idle/run/jump*/hurt/dead)"
```

---

## Task 5: Refactor Gurgles to use SpriteAnimationComponent

**Files:**
- Modify: `lib/components/gurgles.dart` (full rewrite of SVG-related bits)

- [ ] **Step 1: Full rewrite of `lib/components/gurgles.dart`**

Replace the entire file contents:

```dart
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import '../config/game_config.dart';
import 'gurgles_animator.dart';
import 'obstacle.dart';

/// Gurgles the runner + the tankard of hooch riding above his head.
///
/// Body renders from a [SpriteAnimationComponent] driven by [GurglesAnimator].
/// The tankard is a separate [SvgComponent] child that rotates with
/// `balance.tilt` (unchanged from the pre-animation implementation).
class Gurgles extends PositionComponent with CollisionCallbacks {
  double velocityY = 0;
  // 2px tolerance: floating-point arithmetic + size-change cascades leave
  // Gurgles hovering sub-pixel amounts above groundY. A strict `y >= groundY`
  // locks him out of jumping forever.
  bool get onGround => y >= _groundY - 2;
  final double _groundY;
  bool _jumpHeld = false;
  double _jumpHeldMs = 0;

  final GurglesAnimator animator = GurglesAnimator();

  // Populated in onLoad. Test stubs may skip onLoad, in which case
  // [_spritesLoaded] stays false and [_refreshAnimation] no-ops.
  late Map<GurglesAnimation, SpriteAnimation> _animations;
  SpriteAnimationComponent? _body;
  bool _spritesLoaded = false;

  // Nullable because Gurgles.onLoad (which loads the SVG) may not have
  // finished by the time GameScene.update calls setTankardAngle. Rather
  // than await-ing add(gurgles) in the scene, we treat pre-load calls as
  // no-ops.
  SvgComponent? _tankard;

  void Function()? onObstacleHit;

  Gurgles({
    required Vector2 position,
    required double groundY,
    Vector2? size,
  })  : _groundY = groundY,
        super(
          position: position,
          size: size ?? Vector2(96, 120),
          anchor: Anchor.bottomCenter,
        ) {
    y = groundY;
  }

  @override
  Future<void> onLoad() async {
    _animations = {
      GurglesAnimation.idle: await _loadSequence('idle', 20, 0.08),
      GurglesAnimation.run: await _loadSequence('run', 8, 0.06),
      GurglesAnimation.jumpStart: await _loadSequence(
          'jump_start', 7, GameConfig.jumpStartDurationSeconds / 7,
          loop: false),
      GurglesAnimation.jumpCycle: await _loadSequence('jump_cycle', 12, 0.06),
      GurglesAnimation.jumpLand: await _loadSequence(
          'jump_land', 6, GameConfig.jumpLandDurationSeconds / 6,
          loop: false),
      GurglesAnimation.hurt: await _loadSequence(
          'hurt', 6, GameConfig.hurtDurationSeconds / 6,
          loop: false),
      GurglesAnimation.dead: await _loadSequence('dead', 1, 1.0, loop: false),
    };
    _body = SpriteAnimationComponent(
      animation: _animations[GurglesAnimation.run]!,
      size: size,
    );
    add(_body!);

    final hoochSvg = await Svg.load('svg/hooch.svg');
    final tankardSize = Vector2(size.x * 0.7, size.x * 0.55);
    final tankard = SvgComponent(
      svg: hoochSvg,
      size: tankardSize,
      position: Vector2(size.x / 2, -2),
      anchor: Anchor.bottomCenter,
    );
    _tankard = tankard;
    add(tankard);

    // Tight body hitbox tuned empirically against the no_hat_gnome frames.
    // Excludes the raised hat/hair, outstretched staff, and tankard so
    // grazes feel fair. Refined on-device in Task 9.
    add(RectangleHitbox(
      size: Vector2(size.x * 0.40, size.y * 0.58),
      position: Vector2(size.x * 0.30, size.y * 0.32),
    ));
    _spritesLoaded = true;
  }

  Future<SpriteAnimation> _loadSequence(
    String folder,
    int frameCount,
    double stepTime, {
    bool loop = true,
  }) async {
    final sprites = <Sprite>[];
    for (int i = 0; i < frameCount; i++) {
      final name = i.toString().padLeft(3, '0');
      sprites.add(await Sprite.load('gurgles/$folder/$name.png'));
    }
    return SpriteAnimation.spriteList(sprites, stepTime: stepTime, loop: loop);
  }

  void startJump() {
    if (!onGround) return;
    velocityY = GameConfig.jumpVelocityMin;
    _jumpHeld = true;
    _jumpHeldMs = 0;
  }

  void endJump() => _jumpHeld = false;

  /// Called from GameScene when Gurgles should play the hurt-then-dead
  /// sequence. Idempotent — repeated calls after the first are ignored.
  void triggerHurt() => animator.triggerHurt();

  /// Pure function: how far the tankard should lean for a given balance tilt.
  /// Tested in test/tankard_rotation_test.dart.
  static double tankardAngleForTilt(double tilt) =>
      tilt * GameConfig.tankardMaxLeanRadians;

  /// Pure function: offset from tankard center to the point on the rim
  /// pointing in the tilt direction. When [tilt] is 0, that's straight up
  /// at `(0, -tankardRadius)`; the vector rotates by
  /// `tilt * GameConfig.tankardMaxLeanRadians` so the emission point
  /// tracks the lean. Tested in test/tankard_rotation_test.dart.
  @visibleForTesting
  static Vector2 rimOffsetFromTankardCenter(double tilt, double tankardRadius) =>
      Vector2(0, -tankardRadius)..rotate(tilt * GameConfig.tankardMaxLeanRadians);

  /// Called from GameScene.update each frame to visually tilt the tankard in
  /// sync with balance.tilt. Gives the player a clear cue about which way to
  /// counter-drag to avoid spilling.
  void setTankardAngle(double angle) {
    _tankard?.angle = angle;
  }

  /// World-space position of the tankard rim on the tilt side.
  /// Used by [SplashEmitter] to spawn droplets where the hooch would
  /// physically spill out. Returns Gurgles' own position if the tankard
  /// hasn't loaded yet (pre-onLoad), matching the existing null-safe
  /// pattern for _tankard.
  Vector2 tankardRimWorldPosition(double tilt) {
    final t = _tankard;
    if (t == null) return position.clone();
    return t.absoluteCenter + rimOffsetFromTankardCenter(tilt, t.size.y / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_jumpHeld) {
      _jumpHeldMs += dt * 1000;
      final t = (_jumpHeldMs / GameConfig.jumpHoldMaxMs).clamp(0.0, 1.0);
      velocityY = GameConfig.jumpVelocityMin +
          (GameConfig.jumpVelocityMax - GameConfig.jumpVelocityMin) * t;
      if (_jumpHeldMs >= GameConfig.jumpHoldMaxMs) _jumpHeld = false;
    }
    velocityY += GameConfig.gravity * dt;
    y += velocityY * dt;
    if (y >= _groundY) {
      y = _groundY;
      velocityY = 0;
      _jumpHeld = false;
    }
    animator.update(dt, onGround: onGround, velocityY: velocityY);
    _refreshAnimation();
  }

  void _refreshAnimation() {
    if (!_spritesLoaded) return;
    final target = _animations[animator.state]!;
    if (_body!.animation != target) {
      _body!.animation = target;
    }
  }

  /// Reset animator state on restart. Physics fields (velocityY, position)
  /// are reset by GameScene.restart itself.
  void resetAnimator() => animator.reset();

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    // Only obstacles end the run — collectibles handle their own pickup.
    if (other is Obstacle) {
      onObstacleHit?.call();
    }
  }
}
```

- [ ] **Step 2: Run analyze**

Run: `flutter analyze`
Expected: no errors. A few `unused_field` warnings if the old `_runSvg`/`_jumpSvg` are referenced anywhere else — grep and clean up.

- [ ] **Step 3: Run the existing test suite**

Run: `flutter test`
Expected: **76 existing + 11 new animator tests = 87 passing.** `test/gurgles_physics_test.dart` may fail if it depends on `_runSvg`/`_jumpSvg`/`_swapSprite` — those are gone. Re-open it and, if so:

- Remove any stubbed `_swapSprite` overrides.
- Keep the peak-jump analytic tests.

If `test/game_scene_restart_test.dart` exercises game-over logic, it may now need a `.triggerHurt()` stub — see Task 7.

- [ ] **Step 4: Commit**

```bash
git add lib/components/gurgles.dart
git commit -m "refactor(gurgles): drive body sprite via GurglesAnimator + SpriteAnimationComponent"
```

---

## Task 6: Wire game-over to play hurt-then-dead (GameScene)

**Files:**
- Modify: `lib/scenes/game_scene.dart:240-264` (the `_end` method)
- Modify: `test/game_scene_restart_test.dart` (if it constructs a Gurgles stub — update signature)

- [ ] **Step 1: Unify the `_end` method so both paths run the hurt animation**

Replace the `_end` method at `lib/scenes/game_scene.dart:240-264` with:

```dart
  void _end(String reason, {bool fromSpill = false}) {
    if (_gameOver) return;
    _gameOver = true;
    endReason = reason;

    gurgles.triggerHurt();
    if (fromSpill) splashEmitter.emitGameOverBurst();

    // Wait for the hurt animation + (if spilling) the splash flourish before
    // showing the overlay. The engine keeps running during the delay so both
    // play; _gameOver (set above) blocks further update() logic, and the
    // overlay hasn't been added yet, so the player can't retry mid-delay.
    Future.delayed(
      Duration(milliseconds: GameConfig.gameOverHurtDelayMs),
      () {
        if (!isAttached) return;
        pauseEngine();
        overlays.add(gameOverOverlayId);
      },
    );
  }
```

- [ ] **Step 2: Reset animator inside restart()**

Add one line to `lib/scenes/game_scene.dart` inside the `restart()` method (right after `balance.setDriftDirection(...)`, immediately before `resumeEngine()`):

```dart
    gurgles.resetAnimator();
```

- [ ] **Step 3: Update restart test if its stub overrides Gurgles**

Open `test/game_scene_restart_test.dart` and check whether it constructs a real Gurgles or a `_StubGurgles`. If the latter:
- Override `triggerHurt()` as a no-op.
- Override `resetAnimator()` as a no-op.

Example snippet (only apply if the existing stub exists):

```dart
class _StubGurgles extends Gurgles {
  _StubGurgles({required super.position, required super.groundY, super.size});
  @override
  Future<void> onLoad() async {}
  @override
  void triggerHurt() {}
  @override
  void resetAnimator() {}
}
```

- [ ] **Step 4: Run full test + analyze**

Run: `flutter analyze && flutter test`
Expected: 87 passing, clean analyzer.

- [ ] **Step 5: Commit**

```bash
git add lib/scenes/game_scene.dart test/game_scene_restart_test.dart
git commit -m "feat(game-scene): play hurt-then-dead on every game-over path"
```

---

## Task 7: Delete obsolete SVG fields & remove stale references

**Files:**
- Scan repo for `_runSvg`, `_jumpSvg`, `_swapSprite` — remove any residual callers.
- `assets/svg/gurgles.svg`, `gurgles-jump.svg` — keep on disk (harmless, in case future menu wants them), but they're no longer loaded by code.

- [ ] **Step 1: Grep for removed identifiers**

Run: `grep -rn "_runSvg\|_jumpSvg\|_swapSprite" lib/ test/`
Expected: no matches. If any remain, clean them up.

- [ ] **Step 2: Confirm pubspec asset entry for `assets/svg/` still loads untouched**

Run: `flutter analyze && flutter test`
Expected: 87 passing.

- [ ] **Step 3: Commit (empty if nothing changed)**

If changes made:
```bash
git add -A
git commit -m "chore: remove stale SVG-sprite references from Gurgles"
```

If no changes, skip.

---

## Task 8: Menu idle-animation preview widget

**Files:**
- Create: `lib/components/gurgles_idle_widget.dart`
- Modify: `lib/scenes/menu_screen.dart`

- [ ] **Step 1: Create the idle widget**

Create `lib/components/gurgles_idle_widget.dart`:

```dart
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';

/// Standalone Flutter widget that plays Gurgles' idle animation —
/// no FlameGame required. Used on the menu screen while the player
/// types their name.
class GurglesIdleWidget extends StatefulWidget {
  final double size;
  const GurglesIdleWidget({super.key, this.size = 160});

  @override
  State<GurglesIdleWidget> createState() => _GurglesIdleWidgetState();
}

class _GurglesIdleWidgetState extends State<GurglesIdleWidget> {
  late final Future<SpriteAnimation> _future = _load();

  Future<SpriteAnimation> _load() async {
    final sprites = <Sprite>[];
    for (int i = 0; i < 20; i++) {
      final name = i.toString().padLeft(3, '0');
      sprites.add(await Sprite.load('gurgles/idle/$name.png'));
    }
    return SpriteAnimation.spriteList(sprites, stepTime: 0.08);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: FutureBuilder<SpriteAnimation>(
        future: _future,
        builder: (ctx, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          return SpriteAnimationWidget(
            animation: snap.data!,
            anchor: Anchor.center,
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Wire it into the menu**

Edit `lib/scenes/menu_screen.dart`. Add the import at the top:

```dart
import '../components/gurgles_idle_widget.dart';
```

Then replace the block around the "Best: N" Text (around lines 55–66) with:

```dart
              const Text(
                'Hold the Hooch',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD4A744),
                ),
              ),
              const SizedBox(height: 8),
              Text('Best: $_best',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              const GurglesIdleWidget(size: 160),
              const SizedBox(height: 16),
```

- [ ] **Step 3: Analyze + test**

Run: `flutter analyze && flutter test`
Expected: clean; 87 passing.

- [ ] **Step 4: Visual check — run on device**

Install debug APK on the Samsung S26 Ultra:

```bash
flutter build apk --debug
flutter install -d <device-id> --debug
```

Open the menu. Expected: Gurgles idling between "Best: N" and the name field, breathing/subtle motion, scaled to ~160 px.

- [ ] **Step 5: Commit**

```bash
git add lib/components/gurgles_idle_widget.dart lib/scenes/menu_screen.dart
git commit -m "feat(menu): add idle gurgles animation above name entry"
```

---

## Task 9: Device playtest + tune

**Files:**
- Modify: `lib/components/gurgles.dart` — hitbox size/position, tankard y-offset
- Modify: `lib/config/game_config.dart` — animation step-times if cadence feels off
- Modify: `lib/scenes/game_scene.dart:127-128` — Gurgles width/height multipliers if scale is wrong

This is a tuning pass, not TDD. The goal is: **Gurgles on-device looks natural running, jumping, and dying, with fair hitboxes and a tankard that reads as "above his head" throughout**.

- [ ] **Step 1: Run on Samsung S26 Ultra**

```bash
flutter build apk --debug && flutter install -d <device-id> --debug
```

- [ ] **Step 2: Checklist during play**

Observe and note specific issues:

| Check | Look for |
|---|---|
| **Scale** | Gurgles should visually occupy ~18% of screen height (matches current `gurglesHeight = size.y * 0.18`). If too small/large, adjust the multiplier in `game_scene.dart:127-128`. |
| **Vertical anchor** | Gurgles' feet should sit exactly on the ground line. If the content pads with transparent space at the bottom, the script's bbox-padding needs to be 0 below the feet — revisit `_contentBounds` if visible. |
| **Run cadence** | Leg cycle should feel purposeful, not manic. Tune `_loadSequence('run', 8, 0.06)` stepTime (0.06 = ~16fps); try 0.05 for faster, 0.08 for slower. |
| **Jump feel** | Takeoff frames (jumpStart) should play fully. If takeoff feels truncated, raise `GameConfig.jumpStartDurationSeconds`. Ditto `jumpLandDurationSeconds`. |
| **Hitbox fairness** | Jump over a root obstacle brushing the feet — should clear cleanly. Walk straight into a log — should collide. Adjust the `RectangleHitbox` size/position in `Gurgles.onLoad` until both feel right. |
| **Tankard position** | Should sit visibly above the head throughout the run cycle. The source frames have some head-bob; if it looks disconnected, adjust the `position: Vector2(size.x / 2, -2)` Y value in `Gurgles.onLoad` (more negative = higher). |
| **Hurt animation** | Hit an obstacle. Expect: hurt frames play, then dead pose holds for ~300ms, then overlay. If overlay appears too early, raise `gameOverHurtDelayMs`. Too late, lower it. |
| **Spill death** | Let the tilt run away. Expect: splash burst + hurt animation concurrently, then overlay. |
| **Menu idle** | Back at the menu, Gurgles should idle smoothly. If framerate looks wrong, tune stepTime in `GurglesIdleWidget`. |

- [ ] **Step 3: Commit tuning changes**

Commit once on-device behavior is acceptable:

```bash
git add -A
git commit -m "tune(gurgles): on-device scale/hitbox/stepTime adjustments after playtest"
```

If no changes were needed, skip the commit.

---

## Task 10: Documentation sweep

**Files:**
- Modify: `docs/STATUS.md`
- Modify: `docs/ROADMAP.md`
- Modify: `docs/ART-GUIDE.md`

- [ ] **Step 1: Update STATUS.md**

In `docs/STATUS.md`:

1. In the **What's playable today** list, replace the line about "sprite swaps between run and jump pose — no animated run cycle" with:

```
- Gurgles runs with a real 8-frame run cycle (derived from the no_hat_gnome gnome pack, see ART-PACK-INVENTORY.md). On jump: 7-frame takeoff → 12-frame airborne loop → 6-frame landing. On game over: 6-frame hurt → static dead pose held until overlay.
```

2. In the **Known issues & deferred work** table, delete rows 14 ("Run cycle sprite swap is binary") — now closed. Add a new row if tuning from Task 9 surfaced any follow-ups.

3. In the **Gotchas** section, add:

```
- **`image` package is dev-only.** The asset curation script at `tools/build_gurgles_sprites.dart` uses `package:image` and must not be imported from `lib/`. Raw frames live in `art-source/gnomes/` (gitignored) and are consumed by the script, not by the app.
```

- [ ] **Step 2: Update ROADMAP.md**

In `docs/ROADMAP.md` § M5a:
- Tick `[x] **6-frame run cycle** sprite swap` (note it's actually 8 frames, close enough — amend the line).
- Tick `[x] **Hurt pose** on game-over`.

Replace the two lines to read:

```markdown
- [x] **8-frame run cycle** sprite swap. Derived from the `no_hat_gnome` frames in the purchased gnome pack; see [ART-PACK-INVENTORY.md](ART-PACK-INVENTORY.md).
- [x] **Hurt pose** on game-over — full 6-frame hurt animation followed by a held `dead` pose.
```

- [ ] **Step 3: Update ART-GUIDE.md**

In `docs/ART-GUIDE.md`, add this note near the top (after whatever intro already exists):

```markdown
## Current character sprites

As of 2026-04-21 Gurgles is drawn from a derivative of the `no_hat_gnome` frames in the purchased *Gnomes Mega Character Pack* (Game Developer Studio, commercial licence per clause 4.1 of the GDN terms). See [ART-PACK-INVENTORY.md](ART-PACK-INVENTORY.md) for the full inventory. The original-pack staff prop is intentionally kept — a brewing druid's walking stick fits the character. The tankard remains a separate floating SVG overlay.

Asset-regeneration pipeline: extract the source pack into `art-source/gnomes/` (gitignored), then run `dart run tools/build_gurgles_sprites.dart`. Output lands in `assets/images/gurgles/<anim>/`.
```

- [ ] **Step 4: Commit**

```bash
git add docs/STATUS.md docs/ROADMAP.md docs/ART-GUIDE.md
git commit -m "docs: update STATUS/ROADMAP/ART-GUIDE for gnome animation swap"
```

- [ ] **Step 5: Final verification**

Run: `flutter analyze && flutter test`
Expected: clean analyzer, **87 passing tests**.

Install on device one more time, confirm menu idle + in-game run/jump/hurt all look right.

---

## Self-review notes (for the executor)

- The plan assumes the raw pack is extracted to `art-source/gnomes/` as today's inventory survey left it. If `gnomes.zip` was moved or deleted, re-extract per the instructions in `docs/ART-PACK-INVENTORY.md`.
- Every task lists exact file paths and exact code. No placeholders.
- The TDD cycle is honored on Task 4 (animator). Tasks 5–8 are refactor/wiring and are verified by the existing test suite + device playtest (Task 9).
- Estimated timing: Tasks 1–4 ~45 min (scripting + state machine + tests). Task 5 ~20 min (mechanical refactor). Task 6 ~10 min. Task 7 ~5 min. Task 8 ~15 min. Task 9 ~30 min (install + play). Task 10 ~10 min. Total ≈ **2 hours** hands-on.

## Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-21-gnome-animation-integration.md`. Two execution options:

1. **Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks.
2. **Inline Execution** — execute tasks in this session using executing-plans with checkpoints.

Which approach?
