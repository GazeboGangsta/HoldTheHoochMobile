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
}
