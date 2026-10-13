import 'package:flutter/material.dart';

/// Styles de texte Poppins utilisés partout dans l'appli.
abstract final class Styles {
  /// Texte gras (poids 700 par défaut).
  static TextStyle gras(
    double taille,
    Color couleur, {
    double? hauteur,
    FontWeight poids = FontWeight.w700,
  }) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontSize: taille,
      fontWeight: poids,
      color: couleur,
      height: hauteur,
    );
  }

  /// Ombre douce sous les champs et les boutons.
  static const List<BoxShadow> ombre = [
    BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 3)),
  ];
}
