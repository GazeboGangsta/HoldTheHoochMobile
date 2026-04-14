import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game_scene.dart';

/// Widget wrapper that hosts the Flame game and hands it a BuildContext so
/// the game can navigate to GameOverScreen without smuggling widgets into Flame.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameScene _game;

  @override
  void initState() {
    super.initState();
    _game = GameScene();
  }

  @override
  Widget build(BuildContext context) {
    _game.attachContext(context);
    return Scaffold(body: GameWidget(game: _game));
  }
}
