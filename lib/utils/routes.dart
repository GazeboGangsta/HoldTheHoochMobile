import 'package:flutter/material.dart';

/// Snap-in page route — no slide, just a quick fade. Prevents the game's
/// last-frame sliding across into the GameOver screen.
PageRouteBuilder<T> fadeRoute<T>(Widget page, {Duration duration = const Duration(milliseconds: 120)}) {
  return PageRouteBuilder<T>(
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder: (context, anim, secondary) => page,
    transitionsBuilder: (context, anim, secondary, child) =>
        FadeTransition(opacity: anim, child: child),
  );
}
