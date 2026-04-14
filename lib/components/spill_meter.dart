import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'hooch_balance.dart';

/// Horizontal progress bar that fills red as the hooch approaches a spill.
class SpillMeter extends PositionComponent {
  final HoochBalance balance;
  late final RectangleComponent _frame;
  late final RectangleComponent _fill;

  SpillMeter({
    required super.size,
    required super.position,
    required super.anchor,
    required this.balance,
  });

  @override
  Future<void> onLoad() async {
    _frame = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = const Color(0xCC2A1A10)
        ..style = PaintingStyle.fill,
    );
    add(_frame);

    final border = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = const Color(0xFFD4A744)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    add(border);

    _fill = RectangleComponent(
      size: Vector2(0, size.y - 4),
      position: Vector2(2, 2),
      paint: Paint()..color = const Color(0xFFE74C3C),
    );
    add(_fill);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _fill.size.x = (size.x - 4) * balance.spillPercent;
  }
}
