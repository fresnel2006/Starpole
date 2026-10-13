import 'package:flutter/material.dart';

import '../../application/couleurs.dart';
import '../../partage/composants/champ_recherche.dart';
import '../../partage/composants/effet_creux.dart';
import '../../partage/composants/icone_sirene.dart';
import '../../partage/styles.dart';
import '../alertes/ecran_details_alerte.dart';

/// Onglet Accueil : en-tête avec la photo de la ville, recherche, types
/// d'alerte (affichés avec le bouton « Catégories ») et alertes proches.
class EcranAccueil extends StatefulWidget {
  const EcranAccueil({super.key});

  @override
  State<EcranAccueil> createState() => _EcranAccueilState();
}

class _EcranAccueilState extends State<EcranAccueil> {
  /// Vrai quand les trois tuiles (urgences, aides, dons) sont affichées.
  bool _tuilesVisibles = false;

  void _ouvrirDetails() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const EcranDetailsAlerte()));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Photo de la ville qui s'estompe vers le blanc.
        const Positioned(top: 0, left: 0, right: 0, child: _EnteteImage()),
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Lieu(),
                const SizedBox(height: 16),
                const ChampRecherche(
                  indication: 'Rechercher un aide, une alerte , un lien ....',
                ),
                const SizedBox(height: 34),
                _TitreSection(
                  icone: const Icon(
                    Icons.bolt,
                    size: 22,
                    color: Couleurs.rouge,
                  ),
                  texte: "Types d'alerte",
                  droite: GestureDetector(
                    onTap: () =>
                        setState(() => _tuilesVisibles = !_tuilesVisibles),
                    child: const _BoutonCategories(),
                  ),
                ),
                if (_tuilesVisibles) ...[
                  const SizedBox(height: 18),
                  const _TuilesTypes(),
                ],
                const SizedBox(height: 26),
                const _TitreSection(
                  icone: Icon(Icons.gps_fixed, size: 22, color: Colors.black),
                  texte: 'Alertes a proximité',
                  droite: _BadgeNombre(texte: '2 Alertes'),
                ),
                const SizedBox(height: 20),
                _CarteAlerte(
                  couleur: Couleurs.rouge,
                  icone: const IconeSirene(taille: 22),
                  titre: 'Personne en detresse',
                  auAppui: _ouvrirDetails,
                ),
                if (!_tuilesVisibles) ...[
                  const SizedBox(height: 18),
                  _CarteAlerte(
                    couleur: Couleurs.orange,
                    icone: const Icon(
                      Icons.location_on,
                      size: 22,
                      color: Colors.white,
                    ),
                    titre: 'Objet perdu',
                    auAppui: _ouvrirDetails,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Photo d'Abidjan en haut de l'écran, fondue vers le blanc en bas.
class _EnteteImage extends StatelessWidget {
  const _EnteteImage();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/Infos_departs_photo_arriereplan.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00FFFFFF), Colors.white],
                stops: [0.5, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Lieu extends StatelessWidget {
  const _Lieu();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.location_on, size: 36, color: Couleurs.rouge),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Abidjan, Plateau', style: Styles.gras(22, Colors.white)),
            Text(
              'Restez informé, restez en securité',
              style: Styles.gras(11.5, Colors.white, poids: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

/// Titre de section : icône, texte en gras et un élément à droite.
class _TitreSection extends StatelessWidget {
  const _TitreSection({
    required this.icone,
    required this.texte,
    required this.droite,
  });

  final Widget icone;
  final String texte;
  final Widget droite;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icone,
        const SizedBox(width: 10),
        Expanded(child: Text(texte, style: Styles.gras(14, Colors.black))),
        droite,
      ],
    );
  }
}

class _BoutonCategories extends StatelessWidget {
  const _BoutonCategories();

  @override
  Widget build(BuildContext context) {
    return EffetCreux(
      fond: Couleurs.rougeRose,
      rayon: 13,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.grid_view_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text('Catégories', style: Styles.gras(10.5, Colors.white)),
          const SizedBox(width: 3),
          const Icon(Icons.chevron_right, size: 14, color: Colors.white),
        ],
      ),
    );
  }
}

class _BadgeNombre extends StatelessWidget {
  const _BadgeNombre({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    return EffetCreux(
      fond: Couleurs.vertVif,
      rayon: 13,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(texte, style: Styles.gras(10.5, Colors.white)),
    );
  }
}

/// Les trois grandes tuiles : urgences, aides, dons.
class _TuilesTypes extends StatelessWidget {
  const _TuilesTypes();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _TuileRaccourci(
            couleur: Couleurs.rouge,
            icone: Icon(Icons.campaign_outlined, size: 44, color: Colors.white),
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

/// Carte d'une alerte proche : photo en haut, puis pastille, textes et flèche.
class _CarteAlerte extends StatelessWidget {
  const _CarteAlerte({
    required this.couleur,
    required this.icone,
    required this.titre,
    required this.auAppui,
  });

  final Color couleur;
  final Widget icone;
  final String titre;
  final VoidCallback auAppui;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: auAppui,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: Styles.ombre,
        ),
        child: Column(
          children: [
            // Emplacement de la photo de l'alerte (ajoutée plus tard).
            Container(
              height: 96,
              width: double.infinity,
              color: const Color(0xFFD8D2CC),
              alignment: Alignment.center,
              child: const Icon(
                Icons.image_outlined,
                size: 40,
                color: Colors.white,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: couleur,
                      shape: BoxShape.circle,
                      boxShadow: Styles.ombre,
                    ),
                    child: icone,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titre, style: Styles.gras(13, couleur)),
                        Text(
                          'Treichville • 1.2 km',
                          style: Styles.gras(11.5, Colors.black),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 14,
                              color: Couleurs.grisTexte,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Il y'a 15 min",
                              style: Styles.gras(10, Couleurs.grisTexte),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 26,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
