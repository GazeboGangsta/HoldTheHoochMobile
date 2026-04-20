import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/local_store.dart';
import '../widgets/leaderboard_entry_row.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _api = ApiClient();
  final _store = LocalStore();
  late Future<List<LeaderboardEntry>> _future;
  String? _playerName;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchTop(limit: 50);
    _store.getName().then((n) {
      if (mounted) setState(() => _playerName = n?.trim().toLowerCase());
    });
  }

  Future<void> _refresh() async {
    final f = _api.fetchTop(limit: 50);
    setState(() => _future = f);
    await f;
  }

  bool _isPlayerRow(LeaderboardEntry e) {
    final pn = _playerName;
    if (pn == null || pn.isEmpty) return false;
    return e.name.trim().toLowerCase() == pn;
  }

  Widget _buildList(List<LeaderboardEntry> scores) {
    if (scores.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No scores yet — be the first!',
            style: TextStyle(color: Colors.white70, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      color: const Color(0xFFD4A744),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: scores.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (ctx, i) {
          final e = scores[i];
          return LeaderboardEntryRow(
            rank: i + 1,
            entry: e,
            highlighted: _isPlayerRow(e),
          );
        },
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Could not load leaderboard.',
              style: TextStyle(color: Colors.white70, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A744),
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2A1A),
        foregroundColor: const Color(0xFFD4A744),
        title: const Text('Leaderboard'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<LeaderboardEntry>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFD4A744),
                ),
              );
            }
            if (snap.hasError) return _buildError(snap.error!);
            return _buildList(snap.data ?? const []);
          },
        ),
      ),
    );
  }
}
