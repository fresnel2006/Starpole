import 'package:flutter/material.dart';

import '../../application/couleurs.dart';
import '../styles.dart';
import 'icone_sirene.dart';

/// Les trois sortes de lignes que l'on voit dans les listes d'alertes.
enum SorteAlerte { urgence, objet, don }

/// Une ligne de liste : pastille ronde colorée, titre, lieu, temps, et soit
/// une flèche, soit une étiquette de statut à droite.
class LigneAlerte extends StatelessWidget {
  const LigneAlerte({
    super.key,
    required this.couleur,
    required this.icone,
    required this.titre,
    required this.details,
    required this.temps,
    this.statut,
    this.auAppui,
  });

  final Color couleur;
  final Widget icone;
  final String titre;
  final String details;
  final String temps;

  /// Étiquette de statut (« En cours », « Résolue »). Sans elle : une flèche.
  final Widget? statut;
  final VoidCallback? auAppui;

  /// Ligne dont la pastille et le titre suivent la sorte d'alerte.
  factory LigneAlerte.depuisSorte({
    Key? key,
    required SorteAlerte sorte,
    required String titre,
    required String details,
    required String temps,
    VoidCallback? auAppui,
  }) {
    switch (sorte) {
      case SorteAlerte.urgence:
        return LigneAlerte(
          key: key,
          couleur: Couleurs.rouge,
          icone: const IconeSirene(taille: 26),
          titre: titre,
          details: details,
          temps: temps,
          auAppui: auAppui,
        );
      case SorteAlerte.objet:
        return LigneAlerte(
          key: key,
          couleur: Couleurs.orange,
          icone: const Icon(Icons.location_on, size: 28, color: Colors.white),
          titre: titre,
          details: details,
          temps: temps,
          auAppui: auAppui,
        );
      case SorteAlerte.don:
        return LigneAlerte(
          key: key,
          couleur: Couleurs.vert,
          icone: const Icon(Icons.home, size: 28, color: Colors.white),
          titre: titre,
          details: details,
          temps: temps,
          auAppui: auAppui,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: auAppui,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: couleur,
                shape: BoxShape.circle,
                boxShadow: Styles.ombre,
              ),
              child: icone,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, style: Styles.gras(15, couleur)),
                  const SizedBox(height: 2),
                  Text(details, style: Styles.gras(11.5, Colors.black)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 15,
                        color: Couleurs.grisTexte,
                      ),
                      const SizedBox(width: 5),
                      Text(temps, style: Styles.gras(10.5, Couleurs.grisTexte)),
                    ],
                  ),
                ],
              ),
            ),
            statut ??
                const Icon(Icons.chevron_right, size: 28, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
