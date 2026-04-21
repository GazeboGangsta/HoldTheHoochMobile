import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/gurgles_animator.dart';
import 'package:hold_the_hooch/config/game_config.dart';

void main() {
  group('GurglesAnimator', () {
    test('starts in run state', () {
      final a = GurglesAnimator();
      expect(a.state, GurglesAnimation.run);
    });

    test('run -> jumpStart when leaving ground', () {
      final a = GurglesAnimator();
      a.update(0.016, onGround: false, velocityY: -500);
      expect(a.state, GurglesAnimation.jumpStart);
    });

    test('jumpStart -> jumpCycle after jumpStartDuration elapses', () {
      final a = GurglesAnimator();
      a.update(0.016, onGround: false, velocityY: -500);
      // Tick past the transition boundary.
      a.update(GameConfig.jumpStartDurationSeconds + 0.01,
          onGround: false, velocityY: 0);
      expect(a.state, GurglesAnimation.jumpCycle);
    });

    test('jumpCycle -> jumpLand when ground re-acquired', () {
      final a = GurglesAnimator();
      a.update(0.016, onGround: false, velocityY: -500);
      a.update(GameConfig.jumpStartDurationSeconds + 0.01,
          onGround: false, velocityY: 0);
      // Now land.
      a.update(0.016, onGround: true, velocityY: 0);
      expect(a.state, GurglesAnimation.jumpLand);
    });

    test('jumpLand -> run after jumpLandDuration elapses', () {
      final a = GurglesAnimator();
      a.update(0.016, onGround: false, velocityY: -500);
      a.update(GameConfig.jumpStartDurationSeconds + 0.01,
          onGround: false, velocityY: 0);
      a.update(0.016, onGround: true, velocityY: 0);
      a.update(GameConfig.jumpLandDurationSeconds + 0.01,
          onGround: true, velocityY: 0);
      expect(a.state, GurglesAnimation.run);
    });

    test('jumpStart -> jumpLand if onGround becomes true before duration elapses', () {
      final a = GurglesAnimator();
      a.update(0.016, onGround: false, velocityY: -500);
      // Short-tap: player lands mid-takeoff.
      a.update(0.016, onGround: true, velocityY: 0);
      expect(a.state, GurglesAnimation.jumpLand);
    });

    test('triggerHurt -> hurt from any non-terminal state', () {
      final a = GurglesAnimator();
      a.triggerHurt();
      expect(a.state, GurglesAnimation.hurt);
    });

    test('hurt -> dead after hurtDuration elapses', () {
      final a = GurglesAnimator();
      a.triggerHurt();
      a.update(GameConfig.hurtDurationSeconds + 0.01,
          onGround: true, velocityY: 0);
      expect(a.state, GurglesAnimation.dead);
    });

    test('dead is terminal — update is a no-op', () {
      final a = GurglesAnimator();
      a.triggerHurt();
      a.update(GameConfig.hurtDurationSeconds + 0.01,
          onGround: true, velocityY: 0);
      expect(a.state, GurglesAnimation.dead);
      // Even with onGround=false and velocityY<0, should stay dead.
      a.update(0.5, onGround: false, velocityY: -500);
      expect(a.state, GurglesAnimation.dead);
    });

    test('triggerHurt after dead is a no-op', () {
      final a = GurglesAnimator();
      a.triggerHurt();
      a.update(GameConfig.hurtDurationSeconds + 0.01,
          onGround: true, velocityY: 0);
      a.triggerHurt();
      expect(a.state, GurglesAnimation.dead);
    });

    test('reset returns to run', () {
      final a = GurglesAnimator();
      a.triggerHurt();
      a.reset();
      expect(a.state, GurglesAnimation.run);
    });

    test('setIdle puts animator in idle (menu use)', () {
      final a = GurglesAnimator();
      a.setIdle();
      expect(a.state, GurglesAnimation.idle);
    });

    test('idle -> jumpStart if onGround becomes false (defensive)', () {
      final a = GurglesAnimator();
      a.setIdle();
      a.update(0.016, onGround: false, velocityY: -500);
      expect(a.state, GurglesAnimation.jumpStart);
    });
  });
}
