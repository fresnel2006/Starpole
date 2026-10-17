import 'package:flutter/material.dart';

import '../../application/couleurs.dart';
import '../../partage/composants/entete_retour.dart';
import '../../partage/styles.dart';
import 'textes_legaux.dart';

/// Affiche un texte légal (conditions d'utilisation, confidentialité) : un
/// titre, une introduction puis des parties numérotées, à faire défiler.
class EcranTexteLegal extends StatelessWidget {
  const EcranTexteLegal({super.key, required this.texte});

  final TexteLegal texte;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: EnteteRetour(titre: texte.titre),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      texte.introduction,
                      style: Styles.gras(
                        13,
                        Couleurs.grisTexte,
                        hauteur: 1.6,
                        poids: FontWeight.w500,
                      ),
                    ),
                    for (final section in texte.sections) ...[
                      const SizedBox(height: 24),
                      Text(
                        section.titre,
                        style: Styles.gras(15, Couleurs.rouge),
                      ),
                      for (final paragraphe in section.paragraphes) ...[
                        const SizedBox(height: 8),
                        Text(
                          paragraphe,
                          style: Styles.gras(
                            13,
                            Colors.black,
                            hauteur: 1.6,
                            poids: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
