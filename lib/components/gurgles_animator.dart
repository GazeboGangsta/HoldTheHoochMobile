import '../config/game_config.dart';

enum GurglesAnimation {
  idle,
  run,
  jumpStart,
  jumpCycle,
  jumpLand,
  hurt,
  dead,
}

/// Pure state machine for Gurgles' visible animation.
///
/// Takes physics inputs (`onGround`, `velocityY`) + explicit triggers
/// (`triggerHurt`, `setIdle`, `reset`). Emits the current [state] which the
/// renderer swaps into a [SpriteAnimationComponent.animation].
///
/// No Flame, no async, no mutable external state — unit-testable.
class GurglesAnimator {
  GurglesAnimation _state = GurglesAnimation.run;
  double _stateElapsed = 0;

  GurglesAnimation get state => _state;

  void update(double dt, {required bool onGround, required double velocityY}) {
    _stateElapsed += dt;
    switch (_state) {
      case GurglesAnimation.dead:
        return;
      case GurglesAnimation.hurt:
        if (_stateElapsed >= GameConfig.hurtDurationSeconds) {
          _transition(GurglesAnimation.dead);
        }
        return;
      case GurglesAnimation.idle:
      case GurglesAnimation.run:
        if (!onGround) _transition(GurglesAnimation.jumpStart);
        return;
      case GurglesAnimation.jumpStart:
        if (_stateElapsed >= GameConfig.jumpStartDurationSeconds) {
          _transition(GurglesAnimation.jumpCycle);
        }
        return;
      case GurglesAnimation.jumpCycle:
        if (onGround) _transition(GurglesAnimation.jumpLand);
        return;
      case GurglesAnimation.jumpLand:
        if (_stateElapsed >= GameConfig.jumpLandDurationSeconds) {
          _transition(GurglesAnimation.run);
        }
        return;
    }
  }

  void triggerHurt() {
    if (_state == GurglesAnimation.hurt || _state == GurglesAnimation.dead) {
      return;
    }
    _transition(GurglesAnimation.hurt);
  }

  void setIdle() => _transition(GurglesAnimation.idle);

  void reset() => _transition(GurglesAnimation.run);

  void _transition(GurglesAnimation next) {
    _state = next;
    _stateElapsed = 0;
  }
}
