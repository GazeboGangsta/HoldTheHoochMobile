import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import '../config/game_config.dart';
import 'collectible.dart';

/// Fire-and-forget sparkle burst played on collectible pickup. Tinted and
/// sized per [CollectibleKind]: herb = small green, hops = medium gold,
/// potion = large blue plus an expanding halo ring.
class SparkleBurst {
  static final Random _rng = Random();

  /// Build a self-removing ParticleSystemComponent positioned at [at].
  /// Add the returned component to the scene to play the burst.
  static ParticleSystemComponent emit(CollectibleKind kind, Vector2 at) {
    final cfg = configFor(kind);
    final particles = <Particle>[
      for (var i = 0; i < cfg.count; i++) _sparkle(cfg, at),
    ];
    if (kind == CollectibleKind.potion) {
      particles.add(_potionHalo(at));
    }
    return ParticleSystemComponent(
      particle: ComposedParticle(children: particles),
    );
  }

  @visibleForTesting
  static ({int count, double radius, Color colour, double lifespan}) configFor(
    CollectibleKind kind,
  ) =>
      switch (kind) {
        CollectibleKind.herb => (
            count: 6,
            radius: 2.0,
            colour: const Color(0xFF4CAF50),
            lifespan: 0.5,
          ),
        CollectibleKind.hops => (
            count: 10,
            radius: 3.0,
            colour: const Color(0xFFFFD700),
            lifespan: 0.7,
          ),
        CollectibleKind.potion => (
            count: 16,
            radius: 4.0,
            colour: const Color(0xFF00BFFF),
            lifespan: 1.0,
          ),
      };

  /// Single sparkle with closed-form exponential-decay outward motion.
  /// Position at time t is `at + v0 * (1 - e^(-kt)) / k` where k is the
  /// deceleration rate. Alpha ramps linearly 255 → 0 across the lifespan.
  static Particle _sparkle(
    ({int count, double radius, Color colour, double lifespan}) cfg,
    Vector2 at,
  ) {
    final angle = _rng.nextDouble() * 2 * pi;
    final speed = 30 + _rng.nextDouble() * 50; // 30..80 px/s
    final v0 = Vector2(cos(angle), sin(angle)) * speed;
    final k = GameConfig.sparkleDecelerationRate;
    return ComputedParticle(
      lifespan: cfg.lifespan,
      renderer: (canvas, particle) {
        final t = particle.progress * cfg.lifespan;
        final disp = v0 * ((1 - exp(-k * t)) / k);
        final cx = at.x + disp.x;
        final cy = at.y + disp.y;
        final alpha = (255 * (1 - particle.progress)).round().clamp(0, 255);
        final paint = Paint()..color = cfg.colour.withAlpha(alpha);
        canvas.drawCircle(Offset(cx, cy), cfg.radius, paint);
      },
    );
  }

  /// Potion-only expanding ring halo: radius 0 → 40 px over 0.4s,
  /// stroke alpha 180 → 0. Sits behind the sparkles.
  static Particle _potionHalo(Vector2 at) {
    const haloLifespan = 0.4;
    const haloMaxRadius = 40.0;
    const haloMaxAlpha = 180;
    const haloColour = Color(0xFF00BFFF);
    return ComputedParticle(
      lifespan: haloLifespan,
      renderer: (canvas, particle) {
        final r = particle.progress * haloMaxRadius;
        final alpha = (haloMaxAlpha * (1 - particle.progress)).round().clamp(0, 255);
        final paint = Paint()
          ..color = haloColour.withAlpha(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(Offset(at.x, at.y), r, paint);
      },
    );
  }
}
