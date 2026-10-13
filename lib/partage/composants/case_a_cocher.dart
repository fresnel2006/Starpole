import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/couleurs.dart';

/// Petite case carrée à cocher (Se souvenir de moi, conditions d'utilisation).
/// `signalerErreur()` la fait vibrer et clignoter en rouge (accès par une
/// `GlobalKey<CaseACocherState>`).
class CaseACocher extends StatefulWidget {
  const CaseACocher({super.key, required this.couleurFond, this.auChangement});

  /// Couleur de la case quand elle est vide.
  final Color couleurFond;

  /// Appelé avec la nouvelle valeur quand on coche ou décoche.
  final ValueChanged<bool>? auChangement;

  @override
  State<CaseACocher> createState() => CaseACocherState();
}

class CaseACocherState extends State<CaseACocher>
    with SingleTickerProviderStateMixin {
  bool _cochee = false;

  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  /// Vrai pendant que la case vibre et clignote.
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
    return GestureDetector(
      onTap: () {
        setState(() => _cochee = !_cochee);
        widget.auChangement?.call(_cochee);
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, enfant) {
          final t = _animation.value;
          final decalage = math.sin(t * math.pi * 8) * 5 * (1 - t);
          final clignote = t == 0 || t == 1
              ? 0.0
              : (math.sin(t * math.pi * 6 - math.pi / 2) + 1) / 2;
          return Transform.translate(
            offset: Offset(decalage, 0),
            child: Container(
              width: 19,
              height: 19,
              decoration: BoxDecoration(
                color: Color.lerp(
                  widget.couleurFond,
                  const Color(0xFFFFB3B3),
                  clignote,
                ),
                borderRadius: BorderRadius.circular(4),
                border: clignote > 0
                    ? Border.all(color: Couleurs.rouge, width: 1 + clignote)
                    : null,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: enfant,
            ),
          );
        },
        child: _cochee
            ? const Icon(Icons.check, size: 15, color: Colors.black)
            : null,
      ),
    );
  }
}
