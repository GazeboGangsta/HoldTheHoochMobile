/// Static tuning values for the game. Keep all magic numbers here.
/// See docs/GAME_DESIGN.md for rationale behind each constant.
class GameConfig {
  static const double baseScrollSpeed = 280.0;
  static const double maxScrollSpeedMultiplier = 2.0;
  static const double difficultyRampSeconds = 180.0;

  static const double gravity = 2800.0;
  static const double jumpVelocityMin = -480.0;
  static const double jumpVelocityMax = -720.0;
  static const double jumpHoldMaxMs = 220.0;

  static const double spillThreshold = 0.7;
  static const double spillDrainThreshold = 0.4;
  static const double spillFillRate = 0.6;
  static const double spillDrainRate = 0.25;

  static const double wobbleBaseFrequency = 1.2;
  static const double wobbleBaseAmplitude = 0.25;

  static const double referenceWidth = 1080;
  static const double referenceHeight = 1920;

  static const String apiBaseUrl = 'https://gurgles.beer';
  static const int apiTimeoutSeconds = 5;

  // Score multiplier: +0.1x per 10 survival seconds, capped 3x.
  // See docs/GAME_DESIGN.md § Scoring.
  static const double scoreMultiplierIntervalSeconds = 10.0;
  static const double scoreMultiplierStep = 0.1;
  static const double scoreMultiplierMax = 3.0;

  // Potion pickup grants N seconds of boosted spill-meter drain.
  static const double potionSpillDrainBonusSeconds = 1.0;
  static const double potionSpillDrainBonusMultiplier = 4.0;

  // Passive wobble amplitude scales with difficulty curve up to this cap
  // (evaluated at the end of difficultyRampSeconds — matches spec's 1.7x).
  static const double wobbleAmplitudeMaxMultiplier = 1.7;

  // Directional drift bias — the "bias toward outer edges as speed
  // increases" half of the wobble spec. Each run picks a direction; tilt
  // drifts toward that edge at driftRateBase at difficulty 0, lerping
  // toward driftRateMax at difficulty 1. Player must drag to counter.
  static const double driftRateBase = 0.05;
  static const double driftRateMax = 0.20;

  // Tankard visually leans with balance.tilt so the player can see which
  // way the hooch is tipping and which direction to counter-drag.
  // 0.6 rad ~= 34 degrees at tilt = ±1.
  static const double tankardMaxLeanRadians = 0.6;
}
