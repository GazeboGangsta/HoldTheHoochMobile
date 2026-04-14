import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../components/ground.dart';
import '../components/gurgles.dart';
import '../components/hooch_balance.dart';
import '../components/obstacle.dart';
import '../components/parallax_bg.dart';
import '../config/game_config.dart';
import '../systems/obstacle_manager.dart';

class GameScene extends FlameGame with TapCallbacks, HasCollisionDetection {
  static const gameOverOverlayId = 'gameOver';

  late Gurgles gurgles;
  late HoochBalance balance;
  late Ground ground;
  late ObstacleManager obstacleManager;
  late TextComponent scoreText;

  double _elapsed = 0;
  int score = 0;
  bool _gameOver = false;
  String? endReason;

  @override
  Color backgroundColor() => const Color(0xFF87CEEB);

  double get currentScrollSpeed {
    final t = (_elapsed / GameConfig.difficultyRampSeconds).clamp(0.0, 1.0);
    final mult = 1.0 + t * (GameConfig.maxScrollSpeedMultiplier - 1.0);
    return GameConfig.baseScrollSpeed * mult;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final groundY = size.y - 120;

    add(ParallaxLayer(
      assetPath: 'svg/bg-mountains.svg',
      speedFactor: 0.15,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: groundY - 360,
      height: 360,
    ));
    add(ParallaxLayer(
      assetPath: 'svg/bg-trees.svg',
      speedFactor: 0.45,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: groundY - 240,
      height: 240,
    ));

    ground = Ground(
      worldSize: size,
      scrollSpeedProvider: () => currentScrollSpeed,
    );
    add(ground);

    gurgles = Gurgles(
      position: Vector2(size.x * 0.22, groundY),
      groundY: groundY,
    );
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
      position: Vector2(size.x / 2, 48),
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
    endReason = reason;
    pauseEngine();
    overlays.add(gameOverOverlayId);
  }

  /// Called from the overlay Retry button.
  Future<void> restart() async {
    overlays.remove(gameOverOverlayId);
    // Remove every obstacle from the last run.
    for (final ob in children.whereType<Obstacle>().toList()) {
      ob.removeFromParent();
    }
    _elapsed = 0;
    score = 0;
    _gameOver = false;
    endReason = null;
    gurgles.velocityY = 0;
    gurgles.position.y = size.y - 120;
    balance.tilt = 0;
    balance.spill = 0;
    resumeEngine();
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
