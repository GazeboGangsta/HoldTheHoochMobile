import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../components/ground.dart';
import '../components/gurgles.dart';
import '../components/hooch_balance.dart';
import '../config/game_config.dart';
import '../systems/obstacle_manager.dart';
import '../utils/routes.dart';
import 'game_over_screen.dart';

class GameScene extends FlameGame with TapCallbacks, HasCollisionDetection {
  late final Gurgles gurgles;
  late final HoochBalance balance;
  late final Ground ground;
  late final ObstacleManager obstacleManager;
  late final TextComponent scoreText;

  double _elapsed = 0;
  int score = 0;
  bool _gameOver = false;
  BuildContext? _ctx;

  @override
  Color backgroundColor() => const Color(0xFF87CEEB);

  double get currentScrollSpeed {
    final t = (_elapsed / GameConfig.difficultyRampSeconds).clamp(0.0, 1.0);
    final mult = 1.0 + t * (GameConfig.maxScrollSpeedMultiplier - 1.0);
    return GameConfig.baseScrollSpeed * mult;
  }

  void attachContext(BuildContext ctx) => _ctx = ctx;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final groundY = size.y - 120;
    ground = Ground(worldSize: size);
    add(ground);

    gurgles = Gurgles(
      position: Vector2(size.x * 0.25, groundY),
      groundY: groundY,
    )..paint = (Paint()..color = const Color(0xFF3D8B4A));
    gurgles.onObstacleHit = () => _end('Hit an obstacle!');
    add(gurgles);

    balance = HoochBalance();
    add(balance);

    obstacleManager = ObstacleManager(
      scrollSpeedProvider: () => currentScrollSpeed,
      worldWidthProvider: () => size.x,
      groundY: groundY,
    );
    add(obstacleManager);

    scoreText = TextComponent(
      text: '0',
      position: Vector2(size.x / 2, 40),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(scoreText);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameOver) return;
    _elapsed += dt;
    score = (_elapsed * 10).floor();
    scoreText.text = '$score';
    if (balance.hasSpilled) _end('You spilled the hooch!');
  }

  void _end(String reason) {
    if (_gameOver) return;
    _gameOver = true;
    pauseEngine();
    final ctx = _ctx;
    if (ctx != null) {
      Navigator.of(ctx).pushReplacement(
        fadeRoute(GameOverScreen(score: score, reason: reason)),
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_gameOver) return;
    final isRight = event.localPosition.x > size.x / 2;
    if (isRight) {
      gurgles.startJump();
      balance.applyJumpImpulse();
    }
  }

  @override
  void onTapUp(TapUpEvent event) => gurgles.endJump();

  @override
  void onTapCancel(TapCancelEvent event) => gurgles.endJump();
}
