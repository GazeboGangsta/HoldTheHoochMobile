import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/gurgles.dart';
import 'package:hold_the_hooch/components/hooch_balance.dart';
import 'package:hold_the_hooch/components/splash_emitter.dart';
import 'package:hold_the_hooch/config/game_config.dart';

/// Gurgles stub that skips SVG loading and returns a fixed world rim position,
/// so the emitter can be unit-tested without the asset bundle.
class _StubGurgles extends Gurgles {
  _StubGurgles()
      : super(
          position: Vector2(200, 600),
          groundY: 600,
          size: Vector2(80, 144),
        );

  @override
  Future<void> onLoad() async {}

  @override
  Vector2 tankardRimWorldPosition(double tilt) => Vector2(200, 500);
}

int _emissions(FlameGame game) =>
    game.descendants().whereType<ParticleSystemComponent>().length;

Future<({FlameGame game, SplashEmitter emitter, HoochBalance balance})> _setup() async {
  final game = FlameGame();
  game.onGameResize(Vector2(400, 800));
  await game.onLoad();
  await game.ready();
  final balance = HoochBalance();
  // Fixed seed makes lifespan draws deterministic so rate-count assertions
  // are stable across runs. The seed only affects visual variance — physics
  // and rate logic are seed-independent.
  final emitter = SplashEmitter(gurgles: _StubGurgles(), balance: balance, rng: Random(0));
  await game.add(emitter);
  await game.ready();
  return (game: game, emitter: emitter, balance: balance);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('no emission while tilt stays below spillThreshold', () async {
    final s = await _setup();
    s.balance.tilt = 0.5;
    for (var i = 0; i < 60; i++) {
      s.game.update(1 / 60);
    }
    expect(_emissions(s.game), 0);
  });

  test('exactly one burst fires on threshold crossing', () async {
    final s = await _setup();
    s.balance.tilt = 0.5;
    s.game.update(1 / 60);
    final before = _emissions(s.game);

    s.balance.tilt = 0.8;
    s.game.update(1 / 60);
    // One burst is one ParticleSystemComponent carrying splashBurstCount droplets.
    expect(_emissions(s.game) - before, 1);
  });

  test('no re-burst while tilt stays over threshold', () async {
    final s = await _setup();
    s.balance.tilt = 0.8;
    s.game.update(1 / 60);  // entry burst
    final afterBurst = _emissions(s.game);

    // Five more frames at 0.8 tilt. Trickle rate at tilt=0.8 ≈
    //   5 + 10 * (0.8-0.7)/(1-0.7) = 8.33 particles/sec.
    // Over 5 frames (~0.083s) that's ~0.7 particles expected — so
    // total additional emissions should be 0 or 1, NEVER another burst.
    for (var i = 0; i < 5; i++) {
      s.game.update(1 / 60);
    }
    expect(_emissions(s.game) - afterBurst, lessThanOrEqualTo(1));
  });

  test('continuous rate at tilt=threshold+epsilon ≈ 5 per second', () async {
    final s = await _setup();
    s.balance.tilt = GameConfig.spillThreshold + 1e-6;
    for (var i = 0; i < 60; i++) {
      s.game.update(1 / 60);
    }
    // 1 burst + ~5 trickle PSCs = 6 total over 1 s.
    // totalEmitted counts all PSCs ever created (including expired ones that
    // have already been removed from the tree), giving a stable rate signal.
    expect(s.emitter.totalEmitted, inInclusiveRange(5, 7));
  });

  test('continuous rate at tilt=1.0 ≈ 15 per second', () async {
    final s = await _setup();
    s.balance.tilt = 1.0;
    for (var i = 0; i < 60; i++) {
      s.game.update(1 / 60);
    }
    // 1 burst + ~15 trickle PSCs = 16 total over 1 s.
    expect(s.emitter.totalEmitted, inInclusiveRange(15, 17));
  });

  test('reset() clears edge detector — re-entry re-fires the burst', () async {
    final s = await _setup();
    s.balance.tilt = 0.8;
    s.game.update(1 / 60);  // burst
    s.emitter.reset();
    s.balance.tilt = 0;
    s.game.update(1 / 60);  // nothing
    final beforeReEntry = _emissions(s.game);

    s.balance.tilt = 0.8;
    s.game.update(1 / 60);
    expect(_emissions(s.game) - beforeReEntry, 1);
  });

  test('emitGameOverBurst adds exactly one ParticleSystemComponent', () async {
    final s = await _setup();
    s.balance.tilt = 1.0;
    final before = _emissions(s.game);
    s.emitter.emitGameOverBurst();
    await s.game.ready();
    expect(_emissions(s.game) - before, 1);
  });
}
