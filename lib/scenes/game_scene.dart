import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../components/gurgles.dart';
import '../components/hooch_balance.dart';

/// Primary game scene for M2. Shows a scrolling greybox ground + tappable Gurgles.
/// Obstacles, collectibles, and scoring land in later milestones.
class GameScene extends FlameGame with TapCallbacks, HasKeyboardHandlerComponents {
  late final Gurgles gurgles;
  late final HoochBalance balance;
  double _elapsed = 0;
  int score = 0;

  @override
  Color backgroundColor() => const Color(0xFF87CEEB);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final groundY = size.y - 120;
    final ground = RectangleComponent(
      position: Vector2(0, groundY),
      size: Vector2(size.x, size.y - groundY),
      paint: Paint()..color = const Color(0xFF5A3A1A),
    );
    add(ground);

    gurgles = Gurgles(
      position: Vector2(size.x * 0.25, groundY),
      groundY: groundY,
    )..paint = (Paint()..color = const Color(0xFF3D8B4A));
    add(gurgles);

    balance = HoochBalance();
    add(balance);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    score = _elapsed.floor() * 10;
    if (balance.hasSpilled) {
      // TODO(M3): transition to GameOverScene with final score.
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final isRight = event.localPosition.x > size.x / 2;
    if (isRight) {
      gurgles.startJump();
      balance.applyJumpImpulse();
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    gurgles.endJump();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    gurgles.endJump();
  }
}
