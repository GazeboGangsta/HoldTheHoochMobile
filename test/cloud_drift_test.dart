import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/components/cloud_drift.dart';

void main() {
  group('CloudDrift', () {
    test('offset advances by driftPxPerSecond * dt', () {
      final newOffset = CloudDrift.advanceOffset(
        currentOffset: 0,
        driftPxPerSecond: 15,
        dt: 1.0,
        tileWidth: 600,
      );
      expect(newOffset, 15);
    });

    test('negative drift (rightward) wraps at 0 boundary', () {
      // Moving right at -10 px/s for 1s from offset 5 → -5, wraps to 595.
      final newOffset = CloudDrift.advanceOffset(
        currentOffset: 5,
        driftPxPerSecond: -10,
        dt: 1.0,
        tileWidth: 600,
      );
      expect(newOffset, closeTo(595, 0.0001));
    });

    test('positive drift wraps at tile boundary', () {
      // Moving left at 600 px/s for 1s from offset 100 → 700, wraps to 100.
      final newOffset = CloudDrift.advanceOffset(
        currentOffset: 100,
        driftPxPerSecond: 600,
        dt: 1.0,
        tileWidth: 600,
      );
      expect(newOffset, closeTo(100, 0.0001));
    });

    test('constructor stores layout params', () {
      final cloud = CloudDrift(
        assetPath: 'third_party/pine_hills/png/02_cloud1.png',
        driftPxPerSecond: 12,
        worldSize: Vector2(400, 800),
        yPosition: 50,
        height: 200,
        sourceWidth: 320,
        sourceHeight: 180,
      );
      expect(cloud.position.y, 50);
      expect(cloud.size, Vector2(400, 200));
      expect(cloud.driftPxPerSecond, 12);
    });
  });
}
