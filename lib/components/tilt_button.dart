import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum ControlButtonKind { tiltLeft, tiltRight, jump }

/// Visual-only button rendered in the bottom control strip. Hit testing is
/// done in [GameScreen] against the button's rect — this component doesn't
/// handle its own input because our pointer routing (Listener) lives one
/// layer up in the Flutter widget tree.
class TiltButton extends PositionComponent {
  final ControlButtonKind kind;

  /// External flag toggled by the scene. Controls whether the button
  /// renders as pressed.
  bool held = false;

  TiltButton({
    required super.position,
    required Vector2 size,
    required this.kind,
  }) : super(size: size);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.x * 0.22));

    final bg = Paint()
      ..color = held
          ? const Color(0xCCD4A744) // brass highlight when pressed
          : const Color(0x99000000);
    canvas.drawRRect(rrect, bg);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFD4A744);
    canvas.drawRRect(rrect, border);

    final arrow = Path();
    final cx = size.x / 2;
    final cy = size.y / 2;
    final w = size.x * 0.28;
    final h = size.y * 0.34;
    switch (kind) {
      case ControlButtonKind.tiltLeft:
        arrow.moveTo(cx - w, cy);
        arrow.lineTo(cx + w / 2, cy - h);
        arrow.lineTo(cx + w / 2, cy + h);
        break;
      case ControlButtonKind.tiltRight:
        arrow.moveTo(cx + w, cy);
        arrow.lineTo(cx - w / 2, cy - h);
        arrow.lineTo(cx - w / 2, cy + h);
        break;
      case ControlButtonKind.jump:
        arrow.moveTo(cx, cy - h);
        arrow.lineTo(cx - w, cy + h / 2);
        arrow.lineTo(cx + w, cy + h / 2);
        break;
    }
    arrow.close();

    final arrowPaint = Paint()
      ..color = held ? const Color(0xFF1A1A3E) : const Color(0xFFD4A744);
    canvas.drawPath(arrow, arrowPaint);
  }

  /// World-space rect for hit testing from the Flutter pointer layer.
  Rect get hitRect =>
      Rect.fromLTWH(position.x, position.y, size.x, size.y);
}
