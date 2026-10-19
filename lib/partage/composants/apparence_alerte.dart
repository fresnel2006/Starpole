import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../application/couleurs.dart';
import '../../noyau/alerte.dart';
import 'icone_sirene.dart';

/// La couleur et l'icône de chaque type d'alerte, comme sur les maquettes :
/// rouge avec la sirène pour une urgence, orange avec un repère pour un
/// service, vert avec une maison pour un don.
extension ApparenceTypeAlerte on TypeAlerte {
  Color get couleur {
    switch (this) {
      case TypeAlerte.urgence:
        return Couleurs.rouge;
      case TypeAlerte.service:
        return Couleurs.orange;
      case TypeAlerte.don:
        return Couleurs.vert;
    }
  }

  /// L'icône blanche, à poser dans une pastille de la couleur du type.
  Widget icone({double taille = 24}) {
    switch (this) {
      case TypeAlerte.urgence:
        return IconeSirene(taille: taille);
      case TypeAlerte.service:
        return Icon(Icons.location_on, size: taille, color: Colors.white);
      case TypeAlerte.don:
        return Icon(Icons.home, size: taille, color: Colors.white);
    }
  }
}

/// La photo d'une alerte, ou un emplacement gris quand il n'y en a pas.
/// Elle garde la forme [ratio] (largeur divisée par hauteur) et le milieu de
/// l'image reste au milieu du cadre. Les photos enregistrées sont déjà coupées
/// en 2 pour 1, donc on les voit presque en entier.
class PhotoAlerte extends StatelessWidget {
  const PhotoAlerte({
    super.key,
    required this.photo,
    this.ratio = 2.4,
    this.entiere = false,
  });

  final Uint8List? photo;
  final double ratio;

  /// Vrai pour montrer la photo en entier, avec sa propre forme (sans la
  /// couper) ; sinon elle est coupée au [ratio] (cartes de la liste).
  final bool entiere;

  @override
  Widget build(BuildContext context) {
    if (entiere && photo != null) {
      return Image.memory(
        photo!,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        gaplessPlayback: true,
      );
    }
    return AspectRatio(
      aspectRatio: ratio,
      child: photo != null
          ? Image.memory(
              photo!,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              gaplessPlayback: true,
            )
          : Container(
              color: const Color(0xFFD8D2CC),
              alignment: Alignment.center,
              child: const Icon(
                Icons.image_outlined,
                size: 40,
                color: Colors.white,
              ),
            ),
    );
  }
}
