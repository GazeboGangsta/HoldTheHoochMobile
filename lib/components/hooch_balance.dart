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
    _drainBonusRemainingSec = 0.0;
  }

  /// Directly add [delta] to tilt (clamped). Used by discrete controls
  /// (tilt buttons) that already compute a desired per-frame delta.
  void applyTiltTorque(double delta) {
    tilt += delta;
    tilt = tilt.clamp(-1.0, 1.0);
  }

  /// Player drag input. Positive delta (finger moving right) pushes the
  /// tankard right (positive tilt). Natural follow-finger mapping: to
  /// correct a right-leaning tankard, drag left.
  void applyDragInput(double delta) => applyTiltTorque(delta * 0.004);

  /// Legacy name. Kept for any callers/tests that still use the old word,
  /// but forwards to [applyDragInput] with the corrected sign.
  @Deprecated('Use applyDragInput — the old name was misleading')
  void applyCounterTorque(double delta) => applyDragInput(delta);

  /// Called when Gurgles jumps — adds a destabilising impulse.
  void applyJumpImpulse() {
    final dir = Random().nextBool() ? 1.0 : -1.0;
    tilt += dir * 0.18;
    tilt = tilt.clamp(-1.0, 1.0);
  }

  double _difficulty = 0.0;
  double _drainBonusRemainingSec = 0.0;
  double _driftDirection = 0.0;

  /// Called each frame from GameScene with elapsed/rampSeconds in [0, 1].
  void applyDifficulty(double t) {
    _difficulty = t.clamp(0.0, 1.0);
  }

  double get _amplitudeMultiplier =>
      1.0 + _difficulty * (GameConfig.wobbleAmplitudeMaxMultiplier - 1.0);

  double get _driftRate =>
      GameConfig.driftRateBase +
      _difficulty * (GameConfig.driftRateMax - GameConfig.driftRateBase);

  /// Direction the hooch naturally tips over time. Set once per run by the
  /// scene (randomly ±1). 0 disables drift — useful for tests that want to
  /// observe pure wobble behaviour.
  void setDriftDirection(double dir) {
    _driftDirection = dir;
  }

  /// Boost the spill-meter drain rate for [duration]. Stacks by extension:
  /// if another bonus is already active, take the longer remaining time.
  void grantSpillDrain(Duration duration) {
    final sec = duration.inMilliseconds / 1000.0;
    if (sec > _drainBonusRemainingSec) _drainBonusRemainingSec = sec;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * GameConfig.wobbleBaseFrequency * 2 * pi;
    final wobble =
        sin(_phase) * GameConfig.wobbleBaseAmplitude * _amplitudeMultiplier * dt;
    final drift = _driftDirection * _driftRate * dt;
    tilt += wobble + drift;
    tilt = tilt.clamp(-1.0, 1.0);

    if (tilt.abs() > GameConfig.spillThreshold) {
      final over = tilt.abs() - GameConfig.spillThreshold;
      spill += over * GameConfig.spillFillRate * dt;
    } else if (tilt.abs() < GameConfig.spillDrainThreshold) {
      final drainMult = _drainBonusRemainingSec > 0
          ? GameConfig.potionSpillDrainBonusMultiplier
          : 1.0;
      spill -= GameConfig.spillDrainRate * drainMult * dt;
    }
    if (_drainBonusRemainingSec > 0) {
      _drainBonusRemainingSec = (_drainBonusRemainingSec - dt).clamp(0.0, double.infinity);
    }
    spill = spill.clamp(0.0, 1.0);
  }
}
