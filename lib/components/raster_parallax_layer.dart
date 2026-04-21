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
