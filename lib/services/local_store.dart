import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over SharedPreferences for player name and best score.
class LocalStore {
  static const _kName = 'player_name';
  static const _kBest = 'best_score';

  Future<String?> getName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kName);
  }

  Future<void> setName(String name) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, name.trim());
  }

  Future<int> getBestScore() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kBest) ?? 0;
  }

  Future<void> setBestScore(int score) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kBest, score);
  }
}
