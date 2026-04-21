import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/raster_parallax_layer.dart';

void main() {
  group('RasterParallaxLayer', () {
    test('computes tile width from height * source aspect ratio', () {
      // 320x180 source → aspect 320/180 = 1.778
      // At 200px height, tile width = 200 * 1.778 = 355.56
      final tileWidth = RasterParallaxLayer.computeTileWidth(
        renderHeight: 200,
        sourceWidth: 320,
        sourceHeight: 180,
      );
      expect(tileWidth, closeTo(355.56, 0.1));
    });

    test('scrolls offset forward by worldSpeed * speedFactor * dt', () {
      // Offset after 1 second at worldSpeed=200, speedFactor=0.5 = 100px.
      final newOffset = RasterParallaxLayer.advanceOffset(
        currentOffset: 0,
        worldSpeed: 200,
        speedFactor: 0.5,
        dt: 1.0,
        tileWidth: 400,
      );
      expect(newOffset, 100);
    });

    test('wraps offset at tile boundary', () {
      // Offset starting at 390, advance 20 → would be 410, wraps to 10.
      final newOffset = RasterParallaxLayer.advanceOffset(
        currentOffset: 390,
        worldSpeed: 200,
        speedFactor: 0.1,
        dt: 1.0,
        tileWidth: 400,
      );
      expect(newOffset, 10);
    });

    test('constructor stores layout params', () {
      final layer = RasterParallaxLayer(
        assetPath: 'third_party/pine_hills/png/00_background.png',
        speedFactor: 0.15,
        worldSpeedProvider: () => 280,
        worldSize: Vector2(400, 800),
        yPosition: 100,
        height: 500,
        sourceWidth: 320,
        sourceHeight: 180,
      );
      expect(layer.position.y, 100);
      expect(layer.size, Vector2(400, 500));
      expect(layer.speedFactor, 0.15);
    });
  });
}
