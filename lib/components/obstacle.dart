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

  /// Hitbox as fractions of the sprite bounds, tuned per-obstacle from the
  /// actual SVG silhouette (see docs/GAME_DESIGN.md). Values here are
  /// intentionally smaller than the visual — platformers feel fairer when
  /// grazes don't register as hits.
  static ({Vector2 pos, Vector2 size}) _hitboxFor(ObstacleKind k, Vector2 s) => switch (k) {
        // Root: wide, low. Bulk sits in the bottom 60% of the viewBox.
        ObstacleKind.root => (
            pos: Vector2(s.x * 0.10, s.y * 0.40),
            size: Vector2(s.x * 0.80, s.y * 0.60),
          ),
        // Rock: roughly elliptical, approximated with a middle rect.
        ObstacleKind.rock => (
            pos: Vector2(s.x * 0.10, s.y * 0.25),
            size: Vector2(s.x * 0.80, s.y * 0.70),
          ),
        // Mushroom cluster: narrow danger column around the main cap+stem.
        // Small right-side mushroom is short enough it's usually jumped over
        // when the big one is cleared; we intentionally don't hitbox it.
        ObstacleKind.mushroom => (
            pos: Vector2(s.x * 0.12, s.y * 0.22),
            size: Vector2(s.x * 0.45, s.y * 0.75),
          ),
        // Log: wide, flat. Hugs the full trunk body.
        ObstacleKind.log => (
            pos: Vector2(s.x * 0.05, s.y * 0.20),
            size: Vector2(s.x * 0.90, s.y * 0.70),
          ),
      };

  @override
  Future<void> onLoad() async {
    final svg = await Svg.load(_svgFor(kind));
    add(SvgComponent(svg: svg, size: size));
    final hb = _hitboxFor(kind, size);
    add(RectangleHitbox(size: hb.size, position: hb.pos));
  }

  @override
  void update(double dt) {
    super.update(dt);
    x -= scrollSpeed * dt;
    if (x + width < -50) removeFromParent();
  }
}
