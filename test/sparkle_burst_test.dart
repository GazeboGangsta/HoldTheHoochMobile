import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/collectible.dart';
import 'package:hold_the_hooch/components/sparkle_burst.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SparkleBurst.configFor', () {
    // Ordering for the new 5-kind roster:
    // fruitCommon < fruitMedium < fruitRare < crystal < potion
    test('particle counts weakly increase along the tier order', () {
      final order = [
        CollectibleKind.fruitCommon,
        CollectibleKind.fruitMedium,
        CollectibleKind.fruitRare,
        CollectibleKind.crystal,
        CollectibleKind.potion,
      ];
      for (var i = 1; i < order.length; i++) {
        expect(SparkleBurst.configFor(order[i]).count,
            greaterThanOrEqualTo(SparkleBurst.configFor(order[i - 1]).count),
            reason: '${order[i]} count should be ≥ ${order[i - 1]}');
      }
    });

    test('radii weakly increase along the tier order', () {
      final order = [
        CollectibleKind.fruitCommon,
        CollectibleKind.fruitMedium,
        CollectibleKind.fruitRare,
        CollectibleKind.crystal,
        CollectibleKind.potion,
      ];
      for (var i = 1; i < order.length; i++) {
        expect(SparkleBurst.configFor(order[i]).radius,
            greaterThanOrEqualTo(SparkleBurst.configFor(order[i - 1]).radius));
      }
    });

    test('colours are distinct across kinds', () {
      final colours = {
        for (final k in CollectibleKind.values)
          k: SparkleBurst.configFor(k).colour,
      };
      final unique = colours.values.toSet();
      expect(unique.length, CollectibleKind.values.length,
          reason: 'colours not all unique: $colours');
    });
  });

  group('SparkleBurst.emit', () {
    test('adds a ParticleSystemComponent for every kind without throwing',
        () async {
      final game = FlameGame();
      game.onGameResize(Vector2(400, 800));
      await game.onLoad();
      await game.ready();

      for (final kind in CollectibleKind.values) {
        final comp = SparkleBurst.emit(kind, Vector2(100, 100));
        game.add(comp);
        await game.ready();
        expect(game.children.contains(comp), isTrue,
            reason: '$kind component not in game.children');
      }
    });
  });
}
