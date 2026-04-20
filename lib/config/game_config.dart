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

  // Bottom control strip. The play area sits above this strip; ground
  // visually terminates at the top of the strip; the strip itself is an
  // "underground" panel hosting the three control buttons.
  static const double controlStripHeightFraction = 0.14;

  // On-screen control buttons (left-tilt, right-tilt, jump). Sized so
  // they're thumb-friendly without crowding the strip.
  static const double tiltButtonSize = 84.0;
  static const double tiltButtonInset = 24.0;
  static const double tiltButtonGap = 16.0;

  /// Tilt change per second while a tilt-correction button is held.
  /// Order of magnitude faster than driftRateMax so the player can
  /// always out-correct the drift.
  static const double tiltButtonTorqueRate = 1.5;

  // M5a — splash emitter tuning (see docs/superpowers/specs/2026-04-20-m5a-particles-design.md).
  static const int splashBurstCount = 6;
  static const int splashGameOverBurstCount = 30;
  static const double splashTrickleRateBase = 5.0;   // particles/sec at tilt == spillThreshold
  static const double splashTrickleRateMax = 15.0;   // particles/sec at tilt == 1.0
  static const int splashGameOverDelayMs = 600;      // hold the overlay this long so the burst animates
  static const double splashGravity = 800.0;         // px/s² pulling splash droplets down
  static const double splashSpeedMin = 60.0;         // px/s min initial droplet speed
  static const double splashSpeedMax = 120.0;        // px/s max initial droplet speed

  // M5a — sparkle burst tuning. Deceleration is dt-based so feel is stable across
  // framerates. 4.8/s gives the familiar 0.92-per-frame decay at 60fps.
  static const double sparkleDecelerationRate = 4.8;
}
