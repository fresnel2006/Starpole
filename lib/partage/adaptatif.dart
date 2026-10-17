import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Largeur maximale du contenu : au-delà (tablette, téléphone en paysage),
/// l'appli reste centrée à cette largeur au lieu de s'étirer.
const double largeurMaxContenu = 520;

/// Taille maximale du texte : le texte suit le réglage du téléphone (utile pour
/// les personnes qui voient mal) mais pas au point de casser les écrans.
const double echelleTexteMax = 1.3;

/// Hauteur de travail d'un écran dessiné d'après une maquette, où les éléments
/// sont placés en pourcentage de la hauteur. Elle vaut la hauteur de l'écran,
/// mais jamais moins de [minimum] (et davantage quand le texte est agrandi) :
/// sur un petit écran, l'écran défile au lieu de faire se chevaucher les
/// éléments.
double hauteurConception(BuildContext context, double minimum) {
  final hauteur = MediaQuery.sizeOf(context).height;
  final texte = MediaQuery.textScalerOf(context).scale(1);
  return math.max(hauteur, minimum * math.max(1, texte));
}

/// Place l'appli dans une zone de largeur limitée et plafonne la taille du
/// texte. Placé dans le `builder` du `MaterialApp`, il agit sur tous les écrans :
/// les `MediaQuery` des écrans voient la largeur réellement disponible.
Widget cadreAdaptatif(BuildContext context, Widget? enfant) {
  final donnees = MediaQuery.of(context);
  final largeur = donnees.size.width;
  final contenu = MediaQuery(
    data: donnees.copyWith(
      size: Size(math.min(largeur, largeurMaxContenu), donnees.size.height),
      textScaler: donnees.textScaler.clamp(maxScaleFactor: echelleTexteMax),
    ),
    child: enfant ?? const SizedBox.shrink(),
  );
  if (largeur <= largeurMaxContenu) return contenu;
  return ColoredBox(
    color: const Color(0xFFF1F1F1),
    child: Center(
      child: SizedBox(
        width: largeurMaxContenu,
        height: donnees.size.height,
        child: contenu,
      ),
    ),
  );
}
