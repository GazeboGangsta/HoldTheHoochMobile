import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Static ground strip pinned to the bottom of the world. Parallax scrolling
/// lands in M5; for now it's just a solid block so collisions and positioning
/// are rock-simple.
class Ground extends PositionComponent {
  final double groundHeight;

  Ground({
    required Vector2 worldSize,
    this.groundHeight = 120,
  }) : super(
          position: Vector2(0, worldSize.y - groundHeight),
          size: Vector2(worldSize.x, groundHeight),
        );

  double get topY => position.y;

  @override
  Future<void> onLoad() async {
    add(RectangleComponent(
      size: Vector2(size.x, groundHeight),
      paint: Paint()..color = const Color(0xFF5A3A1A),
    ));
    add(RectangleComponent(
      size: Vector2(size.x, 8),
      paint: Paint()..color = const Color(0xFF3D8B4A),
    ));
  }
}
