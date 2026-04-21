import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
// ignore: unnecessary_import (explicit import for consistency with obstacle.dart, collectible.dart)
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart';
import '../components/collectible.dart';
import '../components/ground.dart';
import '../components/gurgles.dart';
import '../components/hooch_balance.dart';
import '../components/obstacle.dart';
import '../components/parallax_bg.dart';
import '../components/score_popup.dart';
import '../components/sparkle_burst.dart';
import '../components/splash_emitter.dart';
import '../components/spill_meter.dart';
import '../components/tilt_button.dart' show TiltButton, ControlButtonKind;
import '../config/game_config.dart';
import '../systems/collectible_manager.dart';
import '../systems/obstacle_manager.dart';

class GameScene extends FlameGame with HasCollisionDetection {
  static const gameOverOverlayId = 'gameOver';

  late Gurgles gurgles;
  late HoochBalance balance;
  late SplashEmitter splashEmitter;
  late Ground ground;
  late ObstacleManager obstacleManager;
  late CollectibleManager collectibleManager;
  late TextComponent scoreText;
  late SpillMeter spillMeter;
  late TiltButton tiltLeftButton;
  late TiltButton tiltRightButton;
  late TiltButton jumpButton;

  bool _tiltLeftHeld = false;
  bool _tiltRightHeld = false;

  double _elapsed = 0;
  int _collectiblePoints = 0;
  int score = 0;
  bool _gameOver = false;
  String? endReason;
  late double _groundY;
  late double _groundHeight;

  // Allows test stubs to initialise _groundY without triggering the full
  // SVG-loading onLoad() path.
  @visibleForTesting
  set groundYForTesting(double v) => _groundY = v;

  // Match bg-mountains.svg's gradient top color — otherwise you get a hard
  // horizontal seam where the light sky-blue Flame backdrop meets the
  // mountain layer's dark night sky.
  @override
  Color backgroundColor() => const Color(0xFF1A1A3E);

  double get currentScrollSpeed {
    final t = (_elapsed / GameConfig.difficultyRampSeconds).clamp(0.0, 1.0);
    final mult = 1.0 + t * (GameConfig.maxScrollSpeedMultiplier - 1.0);
    return GameConfig.baseScrollSpeed * mult;
  }

  /// Score multiplier as a pure function of survival time.
  /// Starts at 1.0, steps +0.1 every [GameConfig.scoreMultiplierIntervalSeconds],
  /// capped at [GameConfig.scoreMultiplierMax].
  static double multiplierFor(double elapsed) {
    final raw = 1.0 +
        (elapsed / GameConfig.scoreMultiplierIntervalSeconds).floor() *
            GameConfig.scoreMultiplierStep;
    return raw.clamp(1.0, GameConfig.scoreMultiplierMax);
  }

  double get currentMultiplier => multiplierFor(_elapsed);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Flame 1.37's default CameraComponent has a viewfinder anchored at
    // center; pin to top-left so our layout math (origin top-left) renders
    // where we expect.
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();

    final controlStripHeight = size.y * GameConfig.controlStripHeightFraction;
    final controlStripTop = size.y - controlStripHeight;
    _groundHeight = size.y * 0.06;
    _groundY = controlStripTop - _groundHeight;

    // "Underground" backdrop for the control strip.
    add(RectangleComponent(
      position: Vector2(0, controlStripTop),
      size: Vector2(size.x, controlStripHeight),
      paint: Paint()..color = const Color(0xFF2D1A0E),
    ));

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

    // Pass a truncated worldSize so Ground pins to the top of the control
    // strip instead of the bottom of the screen.
    ground = Ground(
      worldSize: Vector2(size.x, controlStripTop),
      groundHeight: _groundHeight,
      scrollSpeedProvider: () => currentScrollSpeed,
    );
    add(ground);

    final gurglesHeight = size.y * 0.18;
    final gurglesWidth = gurglesHeight * 0.8;
    gurgles = Gurgles(
      position: Vector2(size.x * 0.22, _groundY),
      groundY: _groundY,
      size: Vector2(gurglesWidth, gurglesHeight),
    );
    gurgles.onObstacleHit = () => _end('Hit an obstacle!');
    add(gurgles);

    balance = HoochBalance();
    balance.setDriftDirection(Random().nextBool() ? 1.0 : -1.0);
    add(balance);

    splashEmitter = SplashEmitter(gurgles: gurgles, balance: balance);
    add(splashEmitter);

    obstacleManager = ObstacleManager(
      scrollSpeedProvider: () => currentScrollSpeed,
      worldWidthProvider: () => size.x,
      groundY: _groundY,
      sizeScale: size.y / 900,
    );
    add(obstacleManager);

    collectibleManager = CollectibleManager(
      scrollSpeedProvider: () => currentScrollSpeed,
      worldWidthProvider: () => size.x,
      groundY: _groundY,
      sizeScale: size.y / 900,
      onPickup: (points, at, kind) {
        _collectiblePoints += points;
        add(ScorePopup(points: points, position: at.clone()));
        add(SparkleBurst.emit(kind, at.clone()));
      },
      onPotionBonus: () =>
          balance.grantSpillDrain(const Duration(milliseconds: 1000)),
    );
    add(collectibleManager);

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

