import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../styles.dart';

/// Avatar rond. Sans photo, il montre l'icône de compte (le bonhomme gris
/// dans un cercle). Avec une [image], elle remplit le cercle, bien centrée.
class AvatarPersonne extends StatelessWidget {
  const AvatarPersonne({
    super.key,
    this.taille = 48,
    this.image,
    this.photo,
    this.avecOmbre = false,
  });

  final double taille;

  /// Chemin d'une image dans les assets (facultatif).
  final String? image;

  /// Photo d'une personne (octets d'une image), si on la connaît.
  final Uint8List? photo;
  final bool avecOmbre;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: avecOmbre ? Styles.ombre : null,
      ),
      child: ClipOval(
        child: photo != null
            ? Image.memory(
                photo!,
                width: taille,
                height: taille,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                gaplessPlayback: true,
              )
            : image != null
            ? Image.asset(
                image!,
                width: taille,
                height: taille,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              )
            : const IconeCompte(),
      ),
    );
  }
}

/// L'icône de compte : un cercle gris avec le bonhomme en blanc. Elle
/// remplit tout l'espace que son parent lui donne (un cercle, en général).
class IconeCompte extends StatelessWidget {
  const IconeCompte({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, contraintes) {
        final cote = contraintes.biggest.shortestSide;
        return Center(
          // Le dessin du cercle occupe environ 83 % de l'icône : on l'agrandit
          // pour qu'il touche exactement le bord de l'avatar.
          child: OverflowBox(
            maxWidth: cote * 1.2,
            maxHeight: cote * 1.2,
            child: Icon(
              Icons.account_circle,
              size: cote * 1.2,
              color: const Color(0xFFB5B5B5),
            ),
          ),
        );
      },
    );
  }
}
