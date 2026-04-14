import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/local_store.dart';
import 'game_scene.dart';

/// Overlay widget shown on top of the paused game. Because it's a Flame
/// overlay and not a pushed route, there's no navigation transition — it
/// just appears, perfectly centered, over the frozen last frame.
class GameOverOverlay extends StatefulWidget {
  final GameScene game;
  final VoidCallback onExitToMenu;
  const GameOverOverlay({super.key, required this.game, required this.onExitToMenu});

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay> {
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
    final score = widget.game.score;
    final best = await _store.getBestScore();
    if (score > best) await _store.setBestScore(score);
    final name = await _store.getName() ?? 'Anon';
    final ok = await _api.submitScore(
      name: name,
      score: score,
      platform: platform,
      version: '1.0.0+1',
    );
    if (!mounted) return;
    setState(() {
      _best = score > best ? score : best;
      _submitStatus = ok ? 'Score submitted to gurgles.beer' : 'Offline — score saved locally';
    });
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.game.score;
    final newBest = score >= _best && score > 0;
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Game Over',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD4A744),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.game.endReason ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),
              Text(
                '$score',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (newBest)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'New Best!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFD4A744), fontSize: 18),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                _submitStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => widget.game.restart(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 16),
                  backgroundColor: const Color(0xFFD4A744),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Retry', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onExitToMenu,
                child: const Text('Menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
