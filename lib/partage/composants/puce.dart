import 'package:flutter/material.dart';

import '../styles.dart';
import 'effet_creux.dart';

/// Petite étiquette arrondie (Urgent, En cours, Résolue, Efficace...).
class Puce extends StatelessWidget {
  const Puce({
    super.key,
    required this.texte,
    required this.fond,
    required this.couleurTexte,
    this.taille = 11,
    this.ombre = false,
    this.enCreux = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  });

  final String texte;
  final Color fond;
  final Color couleurTexte;
  final double taille;
  final bool ombre;

  /// Si vrai, l'étiquette paraît enfoncée (ombre à l'intérieur).
  final bool enCreux;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (enCreux) {
      return EffetCreux(
        fond: fond,
        rayon: 14,
        padding: padding,
        child: Text(texte, style: Styles.gras(taille, couleurTexte)),
      );
    }
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(14),
        boxShadow: ombre ? Styles.ombre : null,
      ),
      child: Text(texte, style: Styles.gras(taille, couleurTexte)),
    );
  }
}
