import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show VoidCallback;
import '../components/collectible.dart';

/// Spawns collectibles from just off the right edge at varying heights.
/// Weighted-kind roll + per-kind sprite-variant RNG.
class CollectibleManager extends Component {
  final double Function() scrollSpeedProvider;
  final double Function() worldWidthProvider;
  final double groundY;
  final double sizeScale;
  final void Function(int points, Vector2 worldPos, CollectibleKind kind) onPickup;
  final VoidCallback? onPotionBonus;
  final Random _rng;

  double _timeToNext = 3.0;

  CollectibleManager({
    required this.scrollSpeedProvider,
    required this.worldWidthProvider,
    required this.groundY,
    required this.onPickup,
    this.onPotionBonus,
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
      final speedNorm = speed / 280.0;
      _timeToNext = (2.4 + _rng.nextDouble() * 2.0) / speedNorm;
    }
  }

  /// Weighted kind roll:
  ///   fruitCommon  55%
  ///   fruitMedium  25%
  ///   fruitRare    10%
  ///   crystal       5%
  ///   potion        5%
  CollectibleKind _rollKind() {
    final r = _rng.nextDouble();
    if (r < 0.55) return CollectibleKind.fruitCommon;
    if (r < 0.80) return CollectibleKind.fruitMedium;
    if (r < 0.90) return CollectibleKind.fruitRare;
    if (r < 0.95) return CollectibleKind.crystal;
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
      CollectibleKind.fruitRare => groundY - 225.0 * sizeScale,
      CollectibleKind.crystal => groundY - 180.0 * sizeScale,
      CollectibleKind.potion => groundY - 180.0 * sizeScale,
    };
  }

  void _spawn() {
    final kind = _rollKind();
    final variants = Collectible.spritePathsFor(kind);
    final spritePath = variants[_rng.nextInt(variants.length)];
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
