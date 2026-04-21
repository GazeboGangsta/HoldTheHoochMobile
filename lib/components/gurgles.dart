import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import '../config/game_config.dart';
import 'gurgles_animator.dart';
import 'obstacle.dart';

/// Gurgles the runner + the tankard of hooch riding above his head.
///
/// Body renders from a [SpriteAnimationComponent] driven by [GurglesAnimator].
/// The tankard is a separate [SvgComponent] child that rotates with
/// `balance.tilt` (unchanged from the pre-animation implementation).
class Gurgles extends PositionComponent with CollisionCallbacks {
  double velocityY = 0;
  // 2px tolerance: floating-point arithmetic + size-change cascades leave
  // Gurgles hovering sub-pixel amounts above groundY. A strict `y >= groundY`
  // locks him out of jumping forever.
  bool get onGround => y >= _groundY - 2;
  final double _groundY;
  bool _jumpHeld = false;
  double _jumpHeldMs = 0;

  final GurglesAnimator animator = GurglesAnimator();

  // Populated in onLoad. Test stubs may skip onLoad, in which case
  // [_spritesLoaded] stays false and [_refreshAnimation] no-ops.
  late Map<GurglesAnimation, SpriteAnimation> _animations;
  SpriteAnimationComponent? _body;
  bool _spritesLoaded = false;

  // Nullable because Gurgles.onLoad (which loads the SVG) may not have
  // finished by the time GameScene.update calls setTankardAngle. Rather
  // than await-ing add(gurgles) in the scene, we treat pre-load calls as
  // no-ops.
  SvgComponent? _tankard;

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
    _animations = {
      GurglesAnimation.idle: await _loadSequence('idle', 20, 0.08),
      GurglesAnimation.run: await _loadSequence('run', 8, 0.06),
      GurglesAnimation.jumpStart: await _loadSequence(
          'jump_start', 7, GameConfig.jumpStartDurationSeconds / 7,
          loop: false),
      GurglesAnimation.jumpCycle: await _loadSequence('jump_cycle', 12, 0.06),
      GurglesAnimation.jumpLand: await _loadSequence(
          'jump_land', 6, GameConfig.jumpLandDurationSeconds / 6,
          loop: false),
      GurglesAnimation.hurt: await _loadSequence(
          'hurt', 6, GameConfig.hurtDurationSeconds / 6,
          loop: false),
      GurglesAnimation.dead: await _loadSequence('dead', 1, 1.0, loop: false),
    };
    _body = SpriteAnimationComponent(
      animation: _animations[GurglesAnimation.run]!,
      size: size,
    );
    add(_body!);

    final hoochSvg = await Svg.load('svg/hooch.svg');
    final tankardSize = Vector2(size.x * 0.7, size.x * 0.55);
    final tankard = SvgComponent(
      svg: hoochSvg,
      size: tankardSize,
      position: Vector2(size.x / 2, -2),
      anchor: Anchor.bottomCenter,
    );
    _tankard = tankard;
    add(tankard);

    // Tight body hitbox tuned empirically against the no_hat_gnome frames.
    // Excludes the raised hat/hair, outstretched staff, and tankard so
    // grazes feel fair. Refined on-device in Task 9.
    add(RectangleHitbox(
      size: Vector2(size.x * 0.40, size.y * 0.58),
      position: Vector2(size.x * 0.30, size.y * 0.32),
    ));
    _spritesLoaded = true;
  }

  Future<SpriteAnimation> _loadSequence(
    String folder,
    int frameCount,
    double stepTime, {
    bool loop = true,
  }) async {
    final sprites = <Sprite>[];
    for (int i = 0; i < frameCount; i++) {
      final name = i.toString().padLeft(3, '0');
      sprites.add(await Sprite.load('gurgles/$folder/$name.png'));
    }
    return SpriteAnimation.spriteList(sprites, stepTime: stepTime, loop: loop);
  }

  void startJump() {
    if (!onGround) return;
    velocityY = GameConfig.jumpVelocityMin;
    _jumpHeld = true;
    _jumpHeldMs = 0;
  }

  void endJump() => _jumpHeld = false;

  /// Called from GameScene when Gurgles should play the hurt-then-dead
  /// sequence. Idempotent — repeated calls after the first are ignored.
  void triggerHurt() => animator.triggerHurt();

  /// Pure function: how far the tankard should lean for a given balance tilt.
  /// Tested in test/tankard_rotation_test.dart.
  static double tankardAngleForTilt(double tilt) =>
      tilt * GameConfig.tankardMaxLeanRadians;

  /// Pure function: offset from tankard center to the point on the rim
  /// pointing in the tilt direction. When [tilt] is 0, that's straight up
  /// at `(0, -tankardRadius)`; the vector rotates by
  /// `tilt * GameConfig.tankardMaxLeanRadians` so the emission point
  /// tracks the lean. Tested in test/tankard_rotation_test.dart.
  @visibleForTesting
  static Vector2 rimOffsetFromTankardCenter(double tilt, double tankardRadius) =>
      Vector2(0, -tankardRadius)..rotate(tilt * GameConfig.tankardMaxLeanRadians);

  /// Called from GameScene.update each frame to visually tilt the tankard in
  /// sync with balance.tilt. Gives the player a clear cue about which way to
  /// counter-drag to avoid spilling.
  void setTankardAngle(double angle) {
    _tankard?.angle = angle;
  }

  /// World-space position of the tankard rim on the tilt side.
  /// Used by [SplashEmitter] to spawn droplets where the hooch would
  /// physically spill out. Returns Gurgles' own position if the tankard
  /// hasn't loaded yet (pre-onLoad), matching the existing null-safe
  /// pattern for _tankard.
  Vector2 tankardRimWorldPosition(double tilt) {
    final t = _tankard;
    if (t == null) return position.clone();
    return t.absoluteCenter + rimOffsetFromTankardCenter(tilt, t.size.y / 2);
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
    if (y >= _groundY) {
      y = _groundY;
      velocityY = 0;
      _jumpHeld = false;
    }
    animator.update(dt, onGround: onGround, velocityY: velocityY);
    _refreshAnimation();
  }

  void _refreshAnimation() {
    if (!_spritesLoaded) return;
    final target = _animations[animator.state]!;
    if (_body!.animation != target) {
      _body!.animation = target;
    }
  }

  /// Reset animator state on restart. Physics fields (velocityY, position)
  /// are reset by GameScene.restart itself.
  void resetAnimator() => animator.reset();

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    // Only obstacles end the run — collectibles handle their own pickup.
    if (other is Obstacle) {
      onObstacleHit?.call();
    }
  }
}
