import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/obstacle.dart';

void main() {
  group('Obstacle sprite-source config', () {
    test('stone is a static sprite', () {
      expect(Obstacle.isAnimated(ObstacleKind.stone), isFalse);
    });
    test('rock is a static sprite', () {
      expect(Obstacle.isAnimated(ObstacleKind.rock), isFalse);
    });
    test('mushroom is animated', () {
      expect(Obstacle.isAnimated(ObstacleKind.mushroom), isTrue);
    });
    test('log is animated', () {
      expect(Obstacle.isAnimated(ObstacleKind.log), isTrue);
    });

    test('animated kinds have valid frame count + stepTime', () {
      for (final kind in ObstacleKind.values) {
        if (!Obstacle.isAnimated(kind)) continue;
        final cfg = Obstacle.animationFor(kind);
        expect(cfg.frameCount, greaterThanOrEqualTo(2));
        expect(cfg.stepTime, greaterThan(0));
        expect(cfg.folder, isNotEmpty);
      }
    });
  });
}
