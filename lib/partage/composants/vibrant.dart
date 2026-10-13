import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/couleurs.dart';

/// Enveloppe n'importe quel élément pour pouvoir le faire vibrer et clignoter
/// en rouge (par exemple une zone de texte vide). On appelle
/// `signalerErreur()` avec une `GlobalKey<VibrantState>`.
class Vibrant extends StatefulWidget {
  const Vibrant({super.key, required this.child, this.rayon = 14});

  final Widget child;

  /// Arrondi du cadre rouge qui clignote.
  final double rayon;

  @override
  State<Vibrant> createState() => VibrantState();
}

class VibrantState extends State<Vibrant> with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  /// Vrai pendant que l'élément vibre et clignote.
  bool get enErreur => _animation.isAnimating;

  void signalerErreur() {
    HapticFeedback.mediumImpact();
    _animation.forward(from: 0);
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, enfant) {
        final t = _animation.value;
        final decalage = math.sin(t * math.pi * 8) * 8 * (1 - t);
        final clignote = t == 0 || t == 1
            ? 0.0
            : (math.sin(t * math.pi * 6 - math.pi / 2) + 1) / 2;
        return Transform.translate(
          offset: Offset(decalage, 0),
          child: Stack(
            children: [
              enfant!,
              if (clignote > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Couleurs.rouge.withValues(
                          alpha: 0.12 * clignote,
                        ),
                        borderRadius: BorderRadius.circular(widget.rayon),
                        border: Border.all(
                          color: Couleurs.rouge.withValues(alpha: clignote),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
