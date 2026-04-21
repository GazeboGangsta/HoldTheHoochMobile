import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show VoidCallback, visibleForTesting;
import 'gurgles.dart';

/// Collectible tiers, rolled with weighted RNG by [CollectibleManager]:
/// - fruitCommon: strawberry / cherry / tomato (10 pts, ground tier).
/// - fruitMedium: apple / orange / pumpkin (50 pts, partial-jump tier).
/// - fruitRare: golden apple (100 pts, partial-jump tier).
/// - crystal: 10 gem variants (150 pts, full-jump tier).
/// - potion: single Onocentaur bottle (200 pts, full-jump tier, grants
///   1-second 4× spill-drain bonus).
enum CollectibleKind { fruitCommon, fruitMedium, fruitRare, crystal, potion }

class Collectible extends PositionComponent with CollisionCallbacks {
  final CollectibleKind kind;
  final String spritePath;
  final void Function(int points, Vector2 worldPos) onPickup;
  final VoidCallback? _grantPotionBonus;
  double scrollSpeed;
  bool _consumed = false;

  Collectible({
    required this.kind,
    required this.spritePath,
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
        CollectibleKind.fruitCommon => Vector2(60, 60),
        CollectibleKind.fruitMedium => Vector2(65, 65),
        CollectibleKind.fruitRare => Vector2(60, 60),
        CollectibleKind.crystal => Vector2(36, 36),
        CollectibleKind.potion => Vector2(32, 48),
      };

  /// List of sprite asset paths available for each kind. Manager picks one
  /// uniformly at random per spawn, so kinds with multiple entries (e.g.
  /// fruitCommon, crystal) get visual variety for free while behaviour
  /// stays kind-driven.
  static List<String> spritePathsFor(CollectibleKind k) => switch (k) {
        CollectibleKind.fruitCommon => const [
            'collectibles/cherry.png',
            'collectibles/strawberry.png',
            'collectibles/tomato.png',
          ],
        CollectibleKind.fruitMedium => const [
            'collectibles/apple.png',
            'collectibles/orange.png',
            'collectibles/pumpkin.png',
          ],
        CollectibleKind.fruitRare => const [
            'collectibles/golden_apple.png',
          ],
        CollectibleKind.crystal => const [
            'collectibles/crystal/rose_quartz.png',
            'collectibles/crystal/jasper.png',
            'collectibles/crystal/citrine.png',
            'collectibles/crystal/turquoise.png',
            'collectibles/crystal/tiger_eye.png',
            'collectibles/crystal/amethyst.png',
            'collectibles/crystal/moonstone.png',
            'collectibles/crystal/sapphire.png',
            'collectibles/crystal/quartz.png',
            'collectibles/crystal/bloodstone.png',
          ],
        CollectibleKind.potion => const ['collectibles/potion.png'],
      };

  static int pointsFor(CollectibleKind k) => switch (k) {
        CollectibleKind.fruitCommon => 10,
        CollectibleKind.fruitMedium => 50,
        CollectibleKind.fruitRare => 100,
        CollectibleKind.crystal => 150,
        CollectibleKind.potion => 200,
      };

  @visibleForTesting
  static bool grantsSpillDrain(CollectibleKind k) => k == CollectibleKind.potion;

  /// Active hitbox for pickup detection. 90% of sprite, centered via 5% inset
  /// on each side.
  @visibleForTesting
  static ({Vector2 pos, Vector2 size}) hitboxFor(Vector2 spriteSize) => (
        pos: Vector2(spriteSize.x * 0.05, spriteSize.y * 0.05),
        size: Vector2(spriteSize.x * 0.9, spriteSize.y * 0.9),
      );

  @override
  Future<void> onLoad() async {
    final sprite = await Sprite.load(spritePath);
    add(SpriteComponent(sprite: sprite, size: size));
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
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (_consumed || other is! Gurgles) return;
    _consumed = true;
    onPickup(pointsFor(kind), position.clone());
    if (grantsSpillDrain(kind)) {
      _grantPotionBonus?.call();
    }
    removeFromParent();
  }
}
