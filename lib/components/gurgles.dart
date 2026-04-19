import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';
import '../config/game_config.dart';
import 'obstacle.dart';

/// Gurgles the runner + the tankard of hooch riding above his head.
class Gurgles extends PositionComponent with CollisionCallbacks {
  double velocityY = 0;
  // 2px tolerance: floating-point arithmetic + size-change cascades leave
  // Gurgles hovering sub-pixel amounts above groundY. A strict `y >= groundY`
  // locks him out of jumping forever.
  bool get onGround => y >= _groundY - 2;
  final double _groundY;
  bool _jumpHeld = false;
  double _jumpHeldMs = 0;

  late SvgComponent _runSvg;
  late SvgComponent _jumpSvg;
  late SvgComponent _tankard;

  void Function()? onObstacleHit;

  Gurgles({
    required Vector2 position,
    required double groundY,
    Vector2? size,
  })  : _groundY = groundY,
        super(
          position: position,
          size: size ?? Vector2(96, 120),
          anchor: Anchor.bottomCenter,
        ) {
    y = groundY;
  }

  @override
  Future<void> onLoad() async {
    final runSvg = await Svg.load('svg/gurgles.svg');
    final jumpSvg = await Svg.load('svg/gurgles-jump.svg');
    final hoochSvg = await Svg.load('svg/hooch.svg');

    _runSvg = SvgComponent(svg: runSvg, size: size);
    _jumpSvg = SvgComponent(svg: jumpSvg, size: size);
    add(_runSvg);

    // Tankard sits above Gurgles' raised hands.
    final tankardSize = Vector2(size.x * 0.7, size.x * 0.55);
    _tankard = SvgComponent(
      svg: hoochSvg,
      size: tankardSize,
      position: Vector2(size.x / 2, -2),
      anchor: Anchor.bottomCenter,
    );
    add(_tankard);

    // Tight body hitbox: just the tunic + legs region of gurgles.svg
    // (face+body+legs span roughly y=26..74 of 80, x=24..40 of 64).
    // We exclude the raised arms, hat spike, and tankard so grazes feel fair.
    add(RectangleHitbox(
      size: Vector2(size.x * 0.38, size.y * 0.62),
      position: Vector2(size.x * 0.31, size.y * 0.30),
    ));
  }

  void _swapSprite(bool jumping) {
    final hasRun = contains(_runSvg);
    final hasJump = contains(_jumpSvg);
    if (jumping && hasRun) {
      remove(_runSvg);
      add(_jumpSvg);
    } else if (!jumping && hasJump) {
      remove(_jumpSvg);
      add(_runSvg);
    }
  }

  void startJump() {
    if (!onGround) return;
    velocityY = GameConfig.jumpVelocityMin;
    _jumpHeld = true;
    _jumpHeldMs = 0;
  }

  void endJump() => _jumpHeld = false;

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
    if (y >= _groundY) {
      y = _groundY;
      velocityY = 0;
      _jumpHeld = false;
    }
    _swapSprite(!onGround);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    // Only obstacles end the run — collectibles handle their own pickup.
    if (other is Obstacle) {
      onObstacleHit?.call();
    }
  }
}
