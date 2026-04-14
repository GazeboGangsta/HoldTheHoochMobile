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
      body: GameWidget<GameScene>(
        game: _game,
        overlayBuilderMap: {
          GameScene.gameOverOverlayId: (ctx, game) => GameOverOverlay(
                game: game,
                onExitToMenu: () => Navigator.of(context).pop(),
              ),
        },
      ),
    );
  }
}
