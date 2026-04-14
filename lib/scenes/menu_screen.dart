import 'package:flutter/material.dart';
import '../services/local_store.dart';
import 'game_screen.dart';

/// Flutter-widget-based menu. Keeps name entry simple and native-feeling.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _store = LocalStore();
  final _nameCtl = TextEditingController();
  int _best = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await _store.getName();
    final best = await _store.getBestScore();
    if (!mounted) return;
    setState(() {
      _nameCtl.text = name ?? '';
      _best = best;
    });
  }

  Future<void> _start() async {
    final name = _nameCtl.text.trim();
    if (name.isEmpty) return;
    await _store.setName(name);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Hold the Hooch',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD4A744),
                ),
              ),
              const SizedBox(height: 8),
              Text('Best: $_best',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 48),
              TextField(
                controller: _nameCtl,
                maxLength: 20,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: const InputDecoration(
                  hintText: 'Enter your name',
                  hintStyle: TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Color(0xFF2E3A2A),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _start,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 64, vertical: 18),
                  backgroundColor: const Color(0xFFD4A744),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Start', style: TextStyle(fontSize: 22)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
