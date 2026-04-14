import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../config/game_config.dart';

/// Gurgles the runner. Greybox rectangle for M1/M2 — sprite comes in M5.
class Gurgles extends RectangleComponent with CollisionCallbacks {
  double velocityY = 0;
  bool get onGround => _onGroundY != null && y >= _onGroundY!;
  double? _onGroundY;
  bool _jumpHeld = false;
  double _jumpHeldMs = 0;

  void Function()? onObstacleHit;

  Gurgles({required Vector2 position, required double groundY})
      : super(
          position: position,
          size: Vector2(96, 128),
          anchor: Anchor.bottomCenter,
        ) {
    _onGroundY = groundY;
    y = groundY;
  }

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  void startJump() {
    if (!onGround) return;
    velocityY = GameConfig.jumpVelocityMin;
    _jumpHeld = true;
    _jumpHeldMs = 0;
  }

  void endJump() {
    _jumpHeld = false;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_jumpHeld) {
      _jumpHeldMs += dt * 1000;
      final t = (_jumpHeldMs / GameConfig.jumpHoldMaxMs).clamp(0.0, 1.0);
      velocityY = GameConfig.jumpVelocityMin +
          (GameConfig.jumpVelocityMax - GameConfig.jumpVelocityMin) * t;
      if (_jumpHeldMs >= GameConfig.jumpHoldMaxMs) _jumpHeld = false;
    }

    velocityY += GameConfig.gravity * dt;
    y += velocityY * dt;

    if (_onGroundY != null && y >= _onGroundY!) {
      y = _onGroundY!;
      velocityY = 0;
      _jumpHeld = false;
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    onObstacleHit?.call();
  }
}
