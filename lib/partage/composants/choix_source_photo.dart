import 'package:flutter/material.dart';

import '../../application/couleurs.dart';
import '../../noyau/service_photo.dart';
import '../styles.dart';

/// Feuille du bas : prendre une photo ou en choisir une dans la galerie.
/// Renvoie la source choisie, ou null si l'utilisateur ferme la feuille.
Future<SourcePhoto?> choisirSourcePhoto(
  BuildContext context, {
  String titre = 'Photo de profil',
}) {
  return showModalBottomSheet<SourcePhoto>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Couleurs.grisBordure,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(titre, style: Styles.gras(18, Colors.black)),
            const SizedBox(height: 8),
            const _OptionPhoto(
              icone: Icons.photo_camera,
              texte: 'Prendre une photo',
              source: SourcePhoto.camera,
            ),
            const _OptionPhoto(
              icone: Icons.photo_library,
              texte: 'Choisir dans la galerie',
              source: SourcePhoto.galerie,
            ),
          ],
        ),
      ),
    ),
  );
}

class _OptionPhoto extends StatelessWidget {
  const _OptionPhoto({
    required this.icone,
    required this.texte,
    required this.source,
  });

  final IconData icone;
  final String texte;
  final SourcePhoto source;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(source),
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            Icon(icone, size: 28, color: Couleurs.rouge),
            const SizedBox(width: 16),
            Text(texte, style: Styles.gras(14.5, Colors.black)),
          ],
        ),
      ),
    );
  }
}
