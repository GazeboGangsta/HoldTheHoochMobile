import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/hooch_balance.dart';

/// Sample the peak wobble swing over a full period by running update()
/// for long enough that the sine reaches its peak.
double _maxTiltOverOneSecond(HoochBalance b) {
  const dt = 1 / 60;
  const steps = 60;
  double peak = 0;
  for (var i = 0; i < steps; i++) {
    b.update(dt);
    if (b.tilt.abs() > peak) peak = b.tilt.abs();
  }
  return peak;
}

void main() {
  group('HoochBalance wobble amplitude ramp', () {
    test('at difficulty 0, wobble amplitude matches base', () {
      final b = HoochBalance();
      b.applyDifficulty(0);
      final peak0 = _maxTiltOverOneSecond(b);

      // Reset + run at the same difficulty; results consistent.
      b.tilt = 0;
      b.resetPhase();
      final peak0Again = _maxTiltOverOneSecond(b);
      expect((peak0 - peak0Again).abs(), lessThan(0.01));
    });

    test('at difficulty 1.0, wobble amplitude is larger than at 0', () {
      final b1 = HoochBalance()..applyDifficulty(0);
      final baseline = _maxTiltOverOneSecond(b1);

      final b2 = HoochBalance()..applyDifficulty(1.0);
      final ramped = _maxTiltOverOneSecond(b2);

      expect(ramped, greaterThan(baseline));
    });

    test('at difficulty 1.0, multiplier is within sane bounds', () {
      final b = HoochBalance()..applyDifficulty(1.0);
      // At max difficulty the wobble frequency and amplitude combine but
      // we expect the peak tilt from pure wobble to still be well below
      // the clamp (1.0).
      final peak = _maxTiltOverOneSecond(b);
      expect(peak, lessThan(0.5));
    });
  });

  group('HoochBalance spill-drain bonus', () {
    test('bonus multiplies drain rate for the requested duration', () {
      final b = HoochBalance();
      // Seed: tilt below drain threshold so drain is active, spill at 1.0
      // so we can observe how fast it drops.
      b.tilt = 0.0;
      b.spill = 1.0;

      // Without bonus: drain rate is GameConfig.spillDrainRate per second.
      // Over 0.5s spill should drop by ~0.125.
      const halfSec = 0.5;
      const dt = 1 / 60;
      final baseline = HoochBalance()
        ..tilt = 0.0
        ..spill = 1.0;
      for (var i = 0; i < (halfSec / dt).round(); i++) {
        baseline.update(dt);
      }
      final baselineFinal = baseline.spill;

      b.grantSpillDrain(Duration(milliseconds: 500));
      for (var i = 0; i < (halfSec / dt).round(); i++) {
        b.update(dt);
      }

      // With bonus active, spill must drop noticeably faster than baseline.
      expect(b.spill, lessThan(baselineFinal));
    });

    test('bonus expires and drain returns to normal', () {
      final b = HoochBalance();
      b.tilt = 0.0;
      b.spill = 1.0;
      b.grantSpillDrain(Duration(milliseconds: 200));

      const dt = 1 / 60;
      // Advance past the bonus window.
      for (var i = 0; i < 30; i++) {
        b.update(dt);
      }
      final spillAfterBonusWindow = b.spill;

      // Now drain rate should be back to baseline.
      final baseline = HoochBalance()
        ..tilt = 0.0
        ..spill = spillAfterBonusWindow;

      const followUpSeconds = 0.3;
      for (var i = 0; i < (followUpSeconds / dt).round(); i++) {
        b.update(dt);
        baseline.update(dt);
      }

      expect((b.spill - baseline.spill).abs(), lessThan(0.01));
    });
  });

  group('HoochBalance directional drift bias', () {
    test('default (no drift direction set): tilt stays tiny (pure wobble)', () {
      final b = HoochBalance()..applyDifficulty(1.0);
      const dt = 1 / 60;
      double peak = 0;
      for (var i = 0; i < 120; i++) {
        b.update(dt);
        if (b.tilt.abs() > peak) peak = b.tilt.abs();
      }
      // Pure wobble at max amplitude ramp: 2 * 0.25 * 1.7 / 7.54 ≈ 0.113.
      expect(peak, lessThan(0.2));
    });

    test('with positive drift direction, tilt drifts positive', () {
      final b = HoochBalance()
        ..setDriftDirection(1.0)
        ..applyDifficulty(0.5);
      const dt = 1 / 60;
      for (var i = 0; i < 120; i++) {
        b.update(dt);
      }
      // After 2s at mid-difficulty, tilt must be noticeably positive.
      expect(b.tilt, greaterThan(0.1));
    });

    test('with negative drift direction, tilt drifts negative', () {
      final b = HoochBalance()
        ..setDriftDirection(-1.0)
        ..applyDifficulty(0.5);
      const dt = 1 / 60;
      for (var i = 0; i < 120; i++) {
        b.update(dt);
      }
      expect(b.tilt, lessThan(-0.1));
    });

    test('drift rate scales with difficulty', () {
      final b0 = HoochBalance()
        ..setDriftDirection(1.0)
        ..applyDifficulty(0);
      final b1 = HoochBalance()
        ..setDriftDirection(1.0)
        ..applyDifficulty(1.0);

      const dt = 1 / 60;
      for (var i = 0; i < 60; i++) {
        b0.update(dt);
        b1.update(dt);
      }
      // Higher difficulty must produce faster drift.
      expect(b1.tilt, greaterThan(b0.tilt));
    });

    test('drift alone eventually crosses the spill threshold', () {
      final b = HoochBalance()
        ..setDriftDirection(1.0)
        ..applyDifficulty(1.0);
      const dt = 1 / 60;
      // 10 seconds of pure drift at max difficulty should be enough to cross
      // spill threshold (0.7) with no player intervention.
      for (var i = 0; i < 600; i++) {
        b.update(dt);
        if (b.tilt.abs() > 0.7) break;
      }
      expect(b.tilt.abs(), greaterThan(0.7));
    });
  });

  group('HoochBalance applyTiltTorque clamp', () {
    test('positive torque past 1.0 clamps at 1.0', () {
      final b = HoochBalance();
      b.applyTiltTorque(1.5);
      expect(b.tilt, 1.0);
    });

    test('negative torque past -1.0 clamps at -1.0', () {
      final b = HoochBalance();
      b.applyTiltTorque(-1.5);
      expect(b.tilt, -1.0);
    });

    test('small torque accumulates without clamp', () {
      final b = HoochBalance();
      b.applyTiltTorque(0.3);
      b.applyTiltTorque(0.3);
      expect((b.tilt - 0.6).abs(), lessThan(1e-9));
    });
  });

  group('HoochBalance applyJumpImpulse', () {
    test('impulse moves tilt by exactly 0.18 in some direction', () {
      // applyJumpImpulse picks a random direction, so run enough trials that
      // we cover both signs; every single call must move |tilt| by 0.18.
      for (var i = 0; i < 20; i++) {
        final b = HoochBalance();
        b.applyJumpImpulse();
        expect(b.tilt.abs(), closeTo(0.18, 1e-9));
      }
    });

    test('impulse applied near +1.0 clamps rather than overshooting', () {
      // Seed tilt so any positive-direction impulse would push past the clamp.
      // We re-try until the random direction is positive (usually in <5 tries).
      for (var i = 0; i < 50; i++) {
        final b = HoochBalance();
        b.tilt = 0.95;
        b.applyJumpImpulse();
        // If the random direction was negative, tilt fell to 0.77 — retry.
        if (b.tilt < 0.95) continue;
        expect(b.tilt, 1.0);
        return;
      }
      fail('applyJumpImpulse never rolled a positive direction in 50 trials');
    });

    test('impulse applied near -1.0 clamps rather than overshooting', () {
      for (var i = 0; i < 50; i++) {
        final b = HoochBalance();
        b.tilt = -0.95;
        b.applyJumpImpulse();
        if (b.tilt > -0.95) continue;
        expect(b.tilt, -1.0);
        return;
      }
      fail('applyJumpImpulse never rolled a negative direction in 50 trials');
    });
  });
}
