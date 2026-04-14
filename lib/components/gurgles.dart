import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';
import '../config/game_config.dart';

/// Gurgles the runner. Uses the web game's SVG art via flame_svg.
class Gurgles extends PositionComponent with CollisionCallbacks {
  double velocityY = 0;
  bool get onGround => y >= _groundY;
  final double _groundY;
  bool _jumpHeld = false;
  double _jumpHeldMs = 0;

  late SvgComponent _runSvg;
  late SvgComponent _jumpSvg;

  void Function()? onObstacleHit;

  Gurgles({required Vector2 position, required double groundY})
      : _groundY = groundY,
        super(
          position: position,
          size: Vector2(96, 120),
          anchor: Anchor.bottomCenter,
        ) {
    y = groundY;
  }

  @override
  Future<void> onLoad() async {
    final runSvg = await Svg.load('svg/gurgles.svg');
    final jumpSvg = await Svg.load('svg/gurgles-jump.svg');
    _runSvg = SvgComponent(svg: runSvg, size: size);
    _jumpSvg = SvgComponent(svg: jumpSvg, size: size);
    add(_runSvg);
    // Hitbox tuned slightly inside the silhouette so grazes don't register.
    add(RectangleHitbox(
      size: Vector2(size.x * 0.55, size.y * 0.85),
      position: Vector2(size.x * 0.22, size.y * 0.1),
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
    onObstacleHit?.call();
  }
}
