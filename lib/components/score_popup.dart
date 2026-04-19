import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Ephemeral "+N" text that floats up over its lifetime and self-removes.
///
/// Animation is driven manually in update() rather than via Flame Effects —
/// MoveByEffect / OpacityEffect require the target to implement
/// PositionProvider / OpacityProvider, and TextComponent's interaction
/// with those providers throws a null-check under Flame 1.37 when the
/// effect runs.
///
/// Removal is routed through a child TimerComponent rather than calling
/// removeFromParent() directly from update() — the latter triggered a
/// "Concurrent modification during iteration" error in FlameGame.updateTree.
class ScorePopup extends TextComponent {
  static const double _lifetime = 0.7;
  static const double _riseDistance = 60;

  final double _startY;
  double _elapsed = 0;

  ScorePopup({required int points, required Vector2 position})
      : _startY = position.y,
        super(
          text: '+$points',
          position: position,
          anchor: Anchor.center,
          priority: 500,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0xFFFFE066),
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    add(TimerComponent(
      period: _lifetime,
      removeOnFinish: true,
      // Defer removeFromParent to a microtask: calling it synchronously
      // from the timer's onTick modifies the game's children set while
      // the game's updateTree is iterating it (ConcurrentModification).
      onTick: () => Future.microtask(removeFromParent),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    final t = (_elapsed / _lifetime).clamp(0.0, 1.0);
    // Ease-out: fast rise, slow end.
    final eased = 1 - (1 - t) * (1 - t);
    y = _startY - _riseDistance * eased;
  }
}
