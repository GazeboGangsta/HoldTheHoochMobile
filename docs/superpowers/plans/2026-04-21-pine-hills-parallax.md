# Pine Hills Parallax Rework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Replace the current 2-layer night-sky SVG parallax with a dusk-themed 13-layer raster parallax derived from the purchased/downloaded Pine Hills asset pack. Add independent cloud-drift layers for atmospheric depth.

**Architecture:**
- Add a raster sibling to the existing `ParallaxLayer` (SVG) component — `RasterParallaxLayer` — that loads PNGs through Flame's image cache and renders via `Sprite.render()` using pixel-perfect `FilterQuality.none` for crisp pixel-art scaling.
- Add a dedicated `CloudDrift` component for the 4 cloud drift layers — they scroll at a fixed speed independent of world scroll speed (so they drift even when the player is stationary, giving the scene life).
- Rewire `GameScene.onLoad()` to layer 11 non-cloud Pine Hills layers from sky-back through foreground trees in z-order, plus 4 drift clouds slotted between back-clouds and mountains.
- Update `backgroundColor()` to match Pine Hills sky gradient's top colour so there's no horizontal seam where the sky layer starts.
- Keep the existing `Ground` component (dark-brown dirt strip). Pine Hills front_grass/leafs/rocks render **on top** of Ground — additive, not replacement.

**Tech Stack:** Flutter 3.41.4 · Dart 3.11.1 · Flame 1.37 · `package:flame/sprite.dart` for raster parallax.

---

## Scope check

The 14-layer Pine Hills pack is visually rich but not architecturally deep — it's one raster parallax subsystem plus cloud drift. No sub-project split needed.

## File Structure

### New files
- `lib/components/raster_parallax_layer.dart` — raster sibling to `ParallaxLayer`. Loads a PNG via `Sprite.load`, tiles horizontally, scrolls at a speed factor of the world. `FilterQuality.none` by default (preserves pixel-art crispness when scaled 5×+).
- `lib/components/cloud_drift.dart` — drifts a single cloud PNG horizontally at a fixed velocity independent of world scroll. Wraps at tile boundaries.
- `assets/third_party/pine_hills/LICENSE.txt` — already present (included in the pack).
- `assets/third_party/pine_hills/png/*.png` — 14 layers (already extracted on-disk, currently untracked).
- `test/raster_parallax_layer_test.dart` — smoke test that the component mounts + computes tile width correctly.
- `test/cloud_drift_test.dart` — smoke test + offset-wrap math.

### Modified files
- `lib/scenes/game_scene.dart` — replace the 2 `ParallaxLayer(svg)` calls with 11 raster layers + 4 cloud-drift components. Update `backgroundColor()` from `#1A1A3E` (night navy) to the Pine Hills sky gradient top (~`#77B8DC` or similar — measure from `00_background.png`).
- `pubspec.yaml` — register `assets/third_party/pine_hills/png/` as an asset directory.
- `docs/STATUS.md` — update the "What's playable today" parallax description.
- `docs/ROADMAP.md` — tick the M5a parallax upgrade (if present).
- `docs/ART-GUIDE.md` — add a "Backdrop art" section crediting Pine Hills.
- `.gitignore` — already updated to ignore the `.zip`s; confirm.

### Untouched (may become dead code but kept for now)
- `lib/components/parallax_bg.dart` — SVG-backed `ParallaxLayer`. Orphaned after this plan. Flagged as cleanup-candidate follow-up rather than deleted inline (avoid scope creep).
- `assets/svg/bg-mountains.svg`, `assets/svg/bg-trees.svg` — kept for reference; no longer loaded by code.

---

## Task 1: Stage the Pine Hills assets + register in pubspec

**Files:**
- Create: `assets/third_party/pine_hills/png/*.png` — already extracted, just git-add.
- Include: `assets/third_party/pine_hills/LICENSE.txt` + `pine hills.aseprite`.
- Modify: `pubspec.yaml` — new asset path.

