import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/gurgles.dart';
import 'package:hold_the_hooch/config/game_config.dart';

void main() {
  group('Gurgles.tankardAngleForTilt', () {
    test('at zero tilt the tankard is upright', () {
      expect(Gurgles.tankardAngleForTilt(0), 0);
    });

    test('at full positive tilt the tankard leans by tankardMaxLeanRadians', () {
      expect(
        Gurgles.tankardAngleForTilt(1.0),
        closeTo(GameConfig.tankardMaxLeanRadians, 1e-9),
      );
    });

    test('at negative tilt the tankard leans the other way', () {
      expect(
        Gurgles.tankardAngleForTilt(-0.5),
        closeTo(-0.5 * GameConfig.tankardMaxLeanRadians, 1e-9),
      );
    });

    test('max lean is visually noticeable (~30° or more)', () {
      // ~0.52 rad = 30 degrees. A tankard barely leaning isn't useful feedback.
      expect(GameConfig.tankardMaxLeanRadians, greaterThan(0.5));
    });
  });

  group('Gurgles.rimOffsetFromTankardCenter', () {
    test('at tilt=0, rim offset is straight up (y negative, x zero)', () {
      final offset = Gurgles.rimOffsetFromTankardCenter(0, 10);
      expect(offset.x, closeTo(0, 1e-9));
      expect(offset.y, closeTo(-10, 1e-9));
    });

    test('at positive tilt, rim offset rotates toward +x', () {
      final offset = Gurgles.rimOffsetFromTankardCenter(1.0, 10);
      expect(offset.x, greaterThan(0), reason: 'positive tilt → rim shifts right');
      expect(offset.y, lessThan(0), reason: 'rim stays above center');
    });

    test('at negative tilt, rim offset rotates toward -x', () {
      final offset = Gurgles.rimOffsetFromTankardCenter(-1.0, 10);
      expect(offset.x, lessThan(0));
      expect(offset.y, lessThan(0));
    });

    test('magnitude equals tankardRadius regardless of tilt', () {
      for (final tilt in [-1.0, -0.5, 0.0, 0.5, 1.0]) {
        final offset = Gurgles.rimOffsetFromTankardCenter(tilt, 10);
        expect(offset.length, closeTo(10, 1e-6), reason: 'tilt=$tilt');
      }
    });
  });
}
