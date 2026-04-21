import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show VoidCallback;
import '../components/collectible.dart';

/// Spawns collectibles from just off the right edge at varying heights.
/// Spawn cadence is slower than obstacles and deliberately offset so the
/// two streams don't always align.
class CollectibleManager extends Component {
  final double Function() scrollSpeedProvider;
  final double Function() worldWidthProvider;
  final double groundY;
  final double sizeScale;
  final void Function(int points, Vector2 worldPos, CollectibleKind kind) onPickup;
  final VoidCallback? onPotionBonus;
  final Random _rng = Random();

  double _timeToNext = 3.0;

  CollectibleManager({
    required this.scrollSpeedProvider,
    required this.worldWidthProvider,
    required this.groundY,
    required this.onPickup,
    this.onPotionBonus,
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

  /// Weighted kind roll: fruitCommon 70%, fruitMedium 25%, potion 5%.
  /// Task 6 expands to a 5-way roll including fruitRare and crystal.
  CollectibleKind _rollKind() {
    final r = _rng.nextDouble();
    if (r < 0.70) return CollectibleKind.fruitCommon;
    if (r < 0.95) return CollectibleKind.fruitMedium;
    return CollectibleKind.potion;
  }

  /// Height tier per kind. Tuned so Gurgles' hitbox top at peak jump
  /// (gravity 2800, max velocity -720 → peak ~92px, plus ~116px of body
  /// clearance above his feet = ~208px reach above ground) can intersect
  /// each tier.
  /// - fruitCommon: free grab at ground level
  /// - fruitMedium: partial jump
  /// - fruitRare: partial jump (same tier as fruitMedium for now)
  /// - crystal / potion: full-hold jump
  double _heightForKind(CollectibleKind k) {
    return switch (k) {
      CollectibleKind.fruitCommon => groundY - 50.0 * sizeScale,
      CollectibleKind.fruitMedium => groundY - 120.0 * sizeScale,
      CollectibleKind.fruitRare => groundY - 120.0 * sizeScale,
      CollectibleKind.crystal => groundY - 180.0 * sizeScale,
      CollectibleKind.potion => groundY - 180.0 * sizeScale,
    };
  }

  void _spawn() {
    final kind = _rollKind();
    final paths = Collectible.spritePathsFor(kind);
    final spritePath = paths[_rng.nextInt(paths.length)];
    final c = Collectible(
      kind: kind,
      spritePath: spritePath,
      position: Vector2(worldWidthProvider() + 80, _heightForKind(kind)),
      scrollSpeed: scrollSpeedProvider(),
      onPickup: (pts, at) => onPickup(pts, at, kind),
      onPotionBonus: onPotionBonus,
      sizeScale: sizeScale,
    );
    parent?.add(c);
  }
}