- [ ] **Step 1: Verify extraction on-disk**

Run: `ls assets/third_party/pine_hills/png/`
Expected: 14 PNG files (00_background, 01_back clouds, 02_cloud1 … 13_front_rocks).

- [ ] **Step 2: Register asset directory in pubspec.yaml**

Edit `pubspec.yaml`. Find the `assets:` block under `flutter:` and add `- assets/third_party/pine_hills/png/` right after `assets/images/gurgles/dead/`:

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
    - assets/third_party/pine_hills/png/
    - assets/audio/
```

**Gotcha to watch for:** the filename `01_back clouds.png` has a SPACE in it. Flutter's asset resolver tolerates spaces in filenames but sometimes external tooling doesn't. Leave the filename as-is (don't rename — we want to keep the source untouched so regeneration from the .aseprite master is lossless) and reference it verbatim in code (`'third_party/pine_hills/png/01_back clouds.png'`).

- [ ] **Step 3: Verify**

Run: `flutter pub get && flutter analyze`
Expected: clean.

- [ ] **Step 4: Commit (explicit paths — NOT `git add -A`)**

```bash
git add pubspec.yaml
git add assets/third_party/pine_hills/LICENSE.txt
git add assets/third_party/pine_hills/png/
git add "assets/third_party/pine_hills/pine hills.aseprite"
git add assets/third_party/forest_sprites/LICENSE.txt
git add .gitignore
git commit -m "chore: stage Pine Hills parallax pack + license files"
```

(The ForestSprites LICENSE + `.gitignore` `.zip` additions from earlier in this session also land in this commit — same class of work.)

---

## Task 2: `RasterParallaxLayer` component (TDD)

**Files:**
- Create: `lib/components/raster_parallax_layer.dart`
- Create: `test/raster_parallax_layer_test.dart`

This mirrors the existing `lib/components/parallax_bg.dart` (SVG) but loads a raster via `Sprite.load` + renders via `Sprite.render`. Per-layer speed factor + world-speed provider + horizontal tiling. `FilterQuality.none` by default so pixel art stays crisp when scaled.

- [ ] **Step 1: Write the failing test**

Create `test/raster_parallax_layer_test.dart`:

```dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/raster_parallax_layer.dart';

