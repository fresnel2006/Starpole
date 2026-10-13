import 'package:flutter/material.dart';

import '../../application/couleurs.dart';
import '../../partage/composants/champ_recherche.dart';
import '../../partage/composants/entete_retour.dart';
import '../../partage/composants/icone_sirene.dart';
import '../../partage/composants/ligne_alerte.dart';
import '../../partage/composants/puce.dart';
import '../alertes/ecran_suivi_alerte.dart';

/// Liste de mes alertes, aides et dons, avec leur statut.
class EcranMesAlertes extends StatelessWidget {
  const EcranMesAlertes({super.key});

  void _ouvrirSuivi(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const EcranSuiviAlerte()));
  }

  @override
  Widget build(BuildContext context) {
    const enCours = Puce(
      texte: 'En cours',
      fond: Couleurs.fondPuceOrange,
      couleurTexte: Couleurs.orange,
      taille: 10.5,
    );
    const resolue = Puce(
      texte: 'Résolue',
      fond: Couleurs.fondPuceVerte,
      couleurTexte: Couleurs.vert,
      taille: 10.5,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EnteteRetour(
                titre: 'Mes alertes, aides & dons',
                tailleTitre: 15.5,
              ),
              const SizedBox(height: 14),
              const ChampRecherche(indication: 'Recherche ....'),
              const SizedBox(height: 14),
              Container(height: 1, color: Couleurs.grisBordure),
              _Element(
                auAppui: () => _ouvrirSuivi(context),
                ligne: const LigneAlerte(
                  couleur: Couleurs.orange,
                  icone: IconeSirene(taille: 26),
                  titre: 'Don de nourriture',
                  details: 'Cocody • 2.1 km',
                  temps: "Il y'a 2h",
                  statut: enCours,
                ),
              ),
              _Element(
                auAppui: () => _ouvrirSuivi(context),
                ligne: const LigneAlerte(
                  couleur: Couleurs.vert,
                  icone: IconeSirene(taille: 26),
                  titre: 'Objet trouvé',
                  details: 'Plateau • 1.5 km',
                  temps: "Il y'a 15 min",
                  statut: resolue,
                ),
              ),
              _Element(
                auAppui: () => _ouvrirSuivi(context),
                ligne: const LigneAlerte(
                  couleur: Couleurs.rougeDoux,
                  icone: IconeSirene(taille: 26),
                  titre: 'Personne en detresse',
                  details: 'Treichville • 3.2 km',
                  temps: "Il y'a 6h",
                  statut: enCours,
                ),
              ),
              _Element(
                auAppui: () => _ouvrirSuivi(context),
                ligne: const LigneAlerte(
                  couleur: Color(0xFFA80000),
                  icone: IconeSirene(taille: 26),
                  titre: 'Urgence medicale',
                  details: 'Marcory • 4.8 km',
                  temps: "Il y'a 8h",
                  statut: resolue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Une ligne cliquable suivie d'un fin trait gris.
class _Element extends StatelessWidget {
  const _Element({required this.ligne, required this.auAppui});

  final Widget ligne;
  final VoidCallback auAppui;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: auAppui,
      child: Column(
        children: [
          ligne,
          Container(height: 1, color: Couleurs.grisBordure),
        ],
      ),
    );
  }
}
