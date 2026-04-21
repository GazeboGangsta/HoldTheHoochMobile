import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
// ignore: unnecessary_import (explicit import for consistency with obstacle.dart, collectible.dart)
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart';
import '../components/collectible.dart';
import '../components/gurgles.dart';
import '../components/hooch_balance.dart';
import '../components/obstacle.dart';
import '../components/cloud_drift.dart';
import '../components/raster_parallax_layer.dart';
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

  // Allows test stubs to initialise _groundY without triggering the full
  // SVG-loading onLoad() path.
  @visibleForTesting
  set groundYForTesting(double v) => _groundY = v;

  // Matched to the top row of Pine Hills 00_background.png so there's no
  // horizontal seam where the sky layer's gradient begins. Tune if a seam
  // is visible on device (Task 6 of the Pine Hills parallax plan).
  @override
  Color backgroundColor() => const Color(0xFF77B8DC);

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
    // _groundY pinned to top of control strip: Gurgles' feet land on the
    // Pine Hills grass/dirt (layer 09/10 content sits at the bottom of the
    // play area). Previously we had an extra _groundHeight gap between
    // them, which the old SVG Ground component filled — now unused.
    _groundY = controlStripTop;

    // "Underground" backdrop for the control strip.
    add(RectangleComponent(
      position: Vector2(0, controlStripTop),
      size: Vector2(size.x, controlStripHeight),
      paint: Paint()..color = const Color(0xFF2D1A0E),
    ));

    // Pine Hills parallax stack. See docs/superpowers/plans/
    // 2026-04-21-pine-hills-parallax.md for the full layer allocation +
    // speed rationale.
    //
    // Asset paths use the `../` prefix to escape Flame's default
    // `assets/images/` cache root, resolving to
    // `assets/third_party/pine_hills/png/` which is registered in pubspec.
    final playAreaHeight = _groundY;
    const srcW = 320;
    const srcH = 180;

    // 00: static sky background (full playable area, does not scroll).
    add(RasterParallaxLayer(
      assetPath: '../third_party/pine_hills/png/00_background.png',
      speedFactor: 0.0,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: 0,
      height: playAreaHeight,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));

    // 01: back-cloud field (fills upper sky, very slow drift).
    add(RasterParallaxLayer(
      assetPath: '../third_party/pine_hills/png/01_back clouds.png',
      speedFactor: 0.03,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: 0,
      height: playAreaHeight,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));

    // 02-05: drift clouds — independent px/s velocities. Positive values
    // drift left (same direction as ground scroll); negative drifts right
    // for counter-breeze variety.
    add(CloudDrift(
      assetPath: '../third_party/pine_hills/png/02_cloud1.png',
      driftPxPerSecond: 8,
      worldSize: size,
      yPosition: 0,
      height: playAreaHeight,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));
    add(CloudDrift(
      assetPath: '../third_party/pine_hills/png/03_cloud2.png',
      driftPxPerSecond: 14,
      worldSize: size,
      yPosition: 0,
      height: playAreaHeight,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));
    add(CloudDrift(
      assetPath: '../third_party/pine_hills/png/04_cloud3.png',
      driftPxPerSecond: 22,
      worldSize: size,
      yPosition: 0,
      height: playAreaHeight,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));
    add(CloudDrift(
      assetPath: '../third_party/pine_hills/png/05_cloud4.png',
      driftPxPerSecond: -10, // counter-breeze
      worldSize: size,
      yPosition: 0,
      height: playAreaHeight,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));

    // 06: back mountains.
    add(RasterParallaxLayer(
      assetPath: '../third_party/pine_hills/png/06_back_mountains.png',
      speedFactor: 0.12,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: playAreaHeight * 0.25,
      height: playAreaHeight * 0.75,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));

    // 07: mid hills.
    add(RasterParallaxLayer(
      assetPath: '../third_party/pine_hills/png/07_mid_hills.png',
      speedFactor: 0.22,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: playAreaHeight * 0.35,
      height: playAreaHeight * 0.65,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));

    // 08: mid forest.
    add(RasterParallaxLayer(
      assetPath: '../third_party/pine_hills/png/08_mid_forest.png',
      speedFactor: 0.40,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: playAreaHeight * 0.45,
      height: playAreaHeight * 0.55,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));


    // 11 front_trees1 added BEFORE Gurgles → renders behind him. Gives the
    // scene a midground-tree beat without occluding the player. Layer 12
    // is still added after Gurgles for one layer of depth occlusion.
    add(RasterParallaxLayer(
      assetPath: '../third_party/pine_hills/png/11_front_trees1.png',
      speedFactor: 0.85,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: playAreaHeight * 0.50,
      height: playAreaHeight * 0.50,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));

    final gurglesHeight = size.y * 0.18;
    final gurglesWidth = gurglesHeight * 0.8;
    gurgles = Gurgles(
      position: Vector2(size.x * 0.22, _groundY),
      groundY: _groundY,
      size: Vector2(gurglesWidth, gurglesHeight),
    );
    gurgles.onObstacleHit = () => _end('Hit an obstacle!');
    add(gurgles);

    // 09-13: foreground layers inserted after Gurgles so they occlude him
    // for depth, but before gameplay managers so obstacles/collectibles render
    // on top (visible through the foliage).
    add(RasterParallaxLayer(
      assetPath: '../third_party/pine_hills/png/09_front_grass.png',
      speedFactor: 1.0,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: playAreaHeight * 0.80,
      height: playAreaHeight * 0.20,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));
    add(RasterParallaxLayer(
      assetPath: '../third_party/pine_hills/png/10_front_leafs.png',
      speedFactor: 1.0,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: playAreaHeight * 0.80,
      height: playAreaHeight * 0.20,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));
    add(RasterParallaxLayer(
      assetPath: '../third_party/pine_hills/png/12_front_trees2.png',
      speedFactor: 0.92,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: playAreaHeight * 0.55,
      height: playAreaHeight * 0.45,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));
    add(RasterParallaxLayer(
      assetPath: '../third_party/pine_hills/png/13_front_rocks.png',
      speedFactor: 1.0,
      worldSpeedProvider: () => currentScrollSpeed,
      worldSize: size,
      yPosition: playAreaHeight * 0.85,
      height: playAreaHeight * 0.15,
      sourceWidth: srcW,
      sourceHeight: srcH,
    ));

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
