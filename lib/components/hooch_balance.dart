import 'dart:math';
import 'package:flame/components.dart';
import '../config/game_config.dart';

/// Tracks tilt in [-1.0, 1.0] and the spill meter in [0.0, 1.0].
/// Visual representation is left to the scene; this is pure state for M3.
class HoochBalance extends Component {
  double tilt = 0.0;
  double spill = 0.0;
  double _phase = 0.0;

  double get spillPercent => spill.clamp(0.0, 1.0);
  bool get hasSpilled => spill >= 1.0;

  void resetPhase() {
    _phase = 0.0;
  }

  /// Called by the scene to apply player input (drag delta in screen-x units).
  void applyCounterTorque(double delta) {
    tilt -= delta * 0.004;
    tilt = tilt.clamp(-1.0, 1.0);
  }

  /// Called when Gurgles jumps — adds a destabilising impulse.
  void applyJumpImpulse() {
    final dir = Random().nextBool() ? 1.0 : -1.0;
    tilt += dir * 0.18;
    tilt = tilt.clamp(-1.0, 1.0);
  }

  double _difficulty = 0.0;

  /// Called each frame from GameScene with elapsed/rampSeconds in [0, 1].
  void applyDifficulty(double t) {
    _difficulty = t.clamp(0.0, 1.0);
  }

  double get _amplitudeMultiplier =>
      1.0 + _difficulty * (GameConfig.wobbleAmplitudeMaxMultiplier - 1.0);

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * GameConfig.wobbleBaseFrequency * 2 * pi;
    final wobble =
        sin(_phase) * GameConfig.wobbleBaseAmplitude * _amplitudeMultiplier * dt;
    tilt += wobble;
    tilt = tilt.clamp(-1.0, 1.0);

    if (tilt.abs() > GameConfig.spillThreshold) {
      final over = tilt.abs() - GameConfig.spillThreshold;
      spill += over * GameConfig.spillFillRate * dt;
    } else if (tilt.abs() < GameConfig.spillDrainThreshold) {
      spill -= GameConfig.spillDrainRate * dt;
    }
    spill = spill.clamp(0.0, 1.0);
  }
}
