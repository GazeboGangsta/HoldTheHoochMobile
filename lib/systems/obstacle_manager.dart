import 'dart:math';
import 'package:flame/components.dart';
import '../components/obstacle.dart';

/// Spawns obstacles at speed-dependent intervals from just off the right edge.
class ObstacleManager extends Component {
  final double Function() scrollSpeedProvider;
  final double Function() worldWidthProvider;
  final double groundY;
  final double sizeScale;
  final Random _rng;

  double _timeToNext = 1.5;

  ObstacleManager({
    required this.scrollSpeedProvider,
    required this.worldWidthProvider,
    required this.groundY,
    this.sizeScale = 1.0,
    Random? rng,
  }) : _rng = rng ?? Random();

  @override
  void update(double dt) {
    super.update(dt);
    _timeToNext -= dt;
    if (_timeToNext <= 0) {
      _spawn();
      final speed = scrollSpeedProvider();
      final minGap = 80.0 / (speed / 280.0);
      final maxGap = 200.0 / (speed / 280.0);
      _timeToNext = (minGap + _rng.nextDouble() * (maxGap - minGap)) / 100.0 + 0.6;
    }
  }

  /// Weighted obstacle roll:
  ///   stone     35%  (small, frequent)
  ///   rock      25%
  ///   mushroom  20%
  ///   log       20%
  ObstacleKind _rollKind() {
    final r = _rng.nextDouble();
    if (r < 0.35) return ObstacleKind.stone;
    if (r < 0.60) return ObstacleKind.rock;
    if (r < 0.80) return ObstacleKind.mushroom;
    return ObstacleKind.log;
  }

  void _spawn() {
    final kind = _rollKind();
    final ob = Obstacle(
      kind: kind,
      position: Vector2(
        worldWidthProvider() + 80,
        groundY + Obstacle.yOffsetFor(kind),
      ),
      scrollSpeed: scrollSpeedProvider(),
      sizeScale: sizeScale,
    );
    parent?.add(ob);
  }
}
