import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';

/// Ground strip pinned to the bottom of the world. Uses the web game's
/// bg-ground.svg tiled horizontally.
class Ground extends PositionComponent {
  final double groundHeight;
  Svg? _svg;
  double _offset = 0;
  final double Function()? scrollSpeedProvider;
  late double _tileWidth;

  Ground({
    required Vector2 worldSize,
    this.groundHeight = 120,
    this.scrollSpeedProvider,
  }) : super(
          position: Vector2(0, worldSize.y - groundHeight),
          size: Vector2(worldSize.x, groundHeight),
        );

  double get topY => position.y;

  @override
  Future<void> onLoad() async {
    _svg = await Svg.load('svg/bg-ground.svg');
    // bg-ground.svg viewBox is ~1600x200 → aspect 8:1
    _tileWidth = groundHeight * 8;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (scrollSpeedProvider != null) {
      _offset = (_offset + scrollSpeedProvider!() * dt) % _tileWidth;
    }
  }

  @override
  void render(canvas) {
    super.render(canvas);
    final svg = _svg;
    if (svg == null) return;
    canvas.save();
    canvas.translate(-_offset, 0);
    final tileSize = Vector2(_tileWidth, size.y);
    var x = 0.0;
    while (x < size.x + _tileWidth) {
      svg.render(canvas, tileSize);
      canvas.translate(_tileWidth, 0);
      x += _tileWidth;
    }
    canvas.restore();
  }
}
