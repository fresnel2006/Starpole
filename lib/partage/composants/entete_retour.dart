import 'package:flutter/material.dart';

import '../styles.dart';

/// En-tête des écrans secondaires : flèche retour et titre.
class EnteteRetour extends StatelessWidget {
  const EnteteRetour({
    super.key,
    required this.titre,
    this.auRetour,
    this.tailleTitre = 17,
  });

  final String titre;

  /// Action de la flèche (par défaut : revenir à l'écran précédent).
  final VoidCallback? auRetour;
  final double tailleTitre;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: auRetour ?? () => Navigator.of(context).maybePop(),
          child: Container(
            width: 40,
            height: 40,
            color: Colors.transparent,
            alignment: Alignment.centerLeft,
            child: const Icon(
              Icons.chevron_left,
              size: 34,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            titre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Styles.gras(tailleTitre, Colors.black),
          ),
        ),
      ],
    );
  }
}
