import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// Ephemeral "+N" text that floats up and fades out. One-shot — removes
/// itself after its effects complete.
class ScorePopup extends TextComponent {
  ScorePopup({required int points, required Vector2 position})
      : super(
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
    add(MoveByEffect(
      Vector2(0, -60),
      EffectController(duration: 0.7, curve: Curves.easeOut),
    ));
    add(OpacityEffect.fadeOut(
      EffectController(duration: 0.7, startDelay: 0.1),
      onComplete: removeFromParent,
    ));
  }
}
