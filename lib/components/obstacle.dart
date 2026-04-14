import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum ObstacleKind { root, rock, mushrooms, log }

class Obstacle extends RectangleComponent with CollisionCallbacks {
  final ObstacleKind kind;
  double scrollSpeed;

  Obstacle({
    required this.kind,
    required Vector2 position,
    required this.scrollSpeed,
  }) : super(
          position: position,
          size: _sizeFor(kind),
          anchor: Anchor.bottomLeft,
          paint: Paint()..color = _colorFor(kind),
        );

  static Vector2 _sizeFor(ObstacleKind k) => switch (k) {
        ObstacleKind.root => Vector2(64, 40),
        ObstacleKind.rock => Vector2(72, 72),
        ObstacleKind.mushrooms => Vector2(96, 56),
        ObstacleKind.log => Vector2(160, 48),
      };

  static Color _colorFor(ObstacleKind k) => switch (k) {
        ObstacleKind.root => const Color(0xFF6B4A1A),
        ObstacleKind.rock => const Color(0xFF777777),
        ObstacleKind.mushrooms => const Color(0xFFB83030),
        ObstacleKind.log => const Color(0xFF4A2D12),
      };

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    x -= scrollSpeed * dt;
    if (x + width < -50) removeFromParent();
  }
}
