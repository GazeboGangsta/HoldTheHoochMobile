import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/scenes/game_scene.dart';

void main() {
  group('GameScene.scoreMultiplier', () {
    test('starts at 1.0', () {
      expect(GameScene.multiplierFor(0), closeTo(1.0, 1e-9));
    });

    test('ticks to 1.1 at 10 seconds', () {
      expect(GameScene.multiplierFor(10), closeTo(1.1, 1e-9));
    });

    test('steps in 10s increments', () {
      expect(GameScene.multiplierFor(25), closeTo(1.2, 1e-9));
      expect(GameScene.multiplierFor(50), closeTo(1.5, 1e-9));
    });

    test('caps at the max', () {
      expect(GameScene.multiplierFor(999), closeTo(3.0, 1e-9));
    });
  });
}
