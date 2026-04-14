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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF87CEEB),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) {
              if (e.localPosition.dx > constraints.maxWidth / 2) {
                _game.handleJumpDown();
              } else {
                _game.handleLeftPointerDown(e.localPosition);
              }
            },
            onPointerMove: (e) {
              if (e.localPosition.dx <= constraints.maxWidth / 2) {
                _game.handleLeftPointerMove(e.localPosition, e.delta);
              }
            },
            onPointerUp: (_) {
              _game.handleJumpUp();
              _game.handleLeftPointerUp();
            },
            onPointerCancel: (_) {
              _game.handleJumpUp();
              _game.handleLeftPointerUp();
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
