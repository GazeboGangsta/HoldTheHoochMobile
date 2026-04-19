import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';
import 'gurgles.dart';

enum CollectibleKind { herb, hops, potion }

class Collectible extends PositionComponent with CollisionCallbacks {
  final CollectibleKind kind;
  final void Function(int points) onPickup;
  double scrollSpeed;
  bool _consumed = false;

  Collectible({
    required this.kind,
    required Vector2 position,
    required this.scrollSpeed,
    required this.onPickup,
    double sizeScale = 1.0,
  }) : super(
          position: position,
          size: _sizeFor(kind) * sizeScale,
          anchor: Anchor.bottomCenter,
        );

  static Vector2 _sizeFor(CollectibleKind k) => switch (k) {
        CollectibleKind.herb => Vector2(48, 48),
        CollectibleKind.hops => Vector2(48, 56),
        CollectibleKind.potion => Vector2(40, 56),
      };

  static String _svgFor(CollectibleKind k) => switch (k) {
        CollectibleKind.herb => 'svg/herb.svg',
        CollectibleKind.hops => 'svg/hops.svg',
        CollectibleKind.potion => 'svg/potion.svg',
      };

  static int pointsFor(CollectibleKind k) => switch (k) {
        CollectibleKind.herb => 10,
        CollectibleKind.hops => 50,
        CollectibleKind.potion => 200,
      };

  @override
  Future<void> onLoad() async {
    final svg = await Svg.load(_svgFor(kind));
    add(SvgComponent(svg: svg, size: size));
    add(RectangleHitbox(
      size: Vector2(size.x * 0.9, size.y * 0.9),
      position: Vector2(size.x * 0.05, size.y * 0.05),
      collisionType: CollisionType.passive,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    x -= scrollSpeed * dt;
    if (x + width < -50) removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (_consumed || other is! Gurgles) return;
    _consumed = true;
    onPickup(pointsFor(kind));
    removeFromParent();
  }
}
