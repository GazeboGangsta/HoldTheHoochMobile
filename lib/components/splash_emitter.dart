import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import '../config/game_config.dart';
import 'gurgles.dart';
import 'hooch_balance.dart';

/// Emits hooch droplet particles whenever the tankard tilts past
/// [GameConfig.spillThreshold]. Emission pattern is hybrid:
/// - **Burst** (splashBurstCount) on each threshold entry (edge-triggered)
/// - **Trickle** at a rate that scales linearly with how far over threshold
///   the tilt sits (splashTrickleRateBase → splashTrickleRateMax)
/// - **Game-over burst** (splashGameOverBurstCount, wider spread, larger
///   radii) via explicit [emitGameOverBurst] call
///
/// Call [reset] on restart to clear the edge detector and rate accumulator.
class SplashEmitter extends Component {
  final Gurgles gurgles;
  final HoochBalance balance;
  final Random _rng;

  bool _wasOverThreshold = false;
  double _continuousAccum = 0;

  /// Running count of [ParticleSystemComponent]s ever emitted. Each call to
  /// [_emitBurst] increments this by 1 regardless of how many droplet
  /// particles the burst carries. Useful for rate-verification in tests where
  /// expired PSCs have already been removed from the component tree.
  int totalEmitted = 0;

  // Emissions built during update() are deferred and added in updateTree()
  // AFTER the children-iteration loop, preventing concurrent-modification
  // errors in both the test harness (where isMounted is always false, so
  // Component._addChild takes the direct-add branch) and in production.
  final _pendingEmissions = <ParticleSystemComponent>[];

  SplashEmitter({
    required this.gurgles,
    required this.balance,
    Random? rng,
  }) : _rng = rng ?? Random();

  @override
  void updateTree(double dt) {
    // Drive our own update first (edge detection + accumulator).
    update(dt);
    // Snapshot children before iterating: in the test harness (no GameWidget,
    // isMounted always false) PSC.removeFromParent() modifies _internalChildren
    // directly rather than going through the lifecycle queue, causing a
    // ConcurrentModificationError if we use the live OrderedSet iterator.
    final snapshot = children.toList(growable: false);
    for (final child in snapshot) {
      child.updateTree(dt);
    }
    // Flush new emissions after iteration — safe because no set is being walked.
    for (final psc in _pendingEmissions) {
      add(psc);
    }
    _pendingEmissions.clear();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final over = balance.tilt.abs() > GameConfig.spillThreshold;

    if (over && !_wasOverThreshold) {
      _emitBurst(GameConfig.splashBurstCount, gameOver: false);
    }
    _wasOverThreshold = over;

    if (over) {
      final excess = (balance.tilt.abs() - GameConfig.spillThreshold) /
          (1.0 - GameConfig.spillThreshold);
      final rate = GameConfig.splashTrickleRateBase +
          excess *
              (GameConfig.splashTrickleRateMax -
                  GameConfig.splashTrickleRateBase);
      _continuousAccum += rate * dt;
      while (_continuousAccum >= 1.0) {
        _emitBurst(1, gameOver: false);
        _continuousAccum -= 1.0;
      }
    } else {
      _continuousAccum = 0;
    }
  }

  void emitGameOverBurst() {
    _emitBurstNow(GameConfig.splashGameOverBurstCount, gameOver: true);
  }

  void reset() {
    _wasOverThreshold = false;
    _continuousAccum = 0;
    totalEmitted = 0;
  }

  /// Queues a burst into [_pendingEmissions] for deferred add after the
  /// current children-iteration completes (called from [update]).
  void _emitBurst(int count, {required bool gameOver}) {
    _pendingEmissions.add(_buildBurst(count, gameOver: gameOver));
    totalEmitted++;
  }

  /// Immediately adds a burst as a child (safe to call outside [updateTree]).
  void _emitBurstNow(int count, {required bool gameOver}) {
    add(_buildBurst(count, gameOver: gameOver));
    totalEmitted++;
  }

  ParticleSystemComponent _buildBurst(int count, {required bool gameOver}) {
    final origin = gurgles.tankardRimWorldPosition(balance.tilt);
    // Base velocity direction: sideways in the tilt direction + small upward pop.
    final tiltSign = balance.tilt == 0 ? 1.0 : balance.tilt.sign;
    final baseAngle = atan2(-0.6, tiltSign);
    final spread = gameOver ? pi / 3 : pi / 12; // 60° or 15°
    final speedMin = gameOver ? GameConfig.splashSpeedMin + 20 : GameConfig.splashSpeedMin;
    final speedMax = gameOver ? GameConfig.splashSpeedMax + 40 : GameConfig.splashSpeedMax;
    final radiusMin = gameOver ? 4.0 : 3.0;
    final radiusMax = gameOver ? 7.0 : 5.0;
    final lifespanMin = gameOver ? 0.9 : 0.6;
    final lifespanMax = gameOver ? 1.2 : 0.9;

    final particles = <Particle>[
      for (var i = 0; i < count; i++)
        _droplet(
          origin: origin,
          baseAngle: baseAngle,
          spread: spread,
          speedMin: speedMin,
          speedMax: speedMax,
          radius: radiusMin + _rng.nextDouble() * (radiusMax - radiusMin),
          lifespan: lifespanMin + _rng.nextDouble() * (lifespanMax - lifespanMin),
          creamHighlight: i % 3 == 0,
        ),
    ];
    return ParticleSystemComponent(
      particle: ComposedParticle(children: particles),
    );
  }

  /// Single amber droplet with closed-form ballistic motion:
  /// `pos(t) = origin + v0 * t + 0.5 * g * t²`.
  /// Every third droplet additionally renders a small cream highlight
  /// for foam-on-amber texture. Both circles fade together.
  Particle _droplet({
    required Vector2 origin,
    required double baseAngle,
    required double spread,
    required double speedMin,
    required double speedMax,
    required double radius,
    required double lifespan,
    required bool creamHighlight,
  }) {
    final angle = baseAngle + (_rng.nextDouble() * 2 - 1) * spread;
    final speed = speedMin + _rng.nextDouble() * (speedMax - speedMin);
    final v0 = Vector2(cos(angle), sin(angle)) * speed;
    final creamOffset = creamHighlight
        ? Vector2(
            (_rng.nextDouble() * 2 - 1) * 2,
            (_rng.nextDouble() * 2 - 1) * 2,
          )
        : Vector2.zero();
    const amber = Color(0xFFD4A017);
    const cream = Color(0xFFFFF9C4);

    return ComputedParticle(
      lifespan: lifespan,
      renderer: (canvas, particle) {
        final t = particle.progress * lifespan;
        final cx = origin.x + v0.x * t;
        final cy = origin.y + v0.y * t + 0.5 * GameConfig.splashGravity * t * t;
        final alpha = (255 * (1 - particle.progress)).round().clamp(0, 255);
        if (creamHighlight) {
          final creamPaint = Paint()..color = cream.withAlpha(alpha);
          canvas.drawCircle(
            Offset(cx + creamOffset.x, cy + creamOffset.y),
            2,
            creamPaint,
          );
        }
        final amberPaint = Paint()..color = amber.withAlpha(alpha);
        canvas.drawCircle(Offset(cx, cy), radius, amberPaint);
      },
    );
  }
}
