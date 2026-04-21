# Obstacle + Collectible Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the web-game-era SVG obstacles and collectibles with pixel-art from the packs staged in `temp/`, swap `root` obstacle for `stone`, rename `herb`/`hops` collectibles to `fruitCommon`/`fruitMedium`, and add `fruitRare` + `crystal` as new higher-tier collectible kinds. Wire Onocentaur potion art as the new `potion` sprite.

**Architecture:**
- New Dart build script `tools/build_obstacle_collectible_sprites.dart` uses `package:image` (existing dev dep) to slice the Nature Full atlas (for crystals), the animated-mushroom sheets (for mushroom frames), the Log_sprite strip (for log frames), and the Onocentaur potion atlas (for a single curated potion) into individual named PNGs under `assets/images/obstacles/` + `assets/images/collectibles/`. Individual fruit/veg PNGs + rock PNGs copy across directly.
- `Obstacle` component extends to load a `SpriteAnimationComponent` for `mushroom` and `log` kinds, keeping `SpriteComponent` for `stone` and `rock`.
- `Collectible` component takes an explicit sprite path in the constructor (rather than deriving from kind) so `CollectibleManager` can pick a random variant per spawn — same kind, different sprite (e.g. `fruitCommon` randomly renders as strawberry, cherry, or tomato).
- `ObstacleKind { stone, rock, mushroom, log }` — drops `root`, adds `stone`.
- `CollectibleKind { fruitCommon, fruitMedium, fruitRare, crystal, potion }` — renames + extends the 3-kind enum.
- `SparkleBurst` gains per-kind configs for `fruitRare` (gold medium) + `crystal` (purple large-with-halo). `fruitCommon` inherits the old `herb` tuning (green → red), `fruitMedium` inherits `hops` (gold → orange), `potion` unchanged.
- `ObstacleManager` + `CollectibleManager` weighted-roll tables updated for the new kinds. Collectible manager adds a sprite-variant-selection step before constructing.

**Tech Stack:** Flutter 3.41.4 · Dart 3.11.1 · Flame 1.37 · `package:image` ^4.3.0 (dev dep, already in pubspec).

**Staged inventory:** See [docs/OBSTACLE-COLLECTIBLE-ASSETS.md](../../OBSTACLE-COLLECTIBLE-ASSETS.md) for the full pack survey. Licences all verified commercial-OK.

---

## Scope check

This plan covers one subsystem: the game's obstacle + collectible sprites + enum roster. Power-up-potion mechanics, butterfly-moving-pickups, bug-obstacles, and leaf-drift-particles are explicitly V2 — out of scope.

## File Structure

### New files
- `tools/build_obstacle_collectible_sprites.dart` — one-shot slicer + copy script.
- `assets/third_party/nature_full/global.png` + `global_shadow.png` + `license.txt` + `list.txt` + `readme.txt` + `glow.png` — raw pack, tracked in repo.
- `assets/third_party/mushrooms/AnimatedMushroomRed.png` + `AnimatedMushroomPink.png` + `AnimatedMushroomBlue.png` + user-added `LICENSE.txt`.
- `assets/third_party/potions_onocentaur/Potions - Full, Corked.png` + `ABOUT.txt`.
- `assets/third_party/props/Boulder 32x32.png` + `MossyBoulder 32x32.png` + `Rock_03 32x32.png` + `Stone_01 16x16.png` + `Log_sprite.png` — individual rock/log PNGs staged.
- `assets/third_party/fruits_veg/*.png` — all 17 individual fruit/veg PNGs.
- `assets/images/obstacles/stone.png` — curated
- `assets/images/obstacles/rock.png` — curated
- `assets/images/obstacles/mushroom/000.png`…`007.png` — 8 animation frames (sliced)
- `assets/images/obstacles/log/000.png`…`003.png` — 4 animation frames (sliced)
- `assets/images/collectibles/cherry.png`, `strawberry.png`, `tomato.png` — Tier 1 variants (copied)
- `assets/images/collectibles/apple.png`, `orange.png`, `pumpkin.png` — Tier 2 variants (copied)
- `assets/images/collectibles/golden_apple.png` — Tier 3 rare (copied)
- `assets/images/collectibles/crystal/rose_quartz.png`…`bloodstone.png` — 10 crystal variants (sliced from Nature Full)
- `assets/images/collectibles/potion.png` — single curated Onocentaur potion (sliced)

### Modified files
- `lib/components/obstacle.dart` — enum rename, add animation branch in onLoad, update sprite paths + hitboxes.
- `lib/components/collectible.dart` — enum rename + extension, constructor takes explicit spritePath, update sizes + points.
- `lib/components/sparkle_burst.dart` — configFor adds fruitRare + crystal cases, rename herb→fruitCommon, hops→fruitMedium.
- `lib/systems/obstacle_manager.dart` — drop root from rollable kinds, add stone, add basic weight table.
- `lib/systems/collectible_manager.dart` — weighted roll for 5 kinds, sprite-variant selection per kind, updated height tiers.
- `lib/scenes/game_scene.dart` — update SparkleBurst.emit kind references if any changed.
- `pubspec.yaml` — register `assets/images/obstacles/` + `assets/images/collectibles/` + per-animation subfolders.
- `test/obstacle_hitbox_test.dart` — no code changes needed (parameterizes over enum values) — but run to confirm it still passes.
- `test/collectible_hitbox_test.dart` — hardcoded `Vector2(48,48)` "herb reference" sizes list must be updated to the new per-kind sizes.
- `test/sparkle_burst_test.dart` — order assertions (`herb < hops < potion`) rewritten for the new 5-kind ordering (`fruitCommon < fruitMedium < fruitRare < crystal < potion`).
- `.gitignore` — add `temp/` (so the working dir stops showing up in `git status`).
- `docs/STATUS.md` — note obstacle/collectible refresh in the M5a section.
- `docs/ROADMAP.md` — tick the M5a obstacle+collectible refresh item.
- `docs/ART-GUIDE.md` — new "Current obstacle + collectible art" section.

### Untouched
- `lib/config/game_config.dart` — the per-kind point values + spawn weights live on the enum-config static maps inside the component files, not in GameConfig. Follow existing pattern.
- The old `svg/herb.svg`, `svg/hops.svg`, `svg/potion.svg`, `svg/root.svg`, `svg/rock.svg`, `svg/mushroom.svg`, `svg/log.svg` — kept on disk (harmless, not loaded by code after this plan). Cleanup candidate for a later pass.

### Decisions baked in

