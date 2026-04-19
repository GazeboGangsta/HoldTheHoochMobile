import 'dart:math';
import 'package:flame/components.dart';
import '../components/collectible.dart';

/// Spawns collectibles from just off the right edge at varying heights.
/// Spawn cadence is slower than obstacles and deliberately offset so the
/// two streams don't always align.
class CollectibleManager extends Component {
  final double Function() scrollSpeedProvider;
  final double Function() worldWidthProvider;
  final double groundY;
  final double sizeScale;
  final void Function(int points, Vector2 worldPos) onPickup;
  final Random _rng = Random();

  double _timeToNext = 3.0;

  CollectibleManager({
    required this.scrollSpeedProvider,
    required this.worldWidthProvider,
    required this.groundY,
    required this.onPickup,
    this.sizeScale = 1.0,
  });

  @override
  void update(double dt) {
    super.update(dt);
    _timeToNext -= dt;
    if (_timeToNext <= 0) {
      _spawn();
      // Gaps tuned so there's usually 1-3 obstacles between each collectible.
      final speed = scrollSpeedProvider();
      final speedNorm = speed / 280.0;
      _timeToNext = (2.4 + _rng.nextDouble() * 2.0) / speedNorm;
    }
  }

  /// Weighted kind roll: herb 70%, hops 25%, potion 5%.
  CollectibleKind _rollKind() {
    final r = _rng.nextDouble();
    if (r < 0.70) return CollectibleKind.herb;
    if (r < 0.95) return CollectibleKind.hops;
    return CollectibleKind.potion;
  }

  /// Height tier per kind. Tuned so Gurgles' hitbox top at peak jump
  /// (gravity 2800, max velocity -720 → peak ~92px, plus ~116px of body
  /// clearance above his feet = ~208px reach above ground) can intersect
  /// each tier.
  /// - herb: free grab at ground level
  /// - hops: partial jump
  /// - potion: full-hold jump
  double _heightForKind(CollectibleKind k) {
    return switch (k) {
      CollectibleKind.herb => groundY - 50.0 * sizeScale,
      CollectibleKind.hops => groundY - 120.0 * sizeScale,
      CollectibleKind.potion => groundY - 180.0 * sizeScale,
    };
  }

  void _spawn() {
    final kind = _rollKind();
    final c = Collectible(
      kind: kind,
      position: Vector2(worldWidthProvider() + 80, _heightForKind(kind)),
      scrollSpeed: scrollSpeedProvider(),
      onPickup: onPickup,
      sizeScale: sizeScale,
    );
    parent?.add(c);
  }
}
