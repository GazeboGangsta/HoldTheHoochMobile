import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/config/game_config.dart';

void main() {
  test('GameConfig sane defaults', () {
    expect(GameConfig.baseScrollSpeed, greaterThan(0));
    expect(GameConfig.spillThreshold, lessThan(1.0));
    expect(GameConfig.spillDrainThreshold, lessThan(GameConfig.spillThreshold));
  });
}
