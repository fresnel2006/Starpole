import 'package:flutter/material.dart';

import '../styles.dart';

/// Avatar rond. En attendant les vraies photos, une icône de personne
/// (ou une image si [image] est donnée).
class AvatarPersonne extends StatelessWidget {
  const AvatarPersonne({
    super.key,
    this.taille = 48,
    this.couleurFond = const Color(0xFFE9D5D5),
    this.image,
    this.avecOmbre = false,
  });

  final double taille;
  final Color couleurFond;

  /// Chemin d'une image dans les assets (facultatif).
  final String? image;
  final bool avecOmbre;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: couleurFond,
        shape: BoxShape.circle,
        boxShadow: avecOmbre ? Styles.ombre : null,
      ),
      child: image != null
          ? Image.asset(image!, fit: BoxFit.cover)
          : Icon(Icons.person, size: taille * 0.62, color: Colors.white),
    );
  }
}