void main() {
  group('RasterParallaxLayer', () {
    test('computes tile width from height * source aspect ratio', () {
      // 320x180 source → aspect 320/180 = 1.778
      // At 200px height, tile width = 200 * 1.778 = 355.56
      final tileWidth = RasterParallaxLayer.computeTileWidth(
        renderHeight: 200,
        sourceWidth: 320,
        sourceHeight: 180,
      );
      expect(tileWidth, closeTo(355.56, 0.1));
    });

    test('scrolls offset forward by worldSpeed * speedFactor * dt', () {
      // Offset after 1 second at worldSpeed=200, speedFactor=0.5 = 100px.
      final newOffset = RasterParallaxLayer.advanceOffset(
        currentOffset: 0,
        worldSpeed: 200,
        speedFactor: 0.5,
        dt: 1.0,
        tileWidth: 400,
      );
      expect(newOffset, 100);
    });

    test('wraps offset at tile boundary', () {
      // Offset starting at 390, advance 20 → would be 410, wraps to 10.
      final newOffset = RasterParallaxLayer.advanceOffset(
        currentOffset: 390,
        worldSpeed: 200,
        speedFactor: 0.1,
        dt: 1.0,
        tileWidth: 400,
      );
      expect(newOffset, 10);
    });

    test('constructor stores layout params', () {
      final layer = RasterParallaxLayer(
        assetPath: 'third_party/pine_hills/png/00_background.png',
        speedFactor: 0.15,
        worldSpeedProvider: () => 280,
        worldSize: Vector2(400, 800),
        yPosition: 100,
        height: 500,
        sourceWidth: 320,
        sourceHeight: 180,
      );
      expect(layer.position.y, 100);
      expect(layer.size, Vector2(400, 500));
      expect(layer.speedFactor, 0.15);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/raster_parallax_layer_test.dart`
Expected: compile failure (file doesn't exist yet).

- [ ] **Step 3: Implement the component**

Create `lib/components/raster_parallax_layer.dart`:

```dart
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

/// Raster sibling to `ParallaxLayer` (which is SVG-backed). Loads a PNG via
/// Flame's image cache, tiles it horizontally, and scrolls at a fractional
/// speed relative to the world.
///
/// Designed for pixel-art parallax packs: renders with
/// `FilterQuality.none` by default so scaled-up pixels stay crisp.
class RasterParallaxLayer extends PositionComponent {
  final String assetPath;
  final double speedFactor;
  final double Function() worldSpeedProvider;
  final int sourceWidth;
  final int sourceHeight;
  final FilterQuality filterQuality;

  Sprite? _sprite;
  late final double _tileWidth;
  double _offset = 0;

  RasterParallaxLayer({
    required this.assetPath,
    required this.speedFactor,
    required this.worldSpeedProvider,
    required Vector2 worldSize,
    required double yPosition,
    required double height,
    required this.sourceWidth,
    required this.sourceHeight,
    this.filterQuality = FilterQuality.none,
  }) : super(
          position: Vector2(0, yPosition),
          size: Vector2(worldSize.x, height),
        );

  @override
  Future<void> onLoad() async {
    _sprite = await Sprite.load(assetPath);
    _tileWidth = computeTileWidth(
      renderHeight: size.y,
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _offset = advanceOffset(
      currentOffset: _offset,
      worldSpeed: worldSpeedProvider(),
      speedFactor: speedFactor,
      dt: dt,
      tileWidth: _tileWidth,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final sprite = _sprite;
    if (sprite == null) return;
    final tileSize = Vector2(_tileWidth, size.y);
    final paint = Paint()..filterQuality = filterQuality;
    canvas.save();
    canvas.translate(-_offset, 0);
    var x = 0.0;
    while (x < size.x + _tileWidth) {
      sprite.render(canvas, size: tileSize, overridePaint: paint);
      canvas.translate(_tileWidth, 0);
      x += _tileWidth;
    }
    canvas.restore();
  }

  /// Pure function for the tile-width derivation — tested in
  /// `test/raster_parallax_layer_test.dart`.
  @visibleForTesting
  static double computeTileWidth({
    required double renderHeight,
    required int sourceWidth,
    required int sourceHeight,
  }) =>
      renderHeight * sourceWidth / sourceHeight;

  /// Pure function for the offset advance + wrap. Tested in the unit tests.
  @visibleForTesting
  static double advanceOffset({
    required double currentOffset,
    required double worldSpeed,
    required double speedFactor,
    required double dt,
    required double tileWidth,
  }) =>
      (currentOffset + worldSpeed * speedFactor * dt) % tileWidth;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/raster_parallax_layer_test.dart`
Expected: 4 tests PASS.

- [ ] **Step 5: Full sweep**

Run: `flutter analyze && flutter test`
Expected: clean + 89 + 4 = **93 passing**.

- [ ] **Step 6: Commit**

```bash
git add lib/components/raster_parallax_layer.dart test/raster_parallax_layer_test.dart
git commit -m "feat: RasterParallaxLayer component for PNG-backed parallax"
```

---

## Task 3: `CloudDrift` component (TDD)

**Files:**
- Create: `lib/components/cloud_drift.dart`
- Create: `test/cloud_drift_test.dart`

Clouds scroll at a fixed pixels-per-second velocity independent of world scroll — so they drift even when the player is stationary. Each cloud is a separate `CloudDrift` component with its own speed (negative → leftward drift, positive → rightward). They wrap at tile boundaries same as the parallax layer.

- [ ] **Step 1: Write the failing test**

Create `test/cloud_drift_test.dart`:

```dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/cloud_drift.dart';

void main() {
  group('CloudDrift', () {
    test('offset advances by driftPxPerSecond * dt', () {
      final newOffset = CloudDrift.advanceOffset(
        currentOffset: 0,
        driftPxPerSecond: 15,
        dt: 1.0,
        tileWidth: 600,
      );
      expect(newOffset, 15);
    });

    test('negative drift (rightward) wraps at 0 boundary', () {
      // Moving right at -10 px/s for 1s from offset 5 → -5, wraps to 595
      // (since negative % in Dart can be negative, we expect wrap to tileWidth - |over|).
      final newOffset = CloudDrift.advanceOffset(
        currentOffset: 5,
        driftPxPerSecond: -10,
        dt: 1.0,
        tileWidth: 600,
      );
      expect(newOffset, closeTo(595, 0.0001));
    });

    test('positive drift wraps at tile boundary', () {
      // Moving left at 600 px/s for 1s from offset 100 → 700, wraps to 100.
      final newOffset = CloudDrift.advanceOffset(
        currentOffset: 100,
        driftPxPerSecond: 600,
        dt: 1.0,
        tileWidth: 600,
      );
      expect(newOffset, closeTo(100, 0.0001));
    });

    test('constructor stores layout params', () {
      final cloud = CloudDrift(
        assetPath: 'third_party/pine_hills/png/02_cloud1.png',
        driftPxPerSecond: 12,
        worldSize: Vector2(400, 800),
        yPosition: 50,
        height: 200,
        sourceWidth: 320,
        sourceHeight: 180,
      );
      expect(cloud.position.y, 50);
      expect(cloud.size, Vector2(400, 200));
      expect(cloud.driftPxPerSecond, 12);
    });
  });
}
```

- [ ] **Step 2: Run tests — verify fail**

Run: `flutter test test/cloud_drift_test.dart`
Expected: compile failure.

- [ ] **Step 3: Implement**

Create `lib/components/cloud_drift.dart`:

```dart
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

/// Drifts a single cloud PNG horizontally at a fixed velocity, independent
/// of world scroll speed. Tiles horizontally the same way [RasterParallaxLayer]
/// does, so clouds wrap seamlessly.
///
/// Use a small positive velocity (e.g. 8-20 px/s) for a slow leftward drift
/// that reads as distant wind. Negative velocity drifts rightward.
class CloudDrift extends PositionComponent {
  final String assetPath;
  final double driftPxPerSecond;
  final int sourceWidth;
  final int sourceHeight;
  final FilterQuality filterQuality;

  Sprite? _sprite;
  late final double _tileWidth;
  double _offset = 0;

  CloudDrift({
    required this.assetPath,
    required this.driftPxPerSecond,
    required Vector2 worldSize,
    required double yPosition,
    required double height,
    required this.sourceWidth,
    required this.sourceHeight,
    this.filterQuality = FilterQuality.none,
  }) : super(
          position: Vector2(0, yPosition),
          size: Vector2(worldSize.x, height),
        );

  @override
  Future<void> onLoad() async {
    _sprite = await Sprite.load(assetPath);
    _tileWidth = size.y * sourceWidth / sourceHeight;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _offset = advanceOffset(
      currentOffset: _offset,
      driftPxPerSecond: driftPxPerSecond,
      dt: dt,
      tileWidth: _tileWidth,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final sprite = _sprite;
    if (sprite == null) return;
    final tileSize = Vector2(_tileWidth, size.y);
    final paint = Paint()..filterQuality = filterQuality;
    canvas.save();
    canvas.translate(-_offset, 0);
    var x = 0.0;
    while (x < size.x + _tileWidth) {
      sprite.render(canvas, size: tileSize, overridePaint: paint);
      canvas.translate(_tileWidth, 0);
      x += _tileWidth;
    }
    canvas.restore();
  }

  /// Pure function — advances offset and wraps positive AND negative values
  /// within [0, tileWidth). Dart's `%` operator returns negative values for
  /// negative operands, so we adjust.
  @visibleForTesting
  static double advanceOffset({
    required double currentOffset,
    required double driftPxPerSecond,
    required double dt,
    required double tileWidth,
  }) {
    final raw = (currentOffset + driftPxPerSecond * dt) % tileWidth;
    return raw < 0 ? raw + tileWidth : raw;
  }
}
```

- [ ] **Step 4: Run tests — verify pass**

Run: `flutter test test/cloud_drift_test.dart`
Expected: 4 PASS.

- [ ] **Step 5: Full sweep**

Run: `flutter analyze && flutter test`
Expected: clean + **97 passing** (89 + 4 + 4).

- [ ] **Step 6: Commit**

```bash
git add lib/components/cloud_drift.dart test/cloud_drift_test.dart
git commit -m "feat: CloudDrift component for independent atmospheric cloud scrolling"
```

---

## Task 4: Rewire GameScene to use Pine Hills parallax

**Files:**
- Modify: `lib/scenes/game_scene.dart`

### Step 1: Sample the sky-top colour

Open `assets/third_party/pine_hills/png/00_background.png` in a viewer and eyedrop the top-row colour. Expected: a light blue like `#77B8DC`. (If the sample doesn't match any existing viewer, approximate — this is tuned on-device in Task 6. A reasonable starting value is `0xFF77B8DC`. Too low-contrast with your sky and you get a seam; close enough and you won't see the transition.)

For the plan's baseline: use `0xFF77B8DC`. Revise in Task 6 if the seam is visible.

### Step 2: Replace the current parallax block

In `lib/scenes/game_scene.dart`, find the existing parallax block (currently around lines 98-116):

```dart
    final mountainsHeight = size.y * 0.42;
    final treesHeight = size.y * 0.32;

    add(ParallaxLayer(
      assetPath: 'svg/bg-mountains.svg',
      speedFactor: 0.15,
      ...
    ));
    add(ParallaxLayer(
      assetPath: 'svg/bg-trees.svg',
      speedFactor: 0.45,
      ...
    ));
```

Replace with:

```dart
    // Pine Hills parallax stack — layered back-to-front with per-layer
    // speed factors. All layers are 320x180 pixel-art (source) scaled up
    // to fill the playable area. See docs/superpowers/plans/
    // 2026-04-21-pine-hills-parallax.md for the full layer allocation.
    final playAreaHeight = _groundY;
    const srcW = 320;
    const srcH = 180;

    // 00: static sky background (full playable area, does not scroll).
    add(RasterParallaxLayer(
      assetPath: 'third_party/pine_hills/png/00_background.png',
      speedFactor: 0.0,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: 0,
      height: playAreaHeight,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));

    // 01: back-cloud field (fills sky, very slow drift).
    add(RasterParallaxLayer(
      assetPath: 'third_party/pine_hills/png/01_back clouds.png',
      speedFactor: 0.03,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: 0,
      height: playAreaHeight * 0.55,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));

    // 02-05: drift clouds at independent speeds (px/s), slotted across the
    // sky at varying y offsets. Leftward drift values (positive). Feel free
    // to set one or two to small negatives for a gentle counter-breeze.
    add(CloudDrift(
      assetPath: 'third_party/pine_hills/png/02_cloud1.png',
      driftPxPerSecond: 8,
      worldSize: size,
      yPosition: playAreaHeight * 0.08,
      height: playAreaHeight * 0.35,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));
    add(CloudDrift(
      assetPath: 'third_party/pine_hills/png/03_cloud2.png',
      driftPxPerSecond: 14,
      worldSize: size,
      yPosition: playAreaHeight * 0.18,
      height: playAreaHeight * 0.35,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));
    add(CloudDrift(
      assetPath: 'third_party/pine_hills/png/04_cloud3.png',
      driftPxPerSecond: 22,
      worldSize: size,
      yPosition: playAreaHeight * 0.05,
      height: playAreaHeight * 0.35,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));
    add(CloudDrift(
      assetPath: 'third_party/pine_hills/png/05_cloud4.png',
      driftPxPerSecond: -10,   // rightward counter-drift for variety
      worldSize: size,
      yPosition: playAreaHeight * 0.22,
      height: playAreaHeight * 0.35,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));

    // 06: back mountains (far, slow).
    add(RasterParallaxLayer(
      assetPath: 'third_party/pine_hills/png/06_back_mountains.png',
      speedFactor: 0.12,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: playAreaHeight * 0.35,
      height: playAreaHeight * 0.50,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));

    // 07: mid hills.
    add(RasterParallaxLayer(
      assetPath: 'third_party/pine_hills/png/07_mid_hills.png',
      speedFactor: 0.22,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: playAreaHeight * 0.50,
      height: playAreaHeight * 0.40,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));

    // 08: mid forest (denser closer trees).
    add(RasterParallaxLayer(
      assetPath: 'third_party/pine_hills/png/08_mid_forest.png',
      speedFactor: 0.40,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: playAreaHeight * 0.58,
      height: playAreaHeight * 0.35,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));
```

**Leave the subsequent ground / collectible / obstacle / gurgles / UI add() calls exactly where they are.**

Then, AFTER `add(gurgles)` (so front trees render on top of the player for depth occlusion), append the front-tree layers:

```dart
    // 09: front grass — sits at the ground line at world speed.
    add(RasterParallaxLayer(
      assetPath: 'third_party/pine_hills/png/09_front_grass.png',
      speedFactor: 1.0,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: playAreaHeight - playAreaHeight * 0.12,
      height: playAreaHeight * 0.12,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));

    // 10: front leafs (dirt/leaves ground edge).
    add(RasterParallaxLayer(
      assetPath: 'third_party/pine_hills/png/10_front_leafs.png',
      speedFactor: 1.0,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: playAreaHeight - playAreaHeight * 0.10,
      height: playAreaHeight * 0.10,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));

    // 11: front trees left cluster (slower than world = closer to camera).
    add(RasterParallaxLayer(
      assetPath: 'third_party/pine_hills/png/11_front_trees1.png',
      speedFactor: 0.85,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: playAreaHeight - playAreaHeight * 0.55,
      height: playAreaHeight * 0.55,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));

    // 12: front trees right cluster.
    add(RasterParallaxLayer(
      assetPath: 'third_party/pine_hills/png/12_front_trees2.png',
      speedFactor: 0.92,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: playAreaHeight - playAreaHeight * 0.50,
      height: playAreaHeight * 0.50,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));

    // 13: front rocks — at the ground line.
    add(RasterParallaxLayer(
      assetPath: 'third_party/pine_hills/png/13_front_rocks.png',
      speedFactor: 1.0,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: playAreaHeight - playAreaHeight * 0.10,
      height: playAreaHeight * 0.10,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));
```

### Step 3: Update `backgroundColor()`

Find the method in `game_scene.dart:57`:

```dart
  @override
  Color backgroundColor() => const Color(0xFF1A1A3E);
```

Replace with:

```dart
  // Matched to the top row of Pine Hills 00_background.png so there's no
  // horizontal seam where the sky layer's gradient begins. Tune in Task 6
  // if a seam is visible on device.
  @override
  Color backgroundColor() => const Color(0xFF77B8DC);
```

### Step 4: Update imports

Add at the top of `game_scene.dart`:

```dart
import '../components/cloud_drift.dart';
import '../components/raster_parallax_layer.dart';
```

Remove the now-unused `ParallaxLayer` import:

```dart
import '../components/parallax_bg.dart';
```

### Step 5: Run

```
flutter analyze && flutter test
```

Expected: clean + 97 passing (no new tests this task — it's wiring).

### Step 6: Commit

```bash
git add lib/scenes/game_scene.dart
git commit -m "feat(scene): swap night-sky SVG parallax for Pine Hills 13-layer raster + cloud drift"
```

---

## Task 5: Update existing parallax test if present

**Files:**
- `test/parallax_bg_test.dart` if it exists.

- [ ] **Step 1: Check if there's an existing parallax test**

Run: `ls test/ | grep -i parallax`

- [ ] **Step 2: If it tests the SVG `ParallaxLayer`**, leave it. The SVG component still works — we just don't use it. The test verifying its math is still valid regression protection.

- [ ] **Step 3: If it tests `GameScene` parallax wiring** (i.e. asserts specific layer counts or SVG paths in the scene), update the assertion to match the new layer set.

No commit if no changes.

---

## Task 6: Device playtest + tune

This is a tuning pass, not TDD. The user will install the build on their Samsung S26 Ultra and report back on any visual issues.

- [ ] **Step 1: Rebuild + install**

```bash
flutter build apk --debug
flutter install -d <device-id> --debug
```

- [ ] **Step 2: Playtest checklist**

Observe and note:

| Check | What to look for | Knob to tune |
|---|---|---|
| **Seam between bg colour and sky layer** | Gradient top should blend invisibly | `backgroundColor()` hex in game_scene.dart:57 |
| **Sky gradient saturation** | Not too bright (washes out Gurgles), not too dark | Can tint the sky layer with a Paint `colorFilter` — or just accept |
| **Cloud drift speed** | Slow enough to feel atmospheric, not so slow it looks static. Different-speed clouds should be visibly independent | `driftPxPerSecond` on each `CloudDrift` |
| **Back mountains depth** | Should feel distant (barely scrolls) | `speedFactor` on the mountains layer |
| **Mid forest layer position** | Forest line should sit at a sensible mid-depth, NOT overlap mountains | `yPosition` and `height` |
| **Front trees occluding Gurgles** | Trees should pass IN FRONT of Gurgles occasionally (depth feel) | z-order — add() call order |
| **Front grass vs existing Ground strip** | The brown dirt Ground strip should still be visible behind the grass blades | Verify Ground is rendered; front_grass only covers the TOP edge |
| **Character visibility** | Gurgles must stay clearly visible against the dusk background | If purple bg washes him out, could tint sky slightly darker |
| **Performance** | Frame rate should stay ≥ 60 fps. 13 parallax layers + 4 cloud-drifts = 17 components per-frame rendering | Profile with Flutter DevTools if stutter appears. Reduce layer count as last resort |

- [ ] **Step 3: Commit any tuning changes**

```bash
git add -A       # OR explicit files if in doubt
git commit -m "tune(pine-hills): on-device parallax adjustments (speeds/positions)"
```

Use explicit paths if anything untracked is still in the working tree.

---

## Task 7: Documentation sweep

**Files:**
- Modify: `docs/STATUS.md`
- Modify: `docs/ROADMAP.md`
- Modify: `docs/ART-GUIDE.md`

- [ ] **Step 1: STATUS.md**

In the "What's playable today" list, find the parallax bullet (currently: "Parallax: distant mountains (0.15x) + forest trees (0.45x) + tiled ground (1.0x)."). Replace with:

```
- Parallax: **13-layer dusk forest scene from the Pine Hills pack** — sky gradient → back-cloud field → 4 drifting clouds (independent speeds, one counter-drift) → back mountains (0.12×) → mid hills (0.22×) → mid forest (0.40×) → tiled Ground → front grass/leafs/rocks (1.0×) → foreground trees 1/2 (0.85×/0.92×) rendered in front of Gurgles for depth occlusion.
```

Update the "Dark-navy night sky backdrop" bullet to reflect the new dusk backdrop.

Add a Gotcha at the bottom of the Gotchas list:

```
- **Flame's built-in `ParallaxComponent` is geometric per-layer, not arbitrary.** It multiplies a `velocityMultiplierDelta` by layer index, so you can't set layer 3 faster than layer 5. That's why we hand-rolled `RasterParallaxLayer` + `CloudDrift` — they let each layer own its speed factor / px-per-sec, which is required for a dusk scene where cloud drift is independent of ground scroll.
```

- [ ] **Step 2: ROADMAP.md**

In M5a — Visuals, find any parallax-related line (currently there's "Parallax background (mountains + trees)" as ✅). Change to:

```markdown
- [x] Parallax background — **Pine Hills 13-layer dusk forest + 4-cloud drift** (M5a). See [docs/superpowers/plans/2026-04-21-pine-hills-parallax.md](superpowers/plans/2026-04-21-pine-hills-parallax.md). Replaces the earlier 2-layer SVG night-sky prototype.
```

- [ ] **Step 3: ART-GUIDE.md**

Append a new section below the gnome-pack "Current character sprites" block:

```markdown
## Current backdrop art

**As of 2026-04-21 the game's parallax backdrop is the free "Pine Hills" pack from [myaumya.itch.io](https://myaumya.itch.io/pine-hills-background).** Licensed for commercial use + modification, no redistribution. See [assets/third_party/pine_hills/LICENSE.txt](../assets/third_party/pine_hills/LICENSE.txt). The pack ships as 14 pixel-art PNG layers at 320×180; we render them upscaled with `FilterQuality.none` for a crisp retro look.

Layer allocation + speed factors are documented in [lib/scenes/game_scene.dart](../lib/scenes/game_scene.dart) and in the plan at [docs/superpowers/plans/2026-04-21-pine-hills-parallax.md](superpowers/plans/2026-04-21-pine-hills-parallax.md).

The deliberate pixel-art-background / smooth-cartoon-character hybrid style is a known aesthetic (Celeste, Hyper Light Drifter). If we ever commission custom parallax art later, the `RasterParallaxLayer` component already handles arbitrary PNGs — drop the new images in and tune the speed factors.

## Unused asset pack: Forest Sprites

An alternative free pack from itch.io (`assets/third_party/forest_sprites/`) is staged on disk but not wired in — lighter, only 5 layers, daylight palette. Kept as a potential theme option for V2. License at [assets/third_party/forest_sprites/LICENSE.txt](../assets/third_party/forest_sprites/LICENSE.txt).
```

- [ ] **Step 4: Run verifications**

```bash
flutter analyze && flutter test
```

Expected: clean + 97 passing.

- [ ] **Step 5: Commit**

```bash
git add docs/STATUS.md docs/ROADMAP.md docs/ART-GUIDE.md
git commit -m "docs: STATUS/ROADMAP/ART-GUIDE updates for Pine Hills parallax integration"
```

---

## Self-review

- **Plan coverage**: each of the 13 Pine Hills layers + 4 cloud drifts is explicitly wired in Task 4. No placeholder "TODO" or "add remaining layers" anywhere.
- **TDD honoured**: Tasks 2 and 3 (new components) follow red-green-commit. Task 4 (scene rewiring) is integration; validated by device playtest in Task 6 rather than a unit test (appropriate — the value of the wiring is the on-screen composition).
- **Type consistency**: `RasterParallaxLayer` and `CloudDrift` share the `sourceWidth`/`sourceHeight`/`filterQuality` signature, and both use Flame's `Sprite.load`. Method names `computeTileWidth` / `advanceOffset` consistent across both components.
- **Dead code deliberate**: `lib/components/parallax_bg.dart` becomes orphaned but is kept for reference. Cleanup tracked as a follow-up, not bundled here.
- **Gotchas captured** in Task 7's STATUS update.
- **Explicit file staging** repeated in every commit step per the lessons of the Task 7 pollution incident from the previous plan.

## Execution handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-21-pine-hills-parallax.md`. Two execution options:

1. **Subagent-Driven (recommended)** — dispatch a fresh subagent per task, two-stage review between tasks.
2. **Inline Execution** — work through the plan in this session with checkpoints.

Which approach?
