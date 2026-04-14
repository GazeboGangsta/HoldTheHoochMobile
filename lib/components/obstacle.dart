import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';

enum ObstacleKind { root, rock, mushroom, log }

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
        ObstacleKind.root => Vector2(72, 36),
        ObstacleKind.rock => Vector2(72, 60),
        ObstacleKind.mushroom => Vector2(72, 72),
        ObstacleKind.log => Vector2(140, 48),
      };

  static String _svgFor(ObstacleKind k) => switch (k) {
        ObstacleKind.root => 'svg/root.svg',
        ObstacleKind.rock => 'svg/rock.svg',
        ObstacleKind.mushroom => 'svg/mushroom.svg',
        ObstacleKind.log => 'svg/log.svg',
      };

  @override
  Future<void> onLoad() async {
    final svg = await Svg.load(_svgFor(kind));
    add(SvgComponent(svg: svg, size: size));
    add(RectangleHitbox(
      size: Vector2(size.x * 0.8, size.y * 0.9),
      position: Vector2(size.x * 0.1, size.y * 0.1),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    x -= scrollSpeed * dt;
    if (x + width < -50) removeFromParent();
  }
}
