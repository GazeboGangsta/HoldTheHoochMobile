import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/collectible.dart';
import 'package:hold_the_hooch/components/gurgles.dart';
import 'package:hold_the_hooch/components/hooch_balance.dart';
import 'package:hold_the_hooch/components/obstacle.dart';
import 'package:hold_the_hooch/components/score_popup.dart';
import 'package:hold_the_hooch/scenes/game_scene.dart';

/// Regression guard: restart() must clear every spawned entity type.
///
/// If a new gameplay entity is added (e.g. a particle effect) and is
/// accidentally omitted from the restart() cleanup loop, a dead entity
/// persists into the next run, causing score pollution or visual artefacts.
///
/// Uses a stub subclass to bypass SVG loading (ParallaxLayer, Ground,
/// Gurgles all call Svg.load in onLoad which is unavailable in the test
/// bundle). The stub initialises only the late fields that restart() touches,
/// keeping the real production restart() logic under test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GameScene.restart() removes obstacles, collectibles, and score popups',
      () async {
    final game = _StubGameScene();
    game.onGameResize(Vector2(400, 800));
    await game.onLoad();
    await game.ready();

    game.add(_StubObstacle());
    game.add(_StubCollectible());
    game.add(ScorePopup(points: 10, position: Vector2(50, 50)));
    await game.ready();

    expect(game.children.whereType<Obstacle>(), isNotEmpty);
    expect(game.children.whereType<Collectible>(), isNotEmpty);
    expect(game.children.whereType<ScorePopup>(), isNotEmpty);

    await game.restart();
    await game.ready();

    expect(game.children.whereType<Obstacle>(), isEmpty);
    expect(game.children.whereType<Collectible>(), isEmpty);
    expect(game.children.whereType<ScorePopup>(), isEmpty);
  });
}

/// Minimal game subclass that skips all SVG loading while keeping the real
/// restart() implementation under test.
class _StubGameScene extends GameScene {
  @override
  Future<void> onLoad() async {
    // Flame camera setup expected by restart()'s resumeEngine() path.
    camera.viewfinder.anchor = Anchor.topLeft;

    // Initialise only the late fields that restart() accesses.
    const groundY = 600.0;
    groundYForTesting = groundY;
    gurgles = Gurgles(
      position: Vector2(88, groundY),
      groundY: groundY,
      size: Vector2(80, 144),
    );
    balance = HoochBalance();
  }
}

class _StubObstacle extends Obstacle {
  _StubObstacle()
      : super(
          kind: ObstacleKind.rock,
          position: Vector2.zero(),
          scrollSpeed: 0,
        );

  @override
  Future<void> onLoad() async {}
}

class _StubCollectible extends Collectible {
  _StubCollectible()
      : super(
          kind: CollectibleKind.herb,
          position: Vector2.zero(),
          scrollSpeed: 0,
          onPickup: _noop,
        );

  @override
  Future<void> onLoad() async {}
}

void _noop(int points, Vector2 at) {}
