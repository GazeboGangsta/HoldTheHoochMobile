import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/collectible.dart';

void main() {
  group('CollectibleKind config', () {
    test('enum has exactly 5 values', () {
      expect(CollectibleKind.values.length, 5);
      expect(CollectibleKind.values, contains(CollectibleKind.fruitCommon));
      expect(CollectibleKind.values, contains(CollectibleKind.fruitMedium));
      expect(CollectibleKind.values, contains(CollectibleKind.fruitRare));
      expect(CollectibleKind.values, contains(CollectibleKind.crystal));
      expect(CollectibleKind.values, contains(CollectibleKind.potion));
    });

    test('points strictly ordered common < medium < rare < crystal < potion', () {
      expect(Collectible.pointsFor(CollectibleKind.fruitCommon),
          lessThan(Collectible.pointsFor(CollectibleKind.fruitMedium)));
      expect(Collectible.pointsFor(CollectibleKind.fruitMedium),
          lessThan(Collectible.pointsFor(CollectibleKind.fruitRare)));
      expect(Collectible.pointsFor(CollectibleKind.fruitRare),
          lessThan(Collectible.pointsFor(CollectibleKind.crystal)));
      expect(Collectible.pointsFor(CollectibleKind.crystal),
          lessThan(Collectible.pointsFor(CollectibleKind.potion)));
    });

    test('fruitCommon has at least 2 sprite variants', () {
      expect(Collectible.spritePathsFor(CollectibleKind.fruitCommon).length,
          greaterThanOrEqualTo(2));
    });

    test('fruitRare has exactly 1 variant (golden apple)', () {
      final paths = Collectible.spritePathsFor(CollectibleKind.fruitRare);
      expect(paths.length, 1);
      expect(paths.first, contains('golden_apple'));
    });

    test('crystal has at least 5 variants', () {
      expect(Collectible.spritePathsFor(CollectibleKind.crystal).length,
          greaterThanOrEqualTo(5));
    });

    test('potion has exactly 1 variant for V1', () {
      expect(Collectible.spritePathsFor(CollectibleKind.potion).length, 1);
    });

    test('only potion grants the spill-drain bonus', () {
      for (final kind in CollectibleKind.values) {
        expect(Collectible.grantsSpillDrain(kind),
            kind == CollectibleKind.potion,
            reason: '$kind grantsSpillDrain wrong');
      }
    });
  });
}
