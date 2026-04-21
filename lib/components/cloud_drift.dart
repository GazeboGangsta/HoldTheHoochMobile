import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

/// Drifts a single cloud PNG horizontally at a fixed velocity, independent
/// of world scroll speed. Tiles horizontally the same way [RasterParallaxLayer]
/// does, so clouds wrap seamlessly.
///
/// Use a small positive velocity (e.g. 8-20 px/s) for a slow leftward drift
/// that reads as distant wind. Negative velocity drifts rightward (useful
/// as counter-drift for atmospheric variety).
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
  /// negative operands (e.g. `-5 % 600 = -5`), so we manually shift back
  /// into the positive range when that happens.
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
