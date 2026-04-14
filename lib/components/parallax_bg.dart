import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';

/// Hand-rolled parallax: tile one SVG horizontally and scroll at a fractional
/// speed relative to the world. Used because flame's ParallaxComponent wants
/// raster images and our assets are SVG.
class ParallaxLayer extends PositionComponent {
  final String assetPath;
  final double speedFactor;
  final double Function() worldSpeedProvider;
  final double aspectRatio;

  late final Svg _svg;
  late final double _tileWidth;
  double _offset = 0;

  ParallaxLayer({
    required this.assetPath,
    required this.speedFactor,
    required this.worldSpeedProvider,
    required Vector2 worldSize,
    required double yPosition,
    required double height,
    this.aspectRatio = 1600 / 600,
  }) : super(
          position: Vector2(0, yPosition),
          size: Vector2(worldSize.x, height),
        );

  @override
  Future<void> onLoad() async {
    _svg = await Svg.load(assetPath);
    _tileWidth = size.y * aspectRatio;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _offset = (_offset + worldSpeedProvider() * speedFactor * dt) % _tileWidth;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final tileSize = Vector2(_tileWidth, size.y);
    canvas.save();
    canvas.translate(-_offset, 0);
    var x = 0.0;
    while (x < size.x + _tileWidth) {
      _svg.render(canvas, tileSize);
      canvas.translate(_tileWidth, 0);
      x += _tileWidth;
    }
    canvas.restore();
  }
}
