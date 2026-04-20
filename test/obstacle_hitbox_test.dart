import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/obstacle.dart';

void main() {
  group('Obstacle hitbox is a strict subset of the sprite rect', () {
    final spriteSize = Vector2(100, 100);

    for (final kind in ObstacleKind.values) {
      test('$kind hitbox sits fully inside [0..size] on both axes', () {
        final hb = Obstacle.hitboxFor(kind, spriteSize);
        expect(hb.pos.x, greaterThanOrEqualTo(0));
        expect(hb.pos.y, greaterThanOrEqualTo(0));
        expect(hb.size.x, greaterThan(0));
        expect(hb.size.y, greaterThan(0));
        expect(hb.pos.x + hb.size.x, lessThanOrEqualTo(spriteSize.x));
        expect(hb.pos.y + hb.size.y, lessThanOrEqualTo(spriteSize.y));
      });
    }

    test('hitbox area is meaningfully smaller than sprite area (fair grazes)', () {
      for (final kind in ObstacleKind.values) {
        final hb = Obstacle.hitboxFor(kind, spriteSize);
        final hbArea = hb.size.x * hb.size.y;
        final spriteArea = spriteSize.x * spriteSize.y;
        // No hitbox should fill more than 80% of its sprite — otherwise
        // edge-grazes start registering as hits and the game feels unfair.
        expect(hbArea / spriteArea, lessThan(0.80), reason: '$kind too generous');
      }
    });
  });
}