    spillMeter = SpillMeter(
      size: Vector2(size.x * 0.6, 14),
      position: Vector2(size.x * 0.5, size.y * 0.14),
      anchor: Anchor.topCenter,
      balance: balance,
    );
    add(spillMeter);

    // Three control buttons: tilt-left, tilt-right on the left side of the
    // strip; jump on the right. All vertically centered in the strip.
    final btnSize = Vector2.all(GameConfig.tiltButtonSize);
    final btnY = controlStripTop + (controlStripHeight - btnSize.y) / 2;
    tiltLeftButton = TiltButton(
      position: Vector2(GameConfig.tiltButtonInset, btnY),
      size: btnSize,
      kind: ControlButtonKind.tiltLeft,
    );
    tiltRightButton = TiltButton(
      position: Vector2(
        GameConfig.tiltButtonInset + btnSize.x + GameConfig.tiltButtonGap,
        btnY,
      ),
      size: btnSize,
      kind: ControlButtonKind.tiltRight,
    );
    jumpButton = TiltButton(
      position: Vector2(
        size.x - GameConfig.tiltButtonInset - btnSize.x,
        btnY,
      ),
      size: btnSize,
      kind: ControlButtonKind.jump,
    );
    add(tiltLeftButton);
    add(tiltRightButton);
    add(jumpButton);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameOver) return;
    _elapsed += dt;
    balance.applyDifficulty(_elapsed / GameConfig.difficultyRampSeconds);
    if (_tiltLeftHeld) {
      balance.applyTiltTorque(-GameConfig.tiltButtonTorqueRate * dt);
    }
    if (_tiltRightHeld) {
      balance.applyTiltTorque(GameConfig.tiltButtonTorqueRate * dt);
    }
    gurgles.setTankardAngle(Gurgles.tankardAngleForTilt(balance.tilt));
    final mult = currentMultiplier;
    score = (_elapsed * 10 * mult).floor() + _collectiblePoints;
    scoreText.text = mult > 1.0
        ? '$score  ×${mult.toStringAsFixed(1)}'
        : '$score';
    if (balance.hasSpilled) _end('You spilled the hooch!', fromSpill: true);
  }

  void _end(String reason, {bool fromSpill = false}) {
    if (_gameOver) return;
    _gameOver = true;
    endReason = reason;

    gurgles.triggerHurt();
    if (fromSpill) splashEmitter.emitGameOverBurst();

    // Wait for the hurt animation + (if spilling) the splash flourish before
    // showing the overlay. The engine keeps running during the delay so both
    // play; _gameOver (set above) blocks further update() logic, and the
    // overlay hasn't been added yet, so the player can't retry mid-delay.
    Future.delayed(
      Duration(milliseconds: GameConfig.gameOverHurtDelayMs),
      () {
        if (!isAttached) return;
        pauseEngine();
        overlays.add(gameOverOverlayId);
      },
    );
  }

  Future<void> restart() async {
    overlays.remove(gameOverOverlayId);
    for (final ob in children.whereType<Obstacle>().toList()) {
      ob.removeFromParent();
    }
    for (final c in children.whereType<Collectible>().toList()) {
      c.removeFromParent();
    }
    for (final p in children.whereType<ScorePopup>().toList()) {
      p.removeFromParent();
    }
    for (final p in children.whereType<ParticleSystemComponent>().toList()) {
      p.removeFromParent();
    }
    splashEmitter.reset();
    _elapsed = 0;
    _collectiblePoints = 0;
    score = 0;
    _gameOver = false;
    endReason = null;
    gurgles.velocityY = 0;
    gurgles.position.y = _groundY;
    balance.tilt = 0;
    balance.spill = 0;
    balance.resetPhase();
    balance.setDriftDirection(Random().nextBool() ? 1.0 : -1.0);
    gurgles.resetAnimator();
    resumeEngine();
  }

  void handleJumpDown() {
    if (_gameOver) return;
    jumpButton.held = true;
    gurgles.startJump();
    balance.applyJumpImpulse();
  }

  void handleJumpUp() {
    jumpButton.held = false;
    gurgles.endJump();
  }

  /// Bottom-left tilt-correction buttons. GameScreen's pointer routing
  /// hit-tests against [tiltLeftButton.hitRect] / [tiltRightButton.hitRect]
  /// and calls these.
  void handleTiltLeftDown() {
    if (_gameOver) return;
    _tiltLeftHeld = true;
    tiltLeftButton.held = true;
  }

  void handleTiltLeftUp() {
    _tiltLeftHeld = false;
    tiltLeftButton.held = false;
  }

  void handleTiltRightDown() {
    if (_gameOver) return;
    _tiltRightHeld = true;
    tiltRightButton.held = true;
  }

  void handleTiltRightUp() {
    _tiltRightHeld = false;
    tiltRightButton.held = false;
  }
}
