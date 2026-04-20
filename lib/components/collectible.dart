import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show VoidCallback, visibleForTesting;
import 'package:flame_svg/flame_svg.dart';
import 'gurgles.dart';

enum CollectibleKind { herb, hops, potion }

class Collectible extends PositionComponent with CollisionCallbacks {
  final CollectibleKind kind;
  final void Function(int points, Vector2 worldPos) onPickup;
  final VoidCallback? _grantPotionBonus;
  double scrollSpeed;
  bool _consumed = false;

  Collectible({
    required this.kind,
    required Vector2 position,
    required this.scrollSpeed,
    required this.onPickup,
    VoidCallback? onPotionBonus,
    double sizeScale = 1.0,
  })  : _grantPotionBonus = onPotionBonus,
        super(
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

  /// Active hitbox for pickup detection. 90% of sprite, centered via 5% inset
  /// on each side, so edge-grazes don't award points and clipping-in visually
  /// always corresponds to a real pickup.
  @visibleForTesting
  static ({Vector2 pos, Vector2 size}) hitboxFor(Vector2 spriteSize) => (
        pos: Vector2(spriteSize.x * 0.05, spriteSize.y * 0.05),
        size: Vector2(spriteSize.x * 0.9, spriteSize.y * 0.9),
      );

  @override
  Future<void> onLoad() async {
    final svg = await Svg.load(_svgFor(kind));
    add(SvgComponent(svg: svg, size: size));
    // Active hitbox (default) so Collectible.onCollisionStart fires when
    // Gurgles overlaps — with passive we'd only get the callback on
    // Gurgles' side and onPickup would never run.
    final hb = hitboxFor(size);
    add(RectangleHitbox(size: hb.size, position: hb.pos));
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
    onPickup(pointsFor(kind), position.clone());
    if (kind == CollectibleKind.potion) {
      _grantPotionBonus?.call();
    }
    removeFromParent();
  }
}
