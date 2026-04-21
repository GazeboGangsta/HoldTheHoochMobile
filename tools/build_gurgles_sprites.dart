// One-shot asset curation script.
//
// Reads raw gnome frames from `art-source/gnomes/PNG_sequences/no_hat_gnome/`
// (gitignored), computes the union content bounding box across all shipping
// frames, crops each frame to that box, resizes to 256 px tall, and writes
// them to `assets/images/gurgles/<anim>/<NNN>.png`.
//
// Run from the repo root: `dart run tools/build_gurgles_sprites.dart`
//
// Not intended to run in CI — raw pack is not checked in. Regenerate locally
// whenever the source frames change.

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
  final source = Directory(srcDir);
  if (!source.existsSync()) {
    stderr.writeln('ERROR: $srcDir not found. Extract gnomes.zip first.');
    exit(1);
  }

  // Collect all frames we'll ship, in per-animation order.
  final allFramePaths = <String>[];
  final framesByAnim = <String, List<String>>{};
  for (final anim in animations.keys) {
    // Match exactly `__no_hat_gnome_<anim>_NNN.png` — the trailing `_\d{3}\.png`
    // prevents `run` from also matching `run_flip_000.png`, etc.
    final framePattern = RegExp(r'__no_hat_gnome_' + anim + r'_\d{3}\.png$');
    final frames = source
        .listSync()
        .whereType<File>()
        .map((f) => f.path)
        .where((p) => framePattern.hasMatch(p.replaceAll(r'\', '/')))
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
  stdout.writeln('Union bbox: ${cropW}x$cropH at ($minX, $minY)');

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
