import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/couleurs.dart';
import '../inscription/ecran_inscription.dart';

/// Une page de l'écran d'infos de départ (seul le texte change).
class _PageInfo {
  const _PageInfo(this.description);

  final List<InlineSpan> description;
}

/// Écran d'infos de départ : 3 pages avec photo d'Abidjan, titre et texte.
/// Un seul écran gère les 3 pages, avec un fondu entre chaque texte.
class EcranInfoDeparts extends StatefulWidget {
  const EcranInfoDeparts({super.key});

  @override
  State<EcranInfoDeparts> createState() => _EcranInfoDepartsState();
}

class _EcranInfoDepartsState extends State<EcranInfoDeparts> {
  static const Color _couleurTitre = Color(0xFF000000);
  static const Color _couleurTexte = Color(0xFF555555);
  static const Color _couleurPointInactif = Color(0xFFD9D9D9);

  static const TextStyle _styleTexte = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.6,
    color: _couleurTexte,
  );
  static const TextStyle _styleMarque = TextStyle(color: Couleurs.rouge);

  static const List<_PageInfo> _pages = [
    _PageInfo([
      TextSpan(text: 'Star'),
      TextSpan(text: 'Pole', style: _styleMarque),
      TextSpan(
        text:
            ' vous permet de signaler, recevoir et répondre à des alertes '
            'de votre communauté, en temps réel, à Abidjan.',
      ),
    ]),
    _PageInfo([
      TextSpan(
        text:
            "Recevez des alertes en temps réel\ndès qu'un voisin a besoin "
            "d'aide ou\npropose la sienne près de chez\nvous.",
      ),
    ]),
    _PageInfo([
      TextSpan(text: 'Répondez, aidez, connectez-vous\n: Star'),
      TextSpan(text: 'Pole', style: _styleMarque),
      TextSpan(
        text: ", c'est la solidarité de quartier qui s'organise,\nensemble.",
      ),
    ]),
  ];

  int _indexPage = 0;

  bool get _estDernierePage => _indexPage == _pages.length - 1;

  void _allerA(int page) => setState(() => _indexPage = page);

  // « Passer » et « C'est parti ! » ouvrent la page d'inscription.
  void _terminer() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const EcranInscription()));
  }

  void _suivant() => _estDernierePage ? _terminer() : _allerA(_indexPage + 1);

  @override
  Widget build(BuildContext context) {
    final taille = MediaQuery.sizeOf(context);
    final hauteur = taille.height;
    // Le panneau blanc a son point le plus haut à 24 % de l'écran (renflement
    // à gauche) et rejoint le bord droit à 34 %, comme sur la maquette.
    final hautPanneau = hauteur * 0.24;
    final creux = hauteur * 0.10;
    // Marges du titre et du texte (les points et le bouton restent centrés).
    final margesTexte = EdgeInsets.only(
      left: taille.width * 0.066,
      right: taille.width * 0.06,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Photo d'arrière-plan.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: hautPanneau + creux + 24,
            child: Image.asset(
              'assets/images/Infos_departs_photo_arriereplan.jpg',
              fit: BoxFit.cover,
              // Photo décalée vers le haut pour montrer le pont comme sur la maquette.
              alignment: const Alignment(0, -0.37),
            ),
          ),
          // Panneau blanc à bord supérieur courbe.
          Positioned(
            top: hautPanneau,
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipPath(
              clipper: _DecoupeCourbe(creux: creux),
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.only(top: hauteur * 0.118),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: margesTexte,
                      child: const _Titre(couleur: _couleurTitre),
                    ),
                    const SizedBox(height: 22),
                    Expanded(
                      child: Padding(
                        padding: margesTexte,
                        // Glisser vers la gauche ou la droite change de page.
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragEnd: (details) {
                            final vitesse = details.primaryVelocity ?? 0;
                            if (vitesse < -200 && !_estDernierePage) {
                              _allerA(_indexPage + 1);
                            } else if (vitesse > 200 && _indexPage > 0) {
                              _allerA(_indexPage - 1);
                            }
                          },
                          // Le texte disparaît puis le suivant apparaît en fondu.
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 450),
                            switchInCurve: Curves.easeIn,
                            switchOutCurve: Curves.easeOut,
                            layoutBuilder: (actuel, precedents) => Stack(
                              alignment: Alignment.topLeft,
                              children: [...precedents, ?actuel],
                            ),
                            child: Align(
                              key: ValueKey(_indexPage),
                              alignment: Alignment.topLeft,
                              child: Text.rich(
                                TextSpan(
                                  style: _styleTexte,
                                  children: _pages[_indexPage].description,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: _Points(
                        nombre: _pages.length,
                        indexActif: _indexPage,
                        couleurInactif: _couleurPointInactif,
                      ),
                    ),
                    SizedBox(height: math.max(hauteur * 0.092 - 26, 16)),
                    Align(
                      alignment: Alignment.center,
                      child: _BoutonPrincipal(
                        libelle: _estDernierePage ? "C'est parti !" : 'Suivant',
                        auAppui: _suivant,
                      ),
                    ),
                    // Réserve la place de « Passer » pour que le bouton ne
                    // bouge pas d'une page à l'autre.
                    SizedBox(
                      height: 54,
                      child: Center(
                        child: _estDernierePage
                            ? null
                            : TextButton(
                                onPressed: _terminer,
                                child: const Text(
                                  'Passer',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Couleurs.rouge,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(
                      height: math.max(
                        hauteur * 0.08 - 22,
                        MediaQuery.paddingOf(context).bottom,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bouton retour (pages 2 et 3).
          if (_indexPage > 0)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 14,
              left: 16,
              child: Semantics(
                button: true,
                label: 'Retour',
                child: GestureDetector(
                  onTap: () => _allerA(_indexPage - 1),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Couleurs.rouge,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Titre commun aux trois pages.
class _Titre extends StatelessWidget {
  const _Titre({required this.couleur});

  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 28.5,
          fontWeight: FontWeight.w700,
          height: 1.5,
          color: couleur,
        ),
        children: const [
          TextSpan(text: 'Ensemble,\nplus fort face\naux '),
          TextSpan(
            text: 'urgences',
            style: TextStyle(color: Couleurs.rouge),
          ),
        ],
      ),
    );
  }
}

class _Points extends StatelessWidget {
  const _Points({
    required this.nombre,
    required this.indexActif,
    required this.couleurInactif,
  });

  final int nombre;
  final int indexActif;
  final Color couleurInactif;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < nombre; i++)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: i == indexActif ? Couleurs.rouge : couleurInactif,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class _BoutonPrincipal extends StatelessWidget {
  const _BoutonPrincipal({required this.libelle, required this.auAppui});

  final String libelle;
  final VoidCallback auAppui;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: libelle,
      child: GestureDetector(
        onTap: auAppui,
        child: Container(
          width: 158,
          height: 43,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Couleurs.rouge,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            libelle,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Découpe le haut du panneau blanc : petit renflement à gauche, puis une
/// courbe qui descend jusqu'au bord droit.
class _DecoupeCourbe extends CustomClipper<Path> {
  _DecoupeCourbe({required this.creux});

  /// Profondeur de la courbe entre le renflement et le bord droit.
  final double creux;

  @override
  Path getClip(Size size) {
    final largeur = size.width;
    return Path()
      ..moveTo(0, creux * 0.30)
      ..quadraticBezierTo(largeur * 0.04, 0, largeur * 0.14, 0)
      ..cubicTo(largeur * 0.45, 0, largeur * 0.65, creux, largeur, creux)
      ..lineTo(largeur, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_DecoupeCourbe ancien) => ancien.creux != creux;
}
