import 'package:flame/sprite.dart';
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';

/// Standalone Flutter widget that plays Gurgles' idle animation —
/// no FlameGame required. Used on the menu screen while the player
/// types their name.
class GurglesIdleWidget extends StatefulWidget {
  final double size;
  const GurglesIdleWidget({super.key, this.size = 160});

  @override
  State<GurglesIdleWidget> createState() => _GurglesIdleWidgetState();
}

class _GurglesIdleWidgetState extends State<GurglesIdleWidget> {
  SpriteAnimation? _animation;
  SpriteAnimationTicker? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sprites = <Sprite>[];
    for (int i = 0; i < 20; i++) {
      final name = i.toString().padLeft(3, '0');
      sprites.add(await Sprite.load('gurgles/idle/$name.png'));
    }
    final animation = SpriteAnimation.spriteList(sprites, stepTime: 0.08);
    if (!mounted) return;
    setState(() {
      _animation = animation;
      _ticker = animation.createTicker();
    });
  }

  @override
  Widget build(BuildContext context) {
    final animation = _animation;
    final ticker = _ticker;
    if (animation == null || ticker == null) {
      return SizedBox(width: widget.size, height: widget.size);
    }
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: SpriteAnimationWidget(
        animation: animation,
        animationTicker: ticker,
        anchor: Anchor.center,
      ),
    );
  }
}
