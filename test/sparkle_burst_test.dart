import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/collectible.dart';
import 'package:hold_the_hooch/components/sparkle_burst.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SparkleBurst.configFor', () {
    test('particle counts strictly ordered fruitCommon < fruitMedium < potion', () {
      expect(SparkleBurst.configFor(CollectibleKind.fruitCommon).count,
          lessThan(SparkleBurst.configFor(CollectibleKind.fruitMedium).count));
      expect(SparkleBurst.configFor(CollectibleKind.fruitMedium).count,
          lessThan(SparkleBurst.configFor(CollectibleKind.potion).count));
    });

    test('radii strictly ordered fruitCommon < fruitMedium < potion', () {
      expect(SparkleBurst.configFor(CollectibleKind.fruitCommon).radius,
          lessThan(SparkleBurst.configFor(CollectibleKind.fruitMedium).radius));
      expect(SparkleBurst.configFor(CollectibleKind.fruitMedium).radius,
          lessThan(SparkleBurst.configFor(CollectibleKind.potion).radius));
    });

    test('lifespans strictly ordered fruitCommon < fruitMedium < potion', () {
      expect(SparkleBurst.configFor(CollectibleKind.fruitCommon).lifespan,
          lessThan(SparkleBurst.configFor(CollectibleKind.fruitMedium).lifespan));
      expect(SparkleBurst.configFor(CollectibleKind.fruitMedium).lifespan,
          lessThan(SparkleBurst.configFor(CollectibleKind.potion).lifespan));
    });

    test('colours are distinct across fruitCommon, fruitMedium, potion', () {
      final h = SparkleBurst.configFor(CollectibleKind.fruitCommon).colour;
      final o = SparkleBurst.configFor(CollectibleKind.fruitMedium).colour;
      final p = SparkleBurst.configFor(CollectibleKind.potion).colour;
      expect(h, isNot(equals(o)));
      expect(o, isNot(equals(p)));
      expect(h, isNot(equals(p)));
    });
  });

  group('SparkleBurst.emit', () {
    // Smoke-test: emit() must not throw and the returned component must be
    // accepted by the game tree. In the test harness (no GameWidget, no
    // game.mount() call) Flame puts children directly into _internalChildren
    // rather than running the full mount lifecycle, so we assert presence in
    // game.children rather than comp.isMounted — the same pattern used by
    // every other FlameGame test in this project.
    test('adds a ParticleSystemComponent for every kind without throwing', () async {
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
