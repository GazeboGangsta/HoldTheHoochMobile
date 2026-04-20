import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/config/game_config.dart';

void main() {
  group('GameConfig invariants', () {
    test('sane existing defaults', () {
      expect(GameConfig.baseScrollSpeed, greaterThan(0));
      expect(GameConfig.spillThreshold, lessThan(1.0));
      expect(GameConfig.spillDrainThreshold, lessThan(GameConfig.spillThreshold));
    });

    test('jump velocities are ordered (min is less-negative hop, max is full jump)', () {
      // Both are negative; min is a weaker upward velocity than max.
      expect(GameConfig.jumpVelocityMin, greaterThan(GameConfig.jumpVelocityMax));
      expect(GameConfig.jumpVelocityMax, lessThan(0));
    });

    test('score multiplier constants are sensible', () {
      expect(GameConfig.scoreMultiplierIntervalSeconds, greaterThan(0));
      expect(GameConfig.scoreMultiplierStep, greaterThan(0));
      expect(GameConfig.scoreMultiplierMax, greaterThan(1.0));
    });

    test('potion spill-drain bonus is a positive duration', () {
      expect(GameConfig.potionSpillDrainBonusSeconds, greaterThan(0));
      expect(GameConfig.potionSpillDrainBonusMultiplier, greaterThan(1.0));
    });

    test('wobble amplitude ramp caps at a sane multiplier', () {
      expect(GameConfig.wobbleAmplitudeMaxMultiplier, greaterThan(1.0));
    });

    test('difficulty and hold durations are positive', () {
      expect(GameConfig.difficultyRampSeconds, greaterThan(0));
      expect(GameConfig.jumpHoldMaxMs, greaterThan(0));
    });

    test('gravity and wobble base magnitudes are positive', () {
      expect(GameConfig.gravity, greaterThan(0));
      expect(GameConfig.wobbleBaseAmplitude, greaterThan(0));
      expect(GameConfig.wobbleBaseFrequency, greaterThan(0));
    });

    test('spill thresholds live in [0, 1]', () {
      expect(GameConfig.spillThreshold, inInclusiveRange(0.0, 1.0));
      expect(GameConfig.spillDrainThreshold, inInclusiveRange(0.0, 1.0));
    });

    test('drift rates are ordered and positive', () {
      expect(GameConfig.driftRateBase, greaterThan(0));
      expect(GameConfig.driftRateMax, greaterThan(GameConfig.driftRateBase));
    });

    test('tiltButtonTorqueRate beats driftRateMax so player can out-correct drift', () {
      // If this invariant breaks, the tilt buttons would apply torque slower
      // than the passive drift fills it — the player would be unable to
      // correct a drifting hooch, making runs impossible to sustain.
      expect(GameConfig.tiltButtonTorqueRate, greaterThan(GameConfig.driftRateMax));
    });

    test('control-strip layout constants are positive', () {
      expect(GameConfig.controlStripHeightFraction, inExclusiveRange(0.0, 1.0));
      expect(GameConfig.tiltButtonSize, greaterThan(0));
      expect(GameConfig.tiltButtonInset, greaterThanOrEqualTo(0));
      expect(GameConfig.tiltButtonGap, greaterThanOrEqualTo(0));
    });

    test('tankard lean is a sensible radian value (not degrees by mistake)', () {
      // 0.6 rad ≈ 34°. If someone set it to 34 expecting degrees, the tankard
      // would spin wildly. Guard: value must be well under π.
      expect(GameConfig.tankardMaxLeanRadians, inExclusiveRange(0.0, 1.5));
    });

    test('jumpVelocityMin produces a theoretical minimum peak above 30px', () {
      // peak_min = v0² / (2g) — minimum peak from an instant-release
      // short hop. If this drops below 30 px, someone has turned jumps
      // into nudges and short-tap gameplay loses its role.
      final v0 = GameConfig.jumpVelocityMin.abs();
      final g = GameConfig.gravity;
      final theoreticalMinPeak = (v0 * v0) / (2 * g);
      expect(theoreticalMinPeak, greaterThan(30.0));
    });
  });
}
