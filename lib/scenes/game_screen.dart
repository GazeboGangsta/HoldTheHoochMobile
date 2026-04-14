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
      body: SizedBox.expand(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) {
            final w = MediaQuery.of(context).size.width;
            if (d.localPosition.dx > w / 2) {
              _game.handleJumpDown();
            }
          },
          onTapUp: (_) => _game.handleJumpUp(),
          onTapCancel: () => _game.handleJumpUp(),
          child: GameWidget<GameScene>(
            game: _game,
            overlayBuilderMap: {
              GameScene.gameOverOverlayId: (ctx, game) => GameOverOverlay(
                    game: game,
                    onExitToMenu: () => Navigator.of(context).pop(),
                  ),
            },
          ),
        ),
      ),
    );
  }
}