- **Potion art**: Onocentaur's red heart-potion (the first bottle in row 0 of `Potions - Full, Corked.png`). Single curated variant for V1.
- **`root` obstacle kind**: dropped. V1 ships 4 obstacle kinds (stone, rock, mushroom, log).
- **Crystal variants**: all 10 from Nature Full row 10. Manager picks one at random per spawn — same `crystal` kind behaviour, visual variety for free.
- **Mushroom / log animations**: sliced from atlases to per-frame PNGs (same pattern as Gurgles' sprites). stepTime hardcoded per kind in the component.
- **Rock variants**: V1 uses just `Rock_03` as the canonical rock sprite. Boulder/MossyBoulder kept in `assets/third_party/props/` for V2 variant spawning.

---

## Task 1: Stage third-party packs and register pubspec assets

**Files:**
- Move: `temp/*` → `assets/third_party/<pack_name>/`
- Modify: `pubspec.yaml` (asset paths)
- Modify: `.gitignore` (add `temp/`)

- [ ] **Step 1: Clean up temp staging**

Move the packs out of `temp/` (gitignored working dir) into the tracked `assets/third_party/` tree. From the repo root:

```bash
mkdir -p assets/third_party/nature_full
mkdir -p assets/third_party/mushrooms
mkdir -p assets/third_party/potions_onocentaur
mkdir -p assets/third_party/props
mkdir -p assets/third_party/fruits_veg

# Nature Full (license bundled inside)
cp "temp/nature_full/nature full/global.png" assets/third_party/nature_full/
cp "temp/nature_full/nature full/global_shadow.png" assets/third_party/nature_full/
cp "temp/nature_full/nature full/glow.png" assets/third_party/nature_full/
cp "temp/nature_full/nature full/license.txt" assets/third_party/nature_full/LICENSE.txt
cp "temp/nature_full/nature full/list.txt" assets/third_party/nature_full/
cp "temp/nature_full/nature full/readme.txt" assets/third_party/nature_full/

# Mushrooms (no license file — user-confirmed commercial-OK)
cp temp/mushrooms/Mushrooms/*.png assets/third_party/mushrooms/
cat > assets/third_party/mushrooms/LICENSE.txt <<'EOF'
Commercial-OK per user confirmation 2026-04-21 (free itch.io pack).
Cannot redistribute the raw assets; use within a derivative work only.
EOF

# Onocentaur Potions
cp "temp/potions_onocentaur/Potions by Onocentaur/Potions - Full, Corked.png" assets/third_party/potions_onocentaur/
cp "temp/potions_onocentaur/Potions by Onocentaur/ABOUT.txt" assets/third_party/potions_onocentaur/

# Individual props (rocks + log)
cp "temp/Boulder 32x32.png" assets/third_party/props/
cp "temp/MossyBoulder 32x32.png" assets/third_party/props/
cp "temp/Rock_03 32x32.png" assets/third_party/props/
cp "temp/Stone_01 16x16.png" assets/third_party/props/
cp temp/Log_sprite.png assets/third_party/props/
cat > assets/third_party/props/LICENSE.txt <<'EOF'
Commercial-OK per user confirmation 2026-04-21 (free itch.io pack).
Cannot redistribute the raw assets; use within a derivative work only.
EOF

# Fruits + veg (17 individual PNGs)
cp temp/*.png assets/third_party/fruits_veg/ 2>/dev/null || true
# The wildcard above pulls ALL .png from temp root, which includes the rock PNGs.
# Remove the rock PNGs from fruits_veg since they already went to props/:
rm -f "assets/third_party/fruits_veg/Boulder 32x32.png"
rm -f "assets/third_party/fruits_veg/MossyBoulder 32x32.png"
rm -f "assets/third_party/fruits_veg/Rock_03 32x32.png"
rm -f "assets/third_party/fruits_veg/Stone_01 16x16.png"
rm -f assets/third_party/fruits_veg/Log_sprite.png
cat > assets/third_party/fruits_veg/LICENSE.txt <<'EOF'
Commercial-OK per user confirmation 2026-04-21 (free itch.io pack).
Cannot redistribute the raw assets; use within a derivative work only.
EOF
```

Verify: `ls assets/third_party/nature_full/` should list 3 PNGs + 3 text files. `ls assets/third_party/fruits_veg/` should list 17 PNGs + LICENSE.txt.

- [ ] **Step 2: Add `temp/` to gitignore**

Edit `.gitignore`. Append under the existing "Tooling / local-only" section:

```
# Ad-hoc working dir for asset-pack staging before curation. Contents
# move to assets/third_party/ when they're ready to ship.
temp/
```

- [ ] **Step 3: Register curated asset folders in pubspec**

Edit `pubspec.yaml`. Find the `assets:` block under `flutter:` and add (after the existing Pine Hills entry):

```yaml
    - assets/third_party/pine_hills/png/
    - assets/third_party/nature_full/
    - assets/third_party/mushrooms/
    - assets/third_party/potions_onocentaur/
    - assets/third_party/props/
    - assets/third_party/fruits_veg/
    - assets/images/obstacles/
    - assets/images/obstacles/mushroom/
    - assets/images/obstacles/log/
    - assets/images/collectibles/
    - assets/images/collectibles/crystal/
    - assets/audio/
```

(The `assets/audio/` entry already exists — keep it at the end as it was. The new lines slot in before it.)

- [ ] **Step 4: Verify**

Run: `flutter pub get && flutter analyze && flutter test`
Expected: clean, 97 passing (no code changes yet).

- [ ] **Step 5: Commit with explicit file paths (NOT `git add -A`)**

```bash
git add pubspec.yaml .gitignore
git add assets/third_party/nature_full/
git add assets/third_party/mushrooms/
git add assets/third_party/potions_onocentaur/
git add assets/third_party/props/
git add assets/third_party/fruits_veg/
git commit -m "chore: stage pixel-art obstacle/collectible packs + pubspec asset paths"
```

**Do not `git add -A`** — the `Screenshot_20260421_123028.jpg` and M6b store-prep files (`featured_graphic.png`, `feature-graphic.svg`, `assets/images/Screenshots/`) are still untracked and must remain so.

---

## Task 2: Atlas slicer tool

**Files:**
- Create: `tools/build_obstacle_collectible_sprites.dart`

This is a one-shot dev script following the same pattern as `tools/build_gurgles_sprites.dart`. Uses `package:image` (already dev dep) to slice named cells out of source atlases and write them to the curated output dirs.

- [ ] **Step 1: Create the script**

Create `tools/build_obstacle_collectible_sprites.dart`:

```dart
/// One-shot asset curation script for the obstacle + collectible refresh.
///
/// Reads:
///   - assets/third_party/nature_full/global.png  (160x208 atlas, 16x16 cells)
///   - assets/third_party/mushrooms/AnimatedMushroomRed.png  (384x384, 3x3 grid of 128x128 cells, 8 frames)
///   - assets/third_party/props/Log_sprite.png  (256x64 strip, 4 frames of 64x64)
///   - assets/third_party/potions_onocentaur/Potions - Full, Corked.png  (160x400 atlas, 16x24 cells)
///
/// Writes individual PNG files to:
///   - assets/images/obstacles/mushroom/000.png … 007.png
///   - assets/images/obstacles/log/000.png … 003.png
///   - assets/images/collectibles/crystal/<name>.png  (10 files)
///   - assets/images/collectibles/potion.png  (1 file)
///
/// Also copies the fruit/veg individual PNGs from assets/third_party/fruits_veg/
/// to assets/images/collectibles/, normalising filenames.
///
/// Also copies curated rock PNG (Rock_03) and stone PNG (Stone_01) to
/// assets/images/obstacles/ with normalised names.
///
/// Idempotent: deletes + recreates each output subdir on re-run.
/// Run from the repo root: `dart run tools/build_obstacle_collectible_sprites.dart`

import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  _sliceCrystals();
  _sliceMushroomFrames();
  _sliceLogFrames();
  _slicePotion();
  _copyFruitsAndVeg();
  _copyRocksAndStone();
  stdout.writeln('Done.');
}

/// Nature Full atlas layout (empirically verified from global.png inspection):
/// Row 10 (y=160 → y=176) holds the 10 crystals at 16×16 each.
/// Row 0 is the top of the atlas. Each row is 16px tall for the rock/crystal
/// section; the tree section at the top uses taller cells but we don't touch
/// that here.
void _sliceCrystals() {
  const atlasPath = 'assets/third_party/nature_full/global.png';
  const outDir = 'assets/images/collectibles/crystal';
  const crystalRowY = 144; // CALIBRATE: visually verify on first run.
  const cellSize = 16;
  const names = [
    'rose_quartz', 'jasper', 'citrine', 'turquoise', 'tiger_eye',
    'amethyst', 'moonstone', 'sapphire', 'quartz', 'bloodstone',
  ];
  _ensureCleanDir(outDir);
  final atlas = img.decodePng(File(atlasPath).readAsBytesSync())!;
  for (var i = 0; i < names.length; i++) {
    final cell = img.copyCrop(
      atlas,
      x: i * cellSize,
      y: crystalRowY,
      width: cellSize,
      height: cellSize,
    );
    File('$outDir/${names[i]}.png').writeAsBytesSync(img.encodePng(cell));
  }
  stdout.writeln('  crystals: ${names.length} files → $outDir');
}

/// AnimatedMushroomRed.png is 384x384 arranged as 3x3 grid of 128x128 cells.
/// The first 8 cells (row-major: 0-2, 3-5, 6-7) are usable frames; cell 8
/// is empty. Mushroom content sits within the center of each 128x128 cell.
void _sliceMushroomFrames() {
  const atlasPath = 'assets/third_party/mushrooms/AnimatedMushroomRed.png';
  const outDir = 'assets/images/obstacles/mushroom';
  const cellSize = 128;
  _ensureCleanDir(outDir);
  final atlas = img.decodePng(File(atlasPath).readAsBytesSync())!;
  for (var i = 0; i < 8; i++) {
    final row = i ~/ 3;
    final col = i % 3;
    final cell = img.copyCrop(
      atlas,
      x: col * cellSize,
      y: row * cellSize,
      width: cellSize,
      height: cellSize,
    );
    final name = i.toString().padLeft(3, '0');
    File('$outDir/$name.png').writeAsBytesSync(img.encodePng(cell));
  }
  stdout.writeln('  mushroom: 8 frames → $outDir');
}

/// Log_sprite.png is 256x64 — a horizontal strip of 4 frames, each 64x64.
void _sliceLogFrames() {
  const atlasPath = 'assets/third_party/props/Log_sprite.png';
  const outDir = 'assets/images/obstacles/log';
  const cellSize = 64;
  _ensureCleanDir(outDir);
  final atlas = img.decodePng(File(atlasPath).readAsBytesSync())!;
  for (var i = 0; i < 4; i++) {
    final cell = img.copyCrop(
      atlas,
      x: i * cellSize,
      y: 0,
      width: cellSize,
      height: cellSize,
    );
    final name = i.toString().padLeft(3, '0');
    File('$outDir/$name.png').writeAsBytesSync(img.encodePng(cell));
  }
  stdout.writeln('  log: 4 frames → $outDir');
}

/// Onocentaur potion atlas is 160x400 at 16x24 per cell: 10 cols × 16 rows.
/// We extract a single curated potion for V1 — the red heart-potion at (0,0).
void _slicePotion() {
  const atlasPath = 'assets/third_party/potions_onocentaur/Potions - Full, Corked.png';
  const outPath = 'assets/images/collectibles/potion.png';
  File(outPath).parent.createSync(recursive: true);
  final atlas = img.decodePng(File(atlasPath).readAsBytesSync())!;
  final cell = img.copyCrop(atlas, x: 0, y: 0, width: 16, height: 24);
  File(outPath).writeAsBytesSync(img.encodePng(cell));
  stdout.writeln('  potion: 1 file → $outPath');
}

/// Copy the 7 fruits + veg we ship in V1 with normalised filenames.
void _copyFruitsAndVeg() {
  const outDir = 'assets/images/collectibles';
  Directory(outDir).createSync(recursive: true);
  const src = 'assets/third_party/fruits_veg';
  const pairs = [
    // Tier 1 common
    ('Strawberry.png', 'strawberry.png'),
    ('Cherry.png', 'cherry.png'),
    ('Tomato.png', 'tomato.png'),
    // Tier 2 medium
    ('Apple.png', 'apple.png'),
    ('Orange.png', 'orange.png'),
    ('Pumpkin.png', 'pumpkin.png'),
    // Tier 3 rare
    ('GoldenApple.png', 'golden_apple.png'),
  ];
  for (final (srcName, dstName) in pairs) {
    File('$src/$srcName').copySync('$outDir/$dstName');
  }
  stdout.writeln('  fruits/veg: ${pairs.length} files → $outDir');
}

/// Copy Rock_03 + Stone_01 with normalised filenames.
void _copyRocksAndStone() {
  const outDir = 'assets/images/obstacles';
  Directory(outDir).createSync(recursive: true);
  File('assets/third_party/props/Rock_03 32x32.png').copySync('$outDir/rock.png');
  File('assets/third_party/props/Stone_01 16x16.png').copySync('$outDir/stone.png');
  stdout.writeln('  rocks: rock.png + stone.png → $outDir');
}

void _ensureCleanDir(String path) {
  final dir = Directory(path);
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);
}
```

- [ ] **Step 2: Run + verify output**

Run: `dart run tools/build_obstacle_collectible_sprites.dart`
Expected output:
```
  crystals: 10 files → assets/images/collectibles/crystal
  mushroom: 8 frames → assets/images/obstacles/mushroom
  log: 4 frames → assets/images/obstacles/log
  potion: 1 file → assets/images/collectibles/potion.png
  fruits/veg: 7 files → assets/images/collectibles
  rocks: rock.png + stone.png → assets/images/obstacles
Done.
```

Then: `find assets/images/obstacles assets/images/collectibles -name '*.png' | wc -l`
Expected: **32 files** (8 mushroom + 4 log + 2 rocks + 7 fruits + 10 crystals + 1 potion).

- [ ] **Step 3: Visually spot-check a sliced file**

Open `assets/images/collectibles/crystal/rose_quartz.png` in a viewer (or use the editor's image preview). Expected: a small pink/rose-coloured gem shape.
If the image is wrong — e.g. shows a mushroom or flower instead of a crystal — the `crystalRowY` constant in the script needs recalibration. Open `assets/third_party/nature_full/global.png` in a 1:1 viewer, count pixel rows from the top to where the crystal row starts, update `crystalRowY`, re-run the script. **Don't commit wrong slices.**

Open `assets/images/obstacles/mushroom/000.png`. Expected: the red-cap mushroom sprite. If the image is empty or cut off, the 128×128 cell size or frame indexing is wrong.

Open `assets/images/obstacles/log/000.png`. Expected: a log with a small leaf. If the log appears truncated, `cellSize=64` is wrong.

Open `assets/images/collectibles/potion.png`. Expected: a small corked bottle.

- [ ] **Step 4: Commit**

```bash
git add tools/build_obstacle_collectible_sprites.dart assets/images/obstacles/ assets/images/collectibles/
git commit -m "feat: slice obstacle + collectible sprites from staged atlases"
```

---

## Task 3: Extend `Obstacle` to support animated sprites (TDD)

**Files:**
- Modify: `lib/components/obstacle.dart`
- Modify: `test/obstacle_hitbox_test.dart` (only if references to `root` need updating)
- Create: `test/obstacle_animation_loading_test.dart`

### Step 1: Write the failing test

Create `test/obstacle_animation_loading_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/obstacle.dart';

void main() {
  group('Obstacle sprite-source config', () {
    test('stone is a static sprite', () {
      expect(Obstacle.isAnimated(ObstacleKind.stone), isFalse);
    });
    test('rock is a static sprite', () {
      expect(Obstacle.isAnimated(ObstacleKind.rock), isFalse);
    });
    test('mushroom is animated', () {
      expect(Obstacle.isAnimated(ObstacleKind.mushroom), isTrue);
    });
    test('log is animated', () {
      expect(Obstacle.isAnimated(ObstacleKind.log), isTrue);
    });

    test('animated kinds have valid frame count + stepTime', () {
      for (final kind in ObstacleKind.values) {
        if (!Obstacle.isAnimated(kind)) continue;
        final cfg = Obstacle.animationFor(kind);
        expect(cfg.frameCount, greaterThanOrEqualTo(2));
        expect(cfg.stepTime, greaterThan(0));
        expect(cfg.folder, isNotEmpty);
      }
    });
  });
}
```

### Step 2: Run — expect compile-failure

Run: `flutter test test/obstacle_animation_loading_test.dart`
Expected: compile errors — `ObstacleKind.stone` undefined, `Obstacle.isAnimated` undefined.

### Step 3: Rewrite `lib/components/obstacle.dart`

Replace the entire file contents with:

```dart
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

/// Obstacle kinds rolled by [ObstacleManager]. `stone` replaces the old
/// `root` kind — a small 16×16 tripping stone. `mushroom` + `log` are
/// animated sprites (SpriteAnimationComponent); `stone` + `rock` are
/// static (SpriteComponent).
enum ObstacleKind { stone, rock, mushroom, log }

class Obstacle extends PositionComponent with CollisionCallbacks {
  final ObstacleKind kind;
  double scrollSpeed;

  Obstacle({
    required this.kind,
    required Vector2 position,
    required this.scrollSpeed,
    double sizeScale = 1.0,
  }) : super(
          position: position,
          size: _sizeFor(kind) * sizeScale,
          anchor: Anchor.bottomLeft,
        );

  static Vector2 _sizeFor(ObstacleKind k) => switch (k) {
        ObstacleKind.stone => Vector2(40, 28),
        ObstacleKind.rock => Vector2(72, 60),
        ObstacleKind.mushroom => Vector2(72, 72),
        ObstacleKind.log => Vector2(140, 72),
      };

  static String _staticSpriteFor(ObstacleKind k) => switch (k) {
        ObstacleKind.stone => 'obstacles/stone.png',
        ObstacleKind.rock => 'obstacles/rock.png',
        _ => throw StateError('$k has no static sprite (it is animated)'),
      };

  @visibleForTesting
  static bool isAnimated(ObstacleKind k) => switch (k) {
        ObstacleKind.stone || ObstacleKind.rock => false,
        ObstacleKind.mushroom || ObstacleKind.log => true,
      };

  @visibleForTesting
  static ({String folder, int frameCount, double stepTime}) animationFor(
    ObstacleKind k,
  ) =>
      switch (k) {
        ObstacleKind.mushroom => (
            folder: 'obstacles/mushroom',
            frameCount: 8,
            stepTime: 0.12,
          ),
        ObstacleKind.log => (
            folder: 'obstacles/log',
            frameCount: 4,
            stepTime: 0.15,
          ),
        _ => throw StateError('$k is not animated'),
      };

  /// Hitbox as fractions of the sprite bounds. Platformers feel fair when
  /// grazes don't register as hits, so hitboxes are intentionally smaller
  /// than the visual.
  @visibleForTesting
  static ({Vector2 pos, Vector2 size}) hitboxFor(ObstacleKind k, Vector2 s) =>
      switch (k) {
        // Stone: small, flat, low to ground.
        ObstacleKind.stone => (
            pos: Vector2(s.x * 0.15, s.y * 0.35),
            size: Vector2(s.x * 0.70, s.y * 0.60),
          ),
        // Rock: roughly elliptical, approximated with a middle rect.
        ObstacleKind.rock => (
            pos: Vector2(s.x * 0.10, s.y * 0.25),
            size: Vector2(s.x * 0.80, s.y * 0.70),
          ),
        // Mushroom: narrow danger column around cap+stem.
        ObstacleKind.mushroom => (
            pos: Vector2(s.x * 0.25, s.y * 0.30),
            size: Vector2(s.x * 0.45, s.y * 0.65),
          ),
        // Log: wide, flat. Hugs the full trunk body.
        ObstacleKind.log => (
            pos: Vector2(s.x * 0.05, s.y * 0.25),
            size: Vector2(s.x * 0.90, s.y * 0.60),
          ),
      };

  @override
  Future<void> onLoad() async {
    if (isAnimated(kind)) {
      final cfg = animationFor(kind);
      final sprites = <Sprite>[];
      for (var i = 0; i < cfg.frameCount; i++) {
        final name = i.toString().padLeft(3, '0');
        sprites.add(await Sprite.load('${cfg.folder}/$name.png'));
      }
      final anim = SpriteAnimation.spriteList(sprites, stepTime: cfg.stepTime);
      add(SpriteAnimationComponent(animation: anim, size: size));
    } else {
      final sprite = await Sprite.load(_staticSpriteFor(kind));
      add(SpriteComponent(sprite: sprite, size: size));
    }
    final hb = hitboxFor(kind, size);
    add(RectangleHitbox(size: hb.size, position: hb.pos));
  }

  @override
  void update(double dt) {
    super.update(dt);
    x -= scrollSpeed * dt;
    if (x + width < -50) removeFromParent();
  }
}
```

### Step 4: Verify new tests pass

Run: `flutter test test/obstacle_animation_loading_test.dart`
Expected: 5 PASS.

### Step 5: Run the existing obstacle hitbox test

Run: `flutter test test/obstacle_hitbox_test.dart`
Expected: PASS — the test iterates `ObstacleKind.values` so it automatically covers the new `stone` kind + no longer references the removed `root`. No code changes to that file.

### Step 6: Full test sweep

Run: `flutter analyze && flutter test`
Expected: clean; **102 passing** (97 previous + 5 new animation tests).

### Step 7: Commit

```bash
git add lib/components/obstacle.dart test/obstacle_animation_loading_test.dart
git commit -m "feat(obstacle): drop root, add stone, support animated mushroom + log"
```

---

## Task 4: Extend `Collectible` for explicit sprite path + new kinds (TDD)

**Files:**
- Modify: `lib/components/collectible.dart`
- Modify: `test/collectible_hitbox_test.dart`
- Create: `test/collectible_kind_config_test.dart`

### Step 1: Write the failing test

Create `test/collectible_kind_config_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/collectible.dart';

void main() {
  group('CollectibleKind config', () {
    test('enum has exactly 5 values', () {
      expect(CollectibleKind.values.length, 5);
      expect(CollectibleKind.values, contains(CollectibleKind.fruitCommon));
      expect(CollectibleKind.values, contains(CollectibleKind.fruitMedium));
      expect(CollectibleKind.values, contains(CollectibleKind.fruitRare));
      expect(CollectibleKind.values, contains(CollectibleKind.crystal));
      expect(CollectibleKind.values, contains(CollectibleKind.potion));
    });

    test('points strictly ordered common < medium < rare < crystal < potion', () {
      expect(Collectible.pointsFor(CollectibleKind.fruitCommon),
          lessThan(Collectible.pointsFor(CollectibleKind.fruitMedium)));
      expect(Collectible.pointsFor(CollectibleKind.fruitMedium),
          lessThan(Collectible.pointsFor(CollectibleKind.fruitRare)));
      expect(Collectible.pointsFor(CollectibleKind.fruitRare),
          lessThan(Collectible.pointsFor(CollectibleKind.crystal)));
      expect(Collectible.pointsFor(CollectibleKind.crystal),
          lessThan(Collectible.pointsFor(CollectibleKind.potion)));
    });

    test('fruitCommon has at least 2 sprite variants', () {
      expect(Collectible.spritePathsFor(CollectibleKind.fruitCommon).length,
          greaterThanOrEqualTo(2));
    });

    test('fruitRare has exactly 1 variant (golden apple)', () {
      final paths = Collectible.spritePathsFor(CollectibleKind.fruitRare);
      expect(paths.length, 1);
      expect(paths.first, contains('golden_apple'));
    });

    test('crystal has at least 5 variants', () {
      expect(Collectible.spritePathsFor(CollectibleKind.crystal).length,
          greaterThanOrEqualTo(5));
    });

    test('potion has exactly 1 variant for V1', () {
      expect(Collectible.spritePathsFor(CollectibleKind.potion).length, 1);
    });

    test('only potion grants the spill-drain bonus', () {
      for (final kind in CollectibleKind.values) {
        expect(Collectible.grantsSpillDrain(kind),
            kind == CollectibleKind.potion,
            reason: '$kind grantsSpillDrain wrong');
      }
    });
  });
}
```

### Step 2: Update `test/collectible_hitbox_test.dart`

Replace the hardcoded reference-size list (currently references the old `herb/hops/potion` sizes) with the new set:

```dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/collectible.dart';

void main() {
  group('Collectible hitbox is a strict subset of the sprite rect', () {
    final sizes = [
      Vector2(40, 40),   // fruitCommon reference size
      Vector2(44, 44),   // fruitMedium
      Vector2(48, 48),   // fruitRare (golden apple)
      Vector2(36, 36),   // crystal (small gems)
      Vector2(32, 48),   // potion (tall bottle)
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

### Step 3: Run — expect failures

Run: `flutter test test/collectible_kind_config_test.dart test/collectible_hitbox_test.dart`
Expected: compile failures (new enum values + methods don't exist yet).

### Step 4: Rewrite `lib/components/collectible.dart`

Replace the entire file contents with:

```dart
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show VoidCallback, visibleForTesting;
import 'gurgles.dart';

/// Collectible tiers, rolled with weighted RNG by [CollectibleManager]:
/// - fruitCommon: strawberry / cherry / tomato (~10 pts, ground tier).
/// - fruitMedium: apple / orange / pumpkin (~50 pts, partial-jump tier).
/// - fruitRare: golden apple (~100 pts, partial-jump tier).
/// - crystal: 10 gem variants (~150 pts, full-jump tier).
/// - potion: single Onocentaur bottle (~200 pts, full-jump tier, grants
///   1-second 4× spill-drain bonus).
enum CollectibleKind { fruitCommon, fruitMedium, fruitRare, crystal, potion }

class Collectible extends PositionComponent with CollisionCallbacks {
  final CollectibleKind kind;
  final String spritePath;
  final void Function(int points, Vector2 worldPos) onPickup;
  final VoidCallback? _grantPotionBonus;
  double scrollSpeed;
  bool _consumed = false;

  Collectible({
    required this.kind,
    required this.spritePath,
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

  static Vector2 _sizeFor(CollectibleKind k) => switch (k) {
        CollectibleKind.fruitCommon => Vector2(40, 40),
        CollectibleKind.fruitMedium => Vector2(44, 44),
        CollectibleKind.fruitRare => Vector2(48, 48),
        CollectibleKind.crystal => Vector2(36, 36),
        CollectibleKind.potion => Vector2(32, 48),
      };

  /// List of sprite asset paths available for each kind. Manager picks one
  /// uniformly at random per spawn, so kinds with multiple entries (e.g.
  /// fruitCommon, crystal) get visual variety for free while behaviour
  /// stays kind-driven.
  @visibleForTesting
  static List<String> spritePathsFor(CollectibleKind k) => switch (k) {
        CollectibleKind.fruitCommon => const [
            'collectibles/cherry.png',
            'collectibles/strawberry.png',
            'collectibles/tomato.png',
          ],
        CollectibleKind.fruitMedium => const [
            'collectibles/apple.png',
            'collectibles/orange.png',
            'collectibles/pumpkin.png',
          ],
        CollectibleKind.fruitRare => const [
            'collectibles/golden_apple.png',
          ],
        CollectibleKind.crystal => const [
            'collectibles/crystal/rose_quartz.png',
            'collectibles/crystal/jasper.png',
            'collectibles/crystal/citrine.png',
            'collectibles/crystal/turquoise.png',
            'collectibles/crystal/tiger_eye.png',
            'collectibles/crystal/amethyst.png',
            'collectibles/crystal/moonstone.png',
            'collectibles/crystal/sapphire.png',
            'collectibles/crystal/quartz.png',
            'collectibles/crystal/bloodstone.png',
          ],
        CollectibleKind.potion => const ['collectibles/potion.png'],
      };

  static int pointsFor(CollectibleKind k) => switch (k) {
        CollectibleKind.fruitCommon => 10,
        CollectibleKind.fruitMedium => 50,
        CollectibleKind.fruitRare => 100,
        CollectibleKind.crystal => 150,
        CollectibleKind.potion => 200,
      };

  @visibleForTesting
  static bool grantsSpillDrain(CollectibleKind k) => k == CollectibleKind.potion;

  /// Active hitbox for pickup detection. 90% of sprite, centered via 5% inset
  /// on each side.
  @visibleForTesting
  static ({Vector2 pos, Vector2 size}) hitboxFor(Vector2 spriteSize) => (
        pos: Vector2(spriteSize.x * 0.05, spriteSize.y * 0.05),
        size: Vector2(spriteSize.x * 0.9, spriteSize.y * 0.9),
      );

  @override
  Future<void> onLoad() async {
    final sprite = await Sprite.load(spritePath);
    add(SpriteComponent(sprite: sprite, size: size));
    final hb = hitboxFor(size);
    add(RectangleHitbox(size: hb.size, position: hb.pos));
  }

  @override
  void update(double dt) {
    super.update(dt);
    x -= scrollSpeed * dt;
    if (x + width < -50) removeFromParent();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (_consumed || other is! Gurgles) return;
    _consumed = true;
    onPickup(pointsFor(kind), position.clone());
    if (grantsSpillDrain(kind)) {
      _grantPotionBonus?.call();
    }
    removeFromParent();
  }
}
```

### Step 5: Verify new tests pass

Run: `flutter test test/collectible_kind_config_test.dart test/collectible_hitbox_test.dart`
Expected: all green.

### Step 6: Commit

```bash
git add lib/components/collectible.dart test/collectible_hitbox_test.dart test/collectible_kind_config_test.dart
git commit -m "feat(collectible): add fruitRare + crystal kinds, rename herb/hops, sprite variants per kind"
```

---

## Task 5: Update `SparkleBurst` config for new kinds

**Files:**
- Modify: `lib/components/sparkle_burst.dart`
- Modify: `test/sparkle_burst_test.dart`

### Step 1: Update the test first

Replace the contents of `test/sparkle_burst_test.dart` with:

```dart
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/collectible.dart';
import 'package:hold_the_hooch/components/sparkle_burst.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SparkleBurst.configFor', () {
    // Ordering for the new 5-kind roster:
    // fruitCommon < fruitMedium < fruitRare < crystal < potion
    test('particle counts weakly increase along the tier order', () {
      final order = [
        CollectibleKind.fruitCommon,
        CollectibleKind.fruitMedium,
        CollectibleKind.fruitRare,
        CollectibleKind.crystal,
        CollectibleKind.potion,
      ];
      for (var i = 1; i < order.length; i++) {
        expect(SparkleBurst.configFor(order[i]).count,
            greaterThanOrEqualTo(SparkleBurst.configFor(order[i - 1]).count),
            reason: '${order[i]} count should be ≥ ${order[i - 1]}');
      }
    });

    test('radii weakly increase along the tier order', () {
      final order = [
        CollectibleKind.fruitCommon,
        CollectibleKind.fruitMedium,
        CollectibleKind.fruitRare,
        CollectibleKind.crystal,
        CollectibleKind.potion,
      ];
      for (var i = 1; i < order.length; i++) {
        expect(SparkleBurst.configFor(order[i]).radius,
            greaterThanOrEqualTo(SparkleBurst.configFor(order[i - 1]).radius));
      }
    });

    test('colours are distinct across kinds', () {
      final colours = {
        for (final k in CollectibleKind.values)
          k: SparkleBurst.configFor(k).colour,
      };
      final unique = colours.values.toSet();
      expect(unique.length, CollectibleKind.values.length,
          reason: 'colours not all unique: $colours');
    });
  });

  group('SparkleBurst.emit', () {
    test('adds a ParticleSystemComponent for every kind without throwing',
        () async {
      final game = FlameGame();
      game.onGameResize(Vector2(400, 800));
      await game.onLoad();
      await game.ready();

      for (final kind in CollectibleKind.values) {
        final comp = SparkleBurst.emit(kind, Vector2(100, 100));
        game.add(comp);
        await game.ready();
        expect(game.children.contains(comp), isTrue,
            reason: '$kind component not in game.children');
      }
    });
  });
}
```

### Step 2: Run — expect failures

Run: `flutter test test/sparkle_burst_test.dart`
Expected: compile errors — `CollectibleKind.fruitCommon` etc. referenced in configFor's switch that doesn't cover the new cases.

### Step 3: Update `lib/components/sparkle_burst.dart`

Replace the `configFor` switch and the potion halo gate in `emit` so they cover all 5 new kinds:

```dart
  /// Build a self-removing ParticleSystemComponent positioned at [at].
  static ParticleSystemComponent emit(CollectibleKind kind, Vector2 at) {
    final cfg = configFor(kind);
    final particles = <Particle>[
      for (var i = 0; i < cfg.count; i++) _sparkle(cfg, at),
    ];
    if (kind == CollectibleKind.potion) {
      particles.add(_haloBurst(at, const Color(0xFF00BFFF)));
    } else if (kind == CollectibleKind.crystal) {
      particles.add(_haloBurst(at, const Color(0xFFB266FF)));
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
        CollectibleKind.fruitCommon => (
            count: 6,
            radius: 4.0,
            colour: const Color(0xFFE57373), // red (strawberry/cherry/tomato)
            lifespan: 0.5,
          ),
        CollectibleKind.fruitMedium => (
            count: 8,
            radius: 5.0,
            colour: const Color(0xFFFF9800), // orange (apple/orange/pumpkin)
            lifespan: 0.6,
          ),
        CollectibleKind.fruitRare => (
            count: 10,
            radius: 6.0,
            colour: const Color(0xFFFFD700), // gold (golden apple)
            lifespan: 0.7,
          ),
        CollectibleKind.crystal => (
            count: 14,
            radius: 7.0,
            colour: const Color(0xFFB266FF), // purple (gem/amethyst)
            lifespan: 0.8,
          ),
        CollectibleKind.potion => (
            count: 16,
            radius: 8.0,
            colour: const Color(0xFF00BFFF), // blue (Onocentaur potion)
            lifespan: 1.0,
          ),
      };
```

Then rename `_potionHalo` to a parameterized `_haloBurst` helper (the only change is taking a colour argument instead of hardcoding blue):

Find:
```dart
  static Particle _potionHalo(Vector2 at) {
    const haloLifespan = 0.4;
    const haloMaxRadius = 60.0;
    const haloMaxAlpha = 180;
    const haloColour = Color(0xFF00BFFF);
```

Replace with:
```dart
  static Particle _haloBurst(Vector2 at, Color haloColour) {
    const haloLifespan = 0.4;
    const haloMaxRadius = 60.0;
    const haloMaxAlpha = 180;
```

Leave the rest of the method body unchanged — it already references the local `haloColour` variable.

### Step 4: Verify

Run: `flutter analyze && flutter test`
Expected: clean; all tests pass.

### Step 5: Commit

```bash
git add lib/components/sparkle_burst.dart test/sparkle_burst_test.dart
git commit -m "feat(sparkle): add fruitRare/crystal configs, purple halo for crystals"
```

---

## Task 6: Update `CollectibleManager` for new kinds + variant RNG

**Files:**
- Modify: `lib/systems/collectible_manager.dart`

### Step 1: Rewrite the manager

Replace `lib/systems/collectible_manager.dart` with:

```dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show VoidCallback;
import '../components/collectible.dart';

/// Spawns collectibles from just off the right edge at varying heights.
/// Weighted-kind roll + per-kind sprite-variant RNG.
class CollectibleManager extends Component {
  final double Function() scrollSpeedProvider;
  final double Function() worldWidthProvider;
  final double groundY;
  final double sizeScale;
  final void Function(int points, Vector2 worldPos, CollectibleKind kind) onPickup;
  final VoidCallback? onPotionBonus;
  final Random _rng;

  double _timeToNext = 3.0;

  CollectibleManager({
    required this.scrollSpeedProvider,
    required this.worldWidthProvider,
    required this.groundY,
    required this.onPickup,
    this.onPotionBonus,
    this.sizeScale = 1.0,
    Random? rng,
  }) : _rng = rng ?? Random();

  @override
  void update(double dt) {
    super.update(dt);
    _timeToNext -= dt;
    if (_timeToNext <= 0) {
      _spawn();
      final speed = scrollSpeedProvider();
      final speedNorm = speed / 280.0;
      _timeToNext = (2.4 + _rng.nextDouble() * 2.0) / speedNorm;
    }
  }

  /// Weighted kind roll:
  ///   fruitCommon  55%
  ///   fruitMedium  25%
  ///   fruitRare    10%
  ///   crystal       5%
  ///   potion        5%
  CollectibleKind _rollKind() {
    final r = _rng.nextDouble();
    if (r < 0.55) return CollectibleKind.fruitCommon;
    if (r < 0.80) return CollectibleKind.fruitMedium;
    if (r < 0.90) return CollectibleKind.fruitRare;
    if (r < 0.95) return CollectibleKind.crystal;
    return CollectibleKind.potion;
  }

  /// Height tiers tuned so Gurgles can reach each with the appropriate
  /// jump effort: peak-jump ~208px above ground, partial jump ~120px.
  double _heightForKind(CollectibleKind k) {
    return switch (k) {
      CollectibleKind.fruitCommon => groundY - 50.0 * sizeScale,
      CollectibleKind.fruitMedium => groundY - 120.0 * sizeScale,
      CollectibleKind.fruitRare => groundY - 120.0 * sizeScale,
      CollectibleKind.crystal => groundY - 180.0 * sizeScale,
      CollectibleKind.potion => groundY - 180.0 * sizeScale,
    };
  }

  void _spawn() {
    final kind = _rollKind();
    final variants = Collectible.spritePathsFor(kind);
    final spritePath = variants[_rng.nextInt(variants.length)];
    final c = Collectible(
      kind: kind,
      spritePath: spritePath,
      position: Vector2(worldWidthProvider() + 80, _heightForKind(kind)),
      scrollSpeed: scrollSpeedProvider(),
      onPickup: (pts, at) => onPickup(pts, at, kind),
      onPotionBonus: onPotionBonus,
      sizeScale: sizeScale,
    );
    parent?.add(c);
  }
}
```

### Step 2: Verify

Run: `flutter analyze && flutter test`
Expected: clean; all tests pass.

### Step 3: Commit

```bash
git add lib/systems/collectible_manager.dart
git commit -m "feat(collectible-manager): weighted 5-kind roll + per-kind sprite-variant RNG"
```

---

## Task 7: Update `ObstacleManager` for new kinds

**Files:**
- Modify: `lib/systems/obstacle_manager.dart`

Currently the manager picks a kind uniformly from `ObstacleKind.values`. With the new 4-kind roster (`stone / rock / mushroom / log`), uniform is fine — but explicitly spelling out the roll keeps future tuning easy. The refactor is also needed because the existing code was written against the 4-kind-including-root enum; we want to give stone a slightly higher weight (it's small and frequent in mid-speed running games).

### Step 1: Rewrite the manager

Replace `lib/systems/obstacle_manager.dart` with:

```dart
import 'dart:math';
import 'package:flame/components.dart';
import '../components/obstacle.dart';

/// Spawns obstacles at speed-dependent intervals from just off the right edge.
class ObstacleManager extends Component {
  final double Function() scrollSpeedProvider;
  final double Function() worldWidthProvider;
  final double groundY;
  final double sizeScale;
  final Random _rng;

  double _timeToNext = 1.5;

  ObstacleManager({
    required this.scrollSpeedProvider,
    required this.worldWidthProvider,
    required this.groundY,
    this.sizeScale = 1.0,
    Random? rng,
  }) : _rng = rng ?? Random();

  @override
  void update(double dt) {
    super.update(dt);
    _timeToNext -= dt;
    if (_timeToNext <= 0) {
      _spawn();
      final speed = scrollSpeedProvider();
      final minGap = 80.0 / (speed / 280.0);
      final maxGap = 200.0 / (speed / 280.0);
      _timeToNext = (minGap + _rng.nextDouble() * (maxGap - minGap)) / 100.0 + 0.6;
    }
  }

  /// Weighted obstacle roll:
  ///   stone     35%  (small, frequent)
  ///   rock      25%
  ///   mushroom  20%
  ///   log       20%
  ObstacleKind _rollKind() {
    final r = _rng.nextDouble();
    if (r < 0.35) return ObstacleKind.stone;
    if (r < 0.60) return ObstacleKind.rock;
    if (r < 0.80) return ObstacleKind.mushroom;
    return ObstacleKind.log;
  }

  void _spawn() {
    final ob = Obstacle(
      kind: _rollKind(),
      position: Vector2(worldWidthProvider() + 80, groundY),
      scrollSpeed: scrollSpeedProvider(),
      sizeScale: sizeScale,
    );
    parent?.add(ob);
  }
}
```

### Step 2: Verify

Run: `flutter analyze && flutter test`
Expected: clean; all tests pass.

### Step 3: Commit

```bash
git add lib/systems/obstacle_manager.dart
git commit -m "feat(obstacle-manager): weighted 4-kind roll (stone 35% / rock 25% / mushroom 20% / log 20%)"
```

---

## Task 8: Sanity-check GameScene references

**Files:**
- Check (may not modify): `lib/scenes/game_scene.dart`

### Step 1: Grep for removed enum names

Run: `grep -rn "CollectibleKind.herb\|CollectibleKind.hops\|ObstacleKind.root" lib/ test/`
Expected: **zero results**. If any show up, they're residual references that didn't get updated in Tasks 3/4/5/6/7. Update them. (Likely zero — the component + manager rewrites should be comprehensive, and `game_scene.dart` refers to `CollectibleKind` only via the `onPickup` callback signature which is type-level, not value-level.)

### Step 2: Full sweep

Run: `flutter analyze && flutter test`
Expected: clean; all tests pass.

### Step 3: Commit only if Step 1 found anything

If residual references were fixed:
```bash
git add lib/scenes/game_scene.dart  # or whichever file had refs
git commit -m "chore: update residual CollectibleKind/ObstacleKind references"
```

Otherwise: skip; no commit needed.

---

## Task 9: Device playtest + tune

**Goal:** install the new build on the user's Samsung S26 Ultra and walk through every new kind to spot visual or gameplay issues.

### Step 1: Rebuild + install

```bash
flutter build apk --debug
flutter install -d adb-R5GL12X3ZXH-fontbc._adb-tls-connect._tcp --debug
```

### Step 2: On-device checklist

Play at least one ~60-second run. Watch for and note:

| Check | What to look for | Knob to tune |
|---|---|---|
| **Fruit common visibility** | Strawberries/cherries/tomatoes pop against the dusk sky | Size in `Collectible._sizeFor`; sparkle colour |
| **Fruit common hit rate** | Easy grab at ground level, no false collisions | `CollectibleManager._heightForKind(fruitCommon)` y-offset |
| **Fruit medium reach** | Requires a short jump; feels fair | height y-offset + Gurgles jump arc |
| **Fruit rare (golden apple)** | Appears rarely enough to feel special | `_rollKind` threshold (currently 10%) |
| **Crystal appearance** | Purple/blue variants visible against parallax | Size (36×36); may need bump to 40×40 |
| **Crystal rarity** | Feels rare-but-obtainable (~5% of rolls) | `_rollKind` threshold |
| **Potion clarity** | Onocentaur bottle reads clearly at pickup size | Size (32×48) |
| **Potion spill-drain** | Still works — pickup while in spill zone, drain happens | No change expected |
| **Stone obstacle** | Small, easy to jump over | `_sizeFor(stone)` (currently 40×28); hitbox |
| **Rock obstacle** | Mid-size; bigger hitbox than stone | `_sizeFor(rock)` + hitbox |
| **Mushroom animation** | 8-frame bob plays smoothly, not too fast/slow | `animationFor(mushroom).stepTime` (currently 0.12s) |
| **Log animation** | 4-frame sway plays naturally | `animationFor(log).stepTime` (currently 0.15s) |
| **Spawn balance** | No single kind feels overwhelming/absent | `_rollKind` weights in each manager |
| **Sparkle colour legibility** | Red/orange/gold/purple/blue pop against dusk sky | `SparkleBurst.configFor.colour` |

### Step 3: Commit tuning changes

If any values changed:

```bash
git add -A   # or be explicit if M6b assets still untracked
git commit -m "tune: on-device playtest adjustments for obstacle/collectible refresh"
```

If nothing changed: skip; no commit needed.

---

## Task 10: Documentation sweep

**Files:**
- Modify: `docs/STATUS.md`
- Modify: `docs/ROADMAP.md`
- Modify: `docs/ART-GUIDE.md`

### Step 1: STATUS.md

Update the `_Last updated_` header to add the new milestone closure.

In the **What's playable today** list, rewrite the line about obstacles + collectibles. Currently it reads (two separate bullets, lines 21-22 approx):

```
- Obstacles (root / rock / mushroom / log) spawn at speed-dependent intervals...
- Collectibles (herb / hops / potion) spawn at three reachable height tiers...
```

Replace with:

```
- **Obstacles** spawn at speed-dependent intervals and end the run on collision. Four kinds with weighted RNG: stone 35% (small tripping stones), rock 25%, mushroom 20% (8-frame animated bob), log 20% (4-frame animated sway). Per-obstacle tight hitboxes are authored (see `lib/components/obstacle.dart:hitboxFor`).
- **Collectibles** spawn at four reachable height tiers with weighted RNG: fruitCommon 55% (ground — cherry / strawberry / tomato, 3 visual variants), fruitMedium 25% (partial jump — apple / orange / pumpkin), fruitRare 10% (partial jump — golden apple, single variant), crystal 5% (full jump — 10 gem variants from the Nature Full pack), potion 5% (full jump — Onocentaur bottle, grants 1s 4× spill-drain). Points scale 10 / 50 / 100 / 150 / 200 per tier.
```

In the **Milestone progress § M5 — Polish & assets** bullet, add to the existing paragraph:

```
, obstacle + collectible refresh (M5a, `feat/obstacle-collectible-refresh`) — pixel-art replacements for all obstacles + collectibles plus new fruitRare + crystal tiers, sliced from the Nature Full / Onocentaur / Animated Mushrooms / individual fruit-veg packs staged in `assets/third_party/`
```

In the **Known issues & deferred work** table, mark any related stale rows as closed with a "**Closed 2026-04-21**" note.

Append this new Gotcha to the list:

```
- **Slicing atlases at 16×16 requires exact-pixel calibration.** The Nature Full atlas crystal row sits at y=144 (empirically — verify by opening `global.png` in a 1:1 viewer). If a future pack is added, the slice script `tools/build_obstacle_collectible_sprites.dart` hard-codes cell origins — visually spot-check each output on first run, adjust constants, rerun.
```

### Step 2: ROADMAP.md

In **M5a — Visuals**, find the unchecked bullet added earlier this session:

```
- [ ] **Obstacle + collectible visual refresh.** Current obstacle art ...
```

Replace with the checked version:

```markdown
- [x] **Obstacle + collectible visual refresh** — dropped `root` obstacle, added `stone`. Renamed `herb`/`hops` collectibles to `fruitCommon`/`fruitMedium`, added new `fruitRare` + `crystal` tiers (5 kinds total). Mushroom + log now animated (8-frame bob / 4-frame sway). Sprites sliced from Nature Full + Onocentaur potions + Animated Mushroom packs + individual fruit/veg files — see [OBSTACLE-COLLECTIBLE-ASSETS.md](../docs/OBSTACLE-COLLECTIBLE-ASSETS.md) and [docs/superpowers/plans/2026-04-21-obstacle-collectible-refresh.md](superpowers/plans/2026-04-21-obstacle-collectible-refresh.md).
```

### Step 3: ART-GUIDE.md

After the "Current backdrop art" and "Current app icon" sections already present in ART-GUIDE.md, append:

```markdown
## Current obstacle + collectible art

**As of 2026-04-21** the obstacles and collectibles use pixel art from several staged packs (all commercial-OK; see [OBSTACLE-COLLECTIBLE-ASSETS.md](OBSTACLE-COLLECTIBLE-ASSETS.md) for the full inventory + licences):

- **Obstacles** (4 kinds at `assets/images/obstacles/`):
  - `stone.png` (16×16) — sourced from individual pixel-art rock pack.
  - `rock.png` (32×32, Rock_03) — same pack.
  - `mushroom/000.png…007.png` — 8-frame animated bob sliced from `AnimatedMushroomRed.png` in `assets/third_party/mushrooms/`.
  - `log/000.png…003.png` — 4-frame animated sway sliced from `Log_sprite.png` in `assets/third_party/props/`.
- **Collectibles** (5 kinds at `assets/images/collectibles/`):
  - `fruitCommon` variants: `cherry.png`, `strawberry.png`, `tomato.png`.
  - `fruitMedium` variants: `apple.png`, `orange.png`, `pumpkin.png`.
  - `fruitRare`: `golden_apple.png` (single variant).
  - `crystal/` variants (10): sliced from the Nature Full atlas row 10 — `rose_quartz`, `jasper`, `citrine`, `turquoise`, `tiger_eye`, `amethyst`, `moonstone`, `sapphire`, `quartz`, `bloodstone`.
  - `potion.png` — single curated Onocentaur red heart-potion.

Slicing + curation lives in `tools/build_obstacle_collectible_sprites.dart` (one-shot Dart + `package:image` script). Run `dart run tools/build_obstacle_collectible_sprites.dart` from the repo root to regenerate outputs.

V2 expansion candidates still in `assets/third_party/` (not yet wired):
- Animated mushroom colour variants (pink + blue) — for rare-variant RNG on the `mushroom` obstacle.
- Remaining 10 fruits/veg (carrot, banana, avocado, garlic, onions) — for more common/medium variety.
- Nature Full trees / leaves / flowers / bushes / butterflies / bugs — for future ambient decoration, moving pickups, or animated obstacles.
- VariPixels PotionsPack — alternative potion library if Onocentaur's styling ever needs to change.
```

### Step 4: Verify + commit

Run: `flutter analyze && flutter test`
Expected: clean; all tests pass (docs don't affect test count).

Commit:
```bash
git add docs/STATUS.md docs/ROADMAP.md docs/ART-GUIDE.md
git commit -m "docs: sync STATUS/ROADMAP/ART-GUIDE for obstacle+collectible refresh"
```

---

## Self-review

**Spec coverage:**
- ✅ Drop `root`, add `stone` — Task 3.
- ✅ Add `crystal` rare collectible tier — Task 4.
- ✅ Fruits/veg as collectibles with tiers — Task 4 (`fruitCommon`/`fruitMedium`/`fruitRare`).
- ✅ Onocentaur potion for `potion` art — Task 2 (slicer) + Task 4 (wiring).
- ✅ Mushroom + log animated — Task 2 (slicer) + Task 3 (component).
- ✅ Sparkle colours distinct per kind — Task 5.
- ✅ Spawn-weight tuning — Tasks 6 + 7.
- ✅ Tests updated — Tasks 3, 4, 5.
- ✅ Device playtest — Task 9.
- ✅ Docs sweep — Task 10.

**Placeholder scan:** none — every code block is concrete, every slice spec has a named constant, every file path is exact.

**Type consistency:**
- `CollectibleKind` spelled as `fruitCommon / fruitMedium / fruitRare / crystal / potion` everywhere (Task 4 enum definition + Task 5 SparkleBurst + Task 6 manager).
- `ObstacleKind` spelled as `stone / rock / mushroom / log` everywhere.
- `Obstacle.hitboxFor`, `Obstacle.isAnimated`, `Obstacle.animationFor` signatures match across Tasks 3 + any downstream test.
- `Collectible.pointsFor`, `Collectible.spritePathsFor`, `Collectible.grantsSpillDrain`, `Collectible.hitboxFor` signatures consistent.

## Execution handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-21-obstacle-collectible-refresh.md`. Two execution options:

1. **Subagent-Driven (recommended)** — dispatch a fresh subagent per task, two-stage review between tasks. Same cadence as the gnome-animations and Pine Hills branches. ~10 dispatch cycles.

2. **Inline** — execute tasks in this session with checkpoints.

Which approach?
