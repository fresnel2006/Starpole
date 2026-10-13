import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/couleurs.dart';

/// Champ blanc arrondi avec une icône à gauche (téléphone, mail, mot de passe...).
/// Si [masque] est vrai, le texte est caché et un oeil permet de l'afficher.
///
/// Pour montrer qu'un champ est vide ou incorrect, on appelle
/// `signalerErreur()` : le champ vibre et clignote en rouge. On y accède avec
/// une `GlobalKey<ChampTexteState>`.
class ChampTexte extends StatefulWidget {
  const ChampTexte({
    super.key,
    required this.icone,
    required this.indication,
    this.masque = false,
    this.avecOeil = false,
    this.type = TextInputType.text,
    this.controleur,
    this.erreurEnRouge = false,
  });

  final IconData icone;
  final String indication;
  final bool masque;
  final bool avecOeil;
  final TextInputType type;

  /// Permet de lire ce que l'utilisateur a écrit.
  final TextEditingController? controleur;

  /// Si vrai, en cas d'erreur l'icône, le texte et le contour restent rouges
  /// jusqu'à ce que l'utilisateur écrive de nouveau (pour les fonds blancs).
  final bool erreurEnRouge;

  @override
  State<ChampTexte> createState() => ChampTexteState();
}

class ChampTexteState extends State<ChampTexte>
    with SingleTickerProviderStateMixin {
  late bool _cache = widget.masque;

  /// Anime la vibration et le clignotement (0 au repos, puis de 0 à 1).
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  /// Vrai pendant que le champ vibre et clignote.
  bool get enErreur => _animation.isAnimating;

  /// Vrai tant que le champ reste rouge après une erreur (voir [erreurEnRouge]).
  bool get rougeFixe => _rougeFixe;
  bool _rougeFixe = false;

  /// Fait vibrer le champ et le fait clignoter 3 fois en rouge.
  void signalerErreur() {
    HapticFeedback.mediumImpact();
    if (widget.erreurEnRouge) setState(() => _rougeFixe = true);
    _animation.forward(from: 0);
  }

  /// Part de rouge (de 0 à 1) du moment : clignotement, ou rouge fixe.
  double _partRouge() {
    if (_rougeFixe) return 1;
    final t = _animation.value;
    if (t == 0 || t == 1) return 0;
    return (math.sin(t * math.pi * 6 - math.pi / 2) + 1) / 2;
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
        // Vibration de gauche à droite qui s'éteint peu à peu.
        final decalage = math.sin(t * math.pi * 8) * 8 * (1 - t);
        // Clignotement : 3 pulsations, qui reviennent à 0 à la fin.
        final clignote = t == 0 || t == 1
            ? 0.0
            : (math.sin(t * math.pi * 6 - math.pi / 2) + 1) / 2;
        // Part de rouge appliquée au contour, à l'icône et au texte.
        final rouge = _rougeFixe ? 1.0 : clignote;
        return Transform.translate(
          offset: Offset(decalage, 0),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Color.lerp(
                Colors.white,
                const Color(0xFFFFD9D9),
                clignote,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Color.lerp(
                  const Color(0xFFE2E2E2),
                  Couleurs.rouge,
                  rouge,
                )!,
                width: 1 + rouge,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: enfant,
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final rouge = _partRouge();
          final noir = Color.lerp(Colors.black, Couleurs.rouge, rouge)!;
          final gris = Color.lerp(
            const Color(0xFF555555),
            Couleurs.rouge,
            rouge,
          )!;
          return Row(
            children: [
              Icon(widget.icone, size: 28, color: noir),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: widget.controleur,
                  obscureText: _cache,
                  keyboardType: widget.type,
                  cursorColor: noir,
                  // Dès que l'utilisateur écrit, le rouge fixe disparaît.
                  onChanged: (_) {
                    if (_rougeFixe) setState(() => _rougeFixe = false);
                  },
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: noir,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.indication,
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: gris,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (widget.avecOeil)
                GestureDetector(
                  onTap: () => setState(() => _cache = !_cache),
                  child: Icon(
                    _cache
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 26,
                    color: noir,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
