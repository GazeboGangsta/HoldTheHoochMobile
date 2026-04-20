import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game_over_overlay.dart';
import 'game_scene.dart';

enum _PointerIntent { jump, tiltLeft, tiltRight }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameScene _game = GameScene();

  /// Each active pointer's intent for its lifetime. Prevents the
  /// multi-touch interference we had when the up-event handler didn't
  /// know which pointer started which action.
  final Map<int, _PointerIntent> _pointerIntents = {};

  _PointerIntent? _intentFor(Offset localPos, double width) {
    // Tilt buttons first — they sit in the bottom-left and need to
    // take priority over any broad zone.
    final leftRect = _game.isLoaded ? _game.tiltLeftButton.hitRect : null;
    final rightRect = _game.isLoaded ? _game.tiltRightButton.hitRect : null;
    if (leftRect != null && leftRect.contains(localPos)) return _PointerIntent.tiltLeft;
    if (rightRect != null && rightRect.contains(localPos)) return _PointerIntent.tiltRight;
    // Right half of screen (outside buttons) = jump.
    if (localPos.dx > width / 2) return _PointerIntent.jump;
    // Left half outside buttons is unused now (used to be drag-to-balance).
    return null;
  }

  void _onDown(int pointer, Offset localPos, double width) {
    final intent = _intentFor(localPos, width);
    if (intent == null) return;
    _pointerIntents[pointer] = intent;
    switch (intent) {
      case _PointerIntent.jump:
        _game.handleJumpDown();
        break;
      case _PointerIntent.tiltLeft:
        _game.handleTiltLeftDown();
        break;
      case _PointerIntent.tiltRight:
        _game.handleTiltRightDown();
        break;
    }
  }

  void _onUp(int pointer) {
    final intent = _pointerIntents.remove(pointer);
    switch (intent) {
      case _PointerIntent.jump:
        _game.handleJumpUp();
        break;
      case _PointerIntent.tiltLeft:
        _game.handleTiltLeftUp();
        break;
      case _PointerIntent.tiltRight:
        _game.handleTiltRightUp();
        break;
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF1A1A3E),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _onDown(e.pointer, e.localPosition, constraints.maxWidth),
            onPointerUp: (e) => _onUp(e.pointer),
            onPointerCancel: (e) => _onUp(e.pointer),
            child: GameWidget<GameScene>(
              game: _game,
              overlayBuilderMap: {
                GameScene.gameOverOverlayId: (c, g) => GameOverOverlay(
                      game: g,
                      onExitToMenu: () => Navigator.of(context).pop(),
                    ),
              },
            ),
          );
        },
      ),
    );
  }
}
