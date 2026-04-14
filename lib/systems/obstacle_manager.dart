import 'dart:math';
import 'package:flame/components.dart';
import '../components/obstacle.dart';

/// Spawns obstacles at speed-dependent intervals from just off the right edge.
class ObstacleManager extends Component {
  final double Function() scrollSpeedProvider;
  final double Function() worldWidthProvider;
  final double groundY;
  final Random _rng = Random();

  double _timeToNext = 1.5;

  ObstacleManager({
    required this.scrollSpeedProvider,
    required this.worldWidthProvider,
    required this.groundY,
  });

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

  void _spawn() {
    final kinds = ObstacleKind.values;
    final kind = kinds[_rng.nextInt(kinds.length)];
    final ob = Obstacle(
      kind: kind,
      position: Vector2(worldWidthProvider() + 80, groundY),
      scrollSpeed: scrollSpeedProvider(),
    );
    parent?.add(ob);
  }
}
