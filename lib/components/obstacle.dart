import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

/// Obstacle kinds rolled by [ObstacleManager]. `stone` replaces the old
/// `root` kind — a small 16×16 tripping stone. `mushroom` + `log` are
/// animated sprites (SpriteAnimationComponent); `stone` + `rock` are
/// static (SpriteComponent).
enum ObstacleKind { stone, rock, mushroom, log }

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
        ObstacleKind.stone => Vector2(60, 49),
        ObstacleKind.rock => Vector2(109, 124),
        ObstacleKind.mushroom => Vector2(82, 82),
        ObstacleKind.log => Vector2(150, 82),
      };

  /// Pixels to push an obstacle BELOW the ground line (so tall rocks + logs
  /// appear planted in the dirt rather than floating on the grass). Applied
  /// by [ObstacleManager._spawn] as `position.y = groundY + yOffsetFor(k)`.
  /// Tuned via tools/sprite-size-preview.html.
  static double yOffsetFor(ObstacleKind k) => switch (k) {
        ObstacleKind.rock => 30,
        ObstacleKind.log => 17,
        ObstacleKind.stone || ObstacleKind.mushroom => 0,
      };

  static String _staticSpriteFor(ObstacleKind k) => switch (k) {
        ObstacleKind.stone => 'obstacles/stone.png',
        ObstacleKind.rock => 'obstacles/rock.png',
        _ => throw StateError('$k has no static sprite (it is animated)'),
      };

  @visibleForTesting
  static bool isAnimated(ObstacleKind k) => switch (k) {
        ObstacleKind.stone || ObstacleKind.rock => false,
        ObstacleKind.mushroom || ObstacleKind.log => true,
      };

  @visibleForTesting
  static ({String folder, int frameCount, double stepTime}) animationFor(
    ObstacleKind k,
  ) =>
      switch (k) {
        ObstacleKind.mushroom => (
            folder: 'obstacles/mushroom',
            frameCount: 8,
            stepTime: 0.12,
          ),
        ObstacleKind.log => (
            folder: 'obstacles/log',
            frameCount: 4,
            stepTime: 0.15,
          ),
        _ => throw StateError('$k is not animated'),
      };

  /// Hitbox as fractions of the sprite bounds. Platformers feel fair when
  /// grazes don't register as hits, so hitboxes are intentionally smaller
  /// than the visual.
  @visibleForTesting
  static ({Vector2 pos, Vector2 size}) hitboxFor(ObstacleKind k, Vector2 s) =>
      switch (k) {
        // Stone: small, flat, low to ground.
        ObstacleKind.stone => (
            pos: Vector2(s.x * 0.15, s.y * 0.35),
            size: Vector2(s.x * 0.70, s.y * 0.60),
          ),
        // Rock: roughly elliptical, approximated with a middle rect.
        ObstacleKind.rock => (
            pos: Vector2(s.x * 0.10, s.y * 0.25),
            size: Vector2(s.x * 0.80, s.y * 0.70),
          ),
        // Mushroom: narrow danger column around cap+stem.
        ObstacleKind.mushroom => (
            pos: Vector2(s.x * 0.25, s.y * 0.30),
            size: Vector2(s.x * 0.45, s.y * 0.65),
          ),
        // Log: wide, flat. Hugs the full trunk body.
        ObstacleKind.log => (
            pos: Vector2(s.x * 0.05, s.y * 0.25),
            size: Vector2(s.x * 0.90, s.y * 0.60),
          ),
      };

  @override
  Future<void> onLoad() async {
    if (isAnimated(kind)) {
      final cfg = animationFor(kind);
      final sprites = <Sprite>[];
      for (var i = 0; i < cfg.frameCount; i++) {
        final name = i.toString().padLeft(3, '0');
        sprites.add(await Sprite.load('${cfg.folder}/$name.png'));
      }
      final anim = SpriteAnimation.spriteList(sprites, stepTime: cfg.stepTime);
      add(SpriteAnimationComponent(animation: anim, size: size));
    } else {
      final sprite = await Sprite.load(_staticSpriteFor(kind));
      add(SpriteComponent(sprite: sprite, size: size));
    }
    final hb = hitboxFor(kind, size);
    add(RectangleHitbox(size: hb.size, position: hb.pos));
  }

  @override
  void update(double dt) {
    super.update(dt);
    x -= scrollSpeed * dt;
    if (x + width < -50) removeFromParent();
  }
}
