import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game_over_overlay.dart';
import 'game_scene.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameScene _game = GameScene();

  // Per-pointer routing so the jump and balance inputs don't interfere
  // when the player has both fingers down. Each pointer is either "jump"
  // (right half tap) or "balance" (left half drag) for its lifetime.
  final Set<int> _jumpPointers = {};
  final Set<int> _balancePointers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF1A1A3E),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) {
              final isRight = e.localPosition.dx > constraints.maxWidth / 2;
              if (isRight) {
                _jumpPointers.add(e.pointer);
                _game.handleJumpDown();
              } else {
                _balancePointers.add(e.pointer);
                _game.handleLeftPointerDown(e.localPosition);
              }
            },
            onPointerMove: (e) {
              if (_balancePointers.contains(e.pointer)) {
                _game.handleLeftPointerMove(e.localPosition, e.delta);
              }
            },
            onPointerUp: (e) {
              if (_jumpPointers.remove(e.pointer)) {
                _game.handleJumpUp();
              } else if (_balancePointers.remove(e.pointer)) {
                _game.handleLeftPointerUp();
              }
            },
            onPointerCancel: (e) {
              if (_jumpPointers.remove(e.pointer)) {
                _game.handleJumpUp();
              } else if (_balancePointers.remove(e.pointer)) {
                _game.handleLeftPointerUp();
              }
            },
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
