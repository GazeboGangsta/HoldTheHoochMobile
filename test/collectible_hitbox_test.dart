import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/collectible.dart';

void main() {
  group('Collectible hitbox is a strict subset of the sprite rect', () {
    final sizes = [
      Vector2(40, 40),   // fruitCommon reference size
      Vector2(44, 44),   // fruitMedium
      Vector2(48, 48),   // fruitRare (golden apple)
      Vector2(36, 36),   // crystal (small gems)
      Vector2(32, 48),   // potion (tall bottle)
      Vector2(100, 100), // arbitrary scale
    ];

    for (final s in sizes) {
      test('hitbox for sprite ${s.x}x${s.y} fits inside bounds', () {
        final hb = Collectible.hitboxFor(s);
        expect(hb.pos.x, greaterThanOrEqualTo(0));
        expect(hb.pos.y, greaterThanOrEqualTo(0));
        expect(hb.size.x, greaterThan(0));
        expect(hb.size.y, greaterThan(0));
        expect(hb.pos.x + hb.size.x, lessThanOrEqualTo(s.x));
        expect(hb.pos.y + hb.size.y, lessThanOrEqualTo(s.y));
      });
    }

    test('hitbox is centered inside sprite (symmetric insets)', () {
      final s = Vector2(100, 100);
      final hb = Collectible.hitboxFor(s);
      final rightInset = s.x - (hb.pos.x + hb.size.x);
      final bottomInset = s.y - (hb.pos.y + hb.size.y);
      expect((hb.pos.x - rightInset).abs(), lessThan(1e-9));
      expect((hb.pos.y - bottomInset).abs(), lessThan(1e-9));
    });
  });
}
