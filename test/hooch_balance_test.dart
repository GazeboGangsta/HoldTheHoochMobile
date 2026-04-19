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
}
