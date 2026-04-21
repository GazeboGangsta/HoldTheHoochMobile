// One-shot asset curation script for the obstacle + collectible refresh.
//
// Reads:
//   - assets/third_party/nature_full/global.png  (160x208 atlas, 16x16 cells)
//   - assets/third_party/mushrooms/AnimatedMushroomRed.png  (384x384, 3x3 grid of 128x128 cells, 8 frames)
//   - assets/third_party/props/Log_sprite.png  (256x64 strip, 4 frames of 64x64)
//   - assets/third_party/potions_onocentaur/Potions - Full, Corked.png  (160x400 atlas, 16x24 cells)
//
// Writes individual PNG files to:
//   - assets/images/obstacles/mushroom/000.png ... 007.png
//   - assets/images/obstacles/log/000.png ... 003.png
//   - assets/images/collectibles/crystal/[name].png  (10 files)
//   - assets/images/collectibles/potion.png  (1 file)
//
// Also copies the fruit/veg individual PNGs from assets/third_party/fruits_veg/
// to assets/images/collectibles/, normalising filenames.
//
// Also copies curated rock PNG (Rock_03) and stone PNG (Stone_01) to
// assets/images/obstacles/ with normalised names.
//
// Idempotent: deletes + recreates each output subdir on re-run.
// Run from the repo root: `dart run tools/build_obstacle_collectible_sprites.dart`

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
/// Row 0 is the top of the atlas. CALIBRATE: visually verify on first run
/// by opening the output rose_quartz.png — if it's not a pink/rose gem,
/// adjust crystalRowY and re-run.
void _sliceCrystals() {
  const atlasPath = 'assets/third_party/nature_full/global.png';
  const outDir = 'assets/images/collectibles/crystal';
  const crystalRowY = 160;
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
  stdout.writeln('  crystals: ${names.length} files -> $outDir');
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
  stdout.writeln('  mushroom: 8 frames -> $outDir');
}

/// Log_sprite.png is 256x64 - a horizontal strip of 4 frames, each 64x64.
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
  stdout.writeln('  log: 4 frames -> $outDir');
}

/// Onocentaur potion atlas is 160x400 at 16x24 per cell: 10 cols x 16 rows.
/// We extract a single curated potion for V1 - the red heart-potion at (0,0).
void _slicePotion() {
  const atlasPath = 'assets/third_party/potions_onocentaur/Potions - Full, Corked.png';
  const outPath = 'assets/images/collectibles/potion.png';
  File(outPath).parent.createSync(recursive: true);
  final atlas = img.decodePng(File(atlasPath).readAsBytesSync())!;
  final cell = img.copyCrop(atlas, x: 0, y: 0, width: 16, height: 24);
  File(outPath).writeAsBytesSync(img.encodePng(cell));
  stdout.writeln('  potion: 1 file -> $outPath');
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
  stdout.writeln('  fruits/veg: ${pairs.length} files -> $outDir');
}

/// Copy Rock_03 + Stone_01 with normalised filenames.
void _copyRocksAndStone() {
  const outDir = 'assets/images/obstacles';
  Directory(outDir).createSync(recursive: true);
  File('assets/third_party/props/Rock_03 32x32.png').copySync('$outDir/rock.png');
  File('assets/third_party/props/Stone_01 16x16.png').copySync('$outDir/stone.png');
  stdout.writeln('  rocks: rock.png + stone.png -> $outDir');
}

void _ensureCleanDir(String path) {
  final dir = Directory(path);
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);
}
