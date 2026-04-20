import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/game_config.dart';

class LeaderboardEntry {
  final String name;
  final int score;
  final DateTime? createdAt;
  LeaderboardEntry({required this.name, required this.score, this.createdAt});

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
    name: j['name'] as String? ?? '',
    score: (j['score'] as num?)?.toInt() ?? 0,
    createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt']) : null,
  );
}

class ApiClient {
  final Duration _timeout = const Duration(seconds: GameConfig.apiTimeoutSeconds);

  Future<bool> submitScore({
    required String name,
    required int score,
    required String platform,
    required String version,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${GameConfig.apiBaseUrl}/api/scores'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'score': score,
          'platform': platform,
          'version': version,
        }),
      ).timeout(_timeout);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<List<LeaderboardEntry>> fetchTop({int limit = 50}) async {
    final res = await http.get(
      Uri.parse('${GameConfig.apiBaseUrl}/api/scores/top?limit=$limit'),
    ).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('Leaderboard request failed: HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (body['scores'] as List? ?? []);
    return list
        .whereType<Map<String, dynamic>>()
        .map(LeaderboardEntry.fromJson)
        .toList();
  }
}
