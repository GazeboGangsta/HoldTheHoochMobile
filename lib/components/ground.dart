import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Infinite scrolling ground. Two tiles side-by-side, swapped as they scroll off.
class Ground extends PositionComponent {
  final double groundHeight;
  double _scrollOffset = 0;
  final double tileWidth;

  Ground({
    required Vector2 worldSize,
    this.groundHeight = 120,
    this.tileWidth = 256,
  }) : super(size: worldSize);

  @override
  Future<void> onLoad() async {
    position = Vector2(0, size.y - groundHeight);
    final earth = RectangleComponent(
      size: Vector2(size.x, groundHeight),
      paint: Paint()..color = const Color(0xFF5A3A1A),
    );
    add(earth);
    final grass = RectangleComponent(
      size: Vector2(size.x, 16),
      paint: Paint()..color = const Color(0xFF3D8B4A),
    );
    add(grass);
  }

  void scroll(double dx) {
    _scrollOffset = (_scrollOffset + dx) % tileWidth;
  }

  double get topY => position.y;
}
