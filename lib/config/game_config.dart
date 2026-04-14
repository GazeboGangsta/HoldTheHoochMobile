/// Static tuning values for the game. Keep all magic numbers here.
/// See docs/GAME_DESIGN.md for rationale behind each constant.
class GameConfig {
  static const double baseScrollSpeed = 280.0;
  static const double maxScrollSpeedMultiplier = 2.0;
  static const double difficultyRampSeconds = 180.0;

  static const double gravity = 2200.0;
  static const double jumpVelocityMin = -600.0;
  static const double jumpVelocityMax = -1050.0;
  static const double jumpHoldMaxMs = 300.0;

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
}
