import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/local_store.dart';
import '../utils/routes.dart';
import 'game_screen.dart';

class GameOverScreen extends StatefulWidget {
  final int score;
  final String reason;
  const GameOverScreen({super.key, required this.score, required this.reason});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  final _store = LocalStore();
  final _api = ApiClient();
  String _submitStatus = 'Submitting score...';
  int _best = 0;

  @override
  void initState() {
    super.initState();
    _submit();
  }

  Future<void> _submit() async {
    final platform = Theme.of(context).platform.name.toLowerCase();
    final best = await _store.getBestScore();
    if (widget.score > best) {
      await _store.setBestScore(widget.score);
    }
    final name = await _store.getName() ?? 'Anon';
    final ok = await _api.submitScore(
      name: name,
      score: widget.score,
      platform: platform,
      version: '1.0.0+1',
    );
    if (!mounted) return;
    setState(() {
      _best = widget.score > best ? widget.score : best;
      _submitStatus = ok ? 'Score submitted to gurgles.beer' : 'Offline — score saved locally';
    });
  }

  void _retry() {
    Navigator.of(context).pushReplacement(fadeRoute(const GameScreen()));
  }

  void _menu() {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final newBest = widget.score >= _best && widget.score > 0;
    return Scaffold(
      backgroundColor: const Color(0xFF1E1A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Game Over',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD4A744),
                ),
              ),
              const SizedBox(height: 8),
              Text(widget.reason,
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 32),
              Text('${widget.score}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold)),
              if (newBest)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('New Best!',
                      style: TextStyle(color: Color(0xFFD4A744), fontSize: 18)),
                ),
              const SizedBox(height: 16),
              Text(_submitStatus,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _retry,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 16),
                  backgroundColor: const Color(0xFFD4A744),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Retry', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _menu, child: const Text('Menu')),
            ],
          ),
        ),
      ),
    );
  }
}
