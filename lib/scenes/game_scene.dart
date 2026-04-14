import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../components/ground.dart';
import '../components/gurgles.dart';
import '../components/hooch_balance.dart';
import '../components/obstacle.dart';
import '../components/parallax_bg.dart';
import '../config/game_config.dart';
import '../systems/obstacle_manager.dart';

/// Top-level game. All sizes below derive from `size.y` (screen height) so
/// the game scales 1:1 across phones of different densities.
class GameScene extends FlameGame with HasCollisionDetection {
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
  late double _groundY;
  late double _groundHeight;

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

    // All layout percentages keyed to the screen height.
    _groundHeight = size.y * 0.08;
    _groundY = size.y - _groundHeight;

    final mountainsHeight = size.y * 0.42;
    final treesHeight = size.y * 0.32;

    add(ParallaxLayer(
      assetPath: 'svg/bg-mountains.svg',
      speedFactor: 0.15,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: _groundY - mountainsHeight,
      height: mountainsHeight,
    ));
    add(ParallaxLayer(
      assetPath: 'svg/bg-trees.svg',
      speedFactor: 0.45,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: _groundY - treesHeight,
      height: treesHeight,
    ));

    ground = Ground(
      worldSize: size,
      groundHeight: _groundHeight,
      scrollSpeedProvider: () => currentScrollSpeed,
    );
    add(ground);

    final gurglesHeight = size.y * 0.18;
    final gurglesWidth = gurglesHeight * 0.8;
    gurgles = Gurgles(
      position: Vector2(size.x * 0.22, _groundY),
      groundY: _groundY,
    )..size = Vector2(gurglesWidth, gurglesHeight);
    gurgles.onObstacleHit = () => _end('Hit an obstacle!');
    add(gurgles);

    balance = HoochBalance();
    add(balance);

    obstacleManager = ObstacleManager(
      scrollSpeedProvider: () => currentScrollSpeed,
      worldWidthProvider: () => size.x,
      groundY: _groundY,
      sizeScale: size.y / 900,
    );
    add(obstacleManager);

    scoreText = TextComponent(
      text: '0',
      position: Vector2(size.x / 2, size.y * 0.05),
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

  Future<void> restart() async {
    overlays.remove(gameOverOverlayId);
    for (final ob in children.whereType<Obstacle>().toList()) {
      ob.removeFromParent();
    }
    _elapsed = 0;
    score = 0;
    _gameOver = false;
    endReason = null;
    gurgles.velocityY = 0;
    gurgles.position.y = _groundY;
    balance.tilt = 0;
    balance.spill = 0;
    resumeEngine();
  }

  void handleJumpDown() {
    if (_gameOver) return;
    gurgles.startJump();
    balance.applyJumpImpulse();
  }

  void handleJumpUp() => gurgles.endJump();
}
