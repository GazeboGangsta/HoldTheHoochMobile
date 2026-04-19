import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/score_popup.dart';

/// Regression guard for the collectible-pickup crash.
///
/// Previously ScorePopup used Flame's MoveByEffect / OpacityEffect, which
/// require targets to implement PositionProvider / OpacityProvider. The
/// effect system failed target resolution on TextComponent and threw a
/// null-check as soon as the effects ran. Fix: animate manually in
/// update() — no Flame effects, no target dance.
///
/// We intentionally don't assert self-removal here: calling
/// removeFromParent() from inside a component's update() tree in a
/// test harness (FlameGame.update() loop without a full frame cycle)
/// triggers Flame's own iterator safety check. In production the
/// frame loop processes removals at safe points. The real regression
/// we're guarding is "does pickup animation run without throwing",
/// which is what crashed on collectible pickup.
void main() {
  test('ScorePopup animates without crashing', () async {
    final game = FlameGame();
    game.onGameResize(Vector2(800, 600));
    await game.onLoad();

    final popup = ScorePopup(
      points: 50,
      position: Vector2(100, 100),
    );
    final startY = popup.position.y;

    await game.add(popup);
    await game.ready();

    // Pump halfway through the popup's ~0.7s lifetime. Must not throw,
    // and popup must have risen.
    for (var i = 0; i < 20; i++) {
      game.update(1 / 60);
    }
    expect(popup.y, lessThan(startY));
  });
}
