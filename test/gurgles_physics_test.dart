import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/gurgles.dart';
import 'package:hold_the_hooch/config/game_config.dart';

/// Regression guard for Gurgles jump physics. If tuning on
/// [GameConfig.jumpVelocityMin] / [GameConfig.jumpVelocityMax] /
/// [GameConfig.jumpHoldMaxMs] / [GameConfig.gravity] silently breaks
/// potion-tier reachability ([CollectibleManager._heightForKind]
/// places it at groundY - 180 * sizeScale), the full-hold assertion
/// below trips.
///
/// Uses the same stub pattern as test/game_scene_restart_test.dart:
/// plain FlameGame host + Gurgles subclass that skips SVG loading.
class _PhysicsHost extends FlameGame {
  late _StubGurgles gurgles;
  final double groundY = 600.0;

  @override
  Future<void> onLoad() async {
    gurgles = _StubGurgles(groundY: groundY);
    await add(gurgles);
  }
}

/// Skips SVG loads but preserves the physics loop (velocityY, y,
/// jump state, gravity). The production update() path is the only
/// behaviour under test.
class _StubGurgles extends Gurgles {
  _StubGurgles({required super.groundY})
      : super(
          position: Vector2(200, groundY),
          size: Vector2(80, 100),
        );

  @override
  Future<void> onLoad() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Gurgles peak feet height on max-hold jump clears the 90px floor',
    () async {
      final host = _PhysicsHost();
      host.onGameResize(Vector2(400, 800));
      await host.onLoad();
      await host.ready();

      final g = host.gurgles;
      g.startJump();

      double minY = g.y;
      const dt = 1 / 60;
      // 1.5s covers full hold (220ms) + descent back to ground.
      for (var i = 0; i < 90; i++) {
        host.update(dt);
        if (g.y < minY) minY = g.y;
      }

      final peakFeetHeight = host.groundY - minY;

      // If this regresses, the potion tier (180px + body clearance)
      // becomes unreachable and the top collectible silently drops out.
      expect(peakFeetHeight, greaterThanOrEqualTo(90.0),
          reason: 'feet peak $peakFeetHeight < 90px — jump too weak');

      // Must return to ground by end of simulation.
      expect(g.y, closeTo(host.groundY, 1.0),
          reason: 'Gurgles did not return to ground after jump');
    },
  );

  test(
    'Short-tap jump (no hold) peaks lower than full-hold jump',
    () async {
      final host = _PhysicsHost();
      host.onGameResize(Vector2(400, 800));
      await host.onLoad();
      await host.ready();

      final g = host.gurgles;
      g.startJump();
      g.endJump(); // Release immediately — velocity stays at jumpVelocityMin.

      double minY = g.y;
      const dt = 1 / 60;
      for (var i = 0; i < 90; i++) {
        host.update(dt);
        if (g.y < minY) minY = g.y;
      }
      final shortHop = host.groundY - minY;

      // Short-tap peak should live in a ~20–90 px band. If it crosses
      // full-hold (≥90), tap-and-hold has lost its role.
      expect(shortHop, lessThan(90.0));
      expect(shortHop, greaterThan(20.0));
    },
  );

  test('GameConfig jump constants still produce a positive peak analytically', () {
    // Sanity check independent of the simulation:
    //   peak_min = v0² / (2g)
    // gives the theoretical minimum peak (instant release). If this
    // drops below 30 px someone has turned jumps into nudges.
    final v0 = GameConfig.jumpVelocityMin.abs();
    final g = GameConfig.gravity;
    final theoreticalMinPeak = (v0 * v0) / (2 * g);
    expect(theoreticalMinPeak, greaterThan(30.0));
  });
}
