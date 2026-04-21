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
