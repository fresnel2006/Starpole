import 'package:flutter/material.dart';

import '../../application/couleurs.dart';
import '../../partage/composants/champ_recherche.dart';
import '../../partage/composants/ligne_alerte.dart';
import '../../partage/styles.dart';
import '../alertes/ecran_details_alerte.dart';

/// Onglet Accueil : lieu, recherche, trois raccourcis et alertes proches.
class EcranAccueil extends StatelessWidget {
  const EcranAccueil({super.key});

  void _ouvrirDetails(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const EcranDetailsAlerte()));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8, top: 4),
              child: _Lieu(),
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: ChampRecherche(
                indication: 'Rechercher un aide, une alerte , un lien ....',
              ),
            ),
            const SizedBox(height: 26),
            const Row(
              children: [
                Expanded(
                  child: _TuileRaccourci(
                    couleur: Couleurs.rouge,
                    icone: Icon(
                      Icons.campaign_outlined,
                      size: 44,
                      color: Colors.white,
                    ),
                    libelle: 'Voir les\nurgences',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _TuileRaccourci(
                    couleur: Couleurs.vert,
                    icone: Icon(
                      Icons.handshake_outlined,
                      size: 44,
                      color: Colors.white,
                    ),
                    libelle: 'Voir les\naides',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _TuileRaccourci(
                    couleur: Couleurs.bleu,
                    icone: Icon(
                      Icons.inventory_2_outlined,
                      size: 44,
                      color: Colors.white,
                    ),
                    libelle: 'Voir les\ndons',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Alertes a proximité',
                    style: Styles.gras(13.5, Colors.black),
                  ),
                  Text('Voir tout', style: Styles.gras(13.5, Couleurs.vert)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _SeparateurLigne(
              enfant: LigneAlerte.depuisSorte(
                sorte: SorteAlerte.urgence,
                titre: 'Personne en detresse',
                details: 'Treichville • 1.2 km',
                temps: "Il y'a 15 min",
                auAppui: () => _ouvrirDetails(context),
              ),
            ),
            _SeparateurLigne(
              enfant: LigneAlerte.depuisSorte(
                sorte: SorteAlerte.objet,
                titre: 'Objet perdu',
                details: 'Plateau • 2.4 km',
                temps: "Il y'a 32 min",
                auAppui: () => _ouvrirDetails(context),
              ),
            ),
            LigneAlerte.depuisSorte(
              sorte: SorteAlerte.don,
              titre: 'Don de vetement',
              details: 'Cocody • 3.8 km',
              temps: "Il y'a 1h",
              auAppui: () => _ouvrirDetails(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _Lieu extends StatelessWidget {
  const _Lieu();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_on, size: 28, color: Colors.black),
        const SizedBox(width: 8),
        Text('Abidjan, Plateau', style: Styles.gras(17, Colors.black)),
      ],
    );
  }
}

/// Grande tuile colorée avec une icône et un texte sur deux lignes.
class _TuileRaccourci extends StatelessWidget {
  const _TuileRaccourci({
    required this.couleur,
    required this.icone,
    required this.libelle,
  });

  final Color couleur;
  final Widget icone;
  final String libelle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 145,
      padding: const EdgeInsets.fromLTRB(8, 22, 8, 14),
      decoration: BoxDecoration(
        color: couleur,
        borderRadius: BorderRadius.circular(12),
        boxShadow: Styles.ombre,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          icone,
          Text(
            libelle,
            textAlign: TextAlign.center,
            style: Styles.gras(13.5, Colors.white, hauteur: 1.35),
          ),
        ],
      ),
    );
  }
}

/// Une ligne suivie d'un fin trait gris, comme dans la maquette.
class _SeparateurLigne extends StatelessWidget {
  const _SeparateurLigne({required this.enfant});

  final Widget enfant;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        enfant,
        Container(height: 1, color: Couleurs.grisBordure),
      ],
    );
  }
}
