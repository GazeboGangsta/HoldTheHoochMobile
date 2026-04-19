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
  });
}
