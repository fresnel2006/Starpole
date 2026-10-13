import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/alerte.dart';
import '../../noyau/format_temps.dart';
import '../../noyau/position_utilisateur.dart';
import '../../noyau/service_alertes.dart';
import '../../noyau/service_localisation.dart';
import '../../partage/composants/apparence_alerte.dart';
import '../../partage/composants/champ_recherche.dart';
import '../../partage/composants/effet_creux.dart';
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

  /// Les alertes, en direct : l'écran se met à jour quand quelqu'un en publie.
  late final Stream<List<Alerte>> _alertes = context
      .read<ServiceAlertes>()
      .alertes();

  @override
  void initState() {
    super.initState();
    // On cherche la position une fois, la première fois qu'on arrive ici.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final position = context.read<PositionUtilisateur>();
      if (position.resultat == null) position.actualiser();
    });
  }

  /// Les alertes en cours de la ville de l'utilisateur (toutes, si on ne
  /// connaît pas encore sa ville).
  List<Alerte> _proches(List<Alerte> toutes, LieuActuel? lieu) {
    return toutes
        .where(
          (a) =>
              a.statut == StatutAlerte.enCours &&
              (lieu == null || a.ville.isEmpty || a.ville == lieu.ville),
        )
        .take(20)
        .toList();
  }

  void _ouvrirDetails(Alerte alerte) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EcranDetailsAlerte(alerte: alerte),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final position = context.watch<PositionUtilisateur>();
    final resultat = position.resultat;

    return Stack(
      children: [
        // Photo de la ville qui s'estompe vers le blanc.
        const Positioned(top: 0, left: 0, right: 0, child: _EnteteImage()),
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Lieu(
                  resultat: resultat,
                  auAppui:
                      resultat == null || resultat.etat == EtatLocalisation.ok
                      ? null
                      : position.reessayer,
                ),
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
                StreamBuilder<List<Alerte>>(
                  stream: _alertes,
                  builder: (context, instantane) {
                    final toutes = instantane.data;
                    final proches = toutes == null
                        ? const <Alerte>[]
                        : _proches(toutes, position.lieu);
                    final nombre = proches.length;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TitreSection(
                          icone: const Icon(
                            Icons.gps_fixed,
                            size: 22,
                            color: Colors.black,
                          ),
                          texte: 'Alertes a proximité',
                          droite: _BadgeNombre(
                            texte: toutes == null
                                ? '...'
                                : '$nombre ${nombre > 1 ? 'Alertes' : 'Alerte'}',
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (instantane.hasError)
                          const _MessageVide(
                            'Impossible de charger les alertes. '
                            'Vérifiez votre connexion.',
                          )
                        else if (toutes == null)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Couleurs.rouge,
                              ),
                            ),
                          )
                        else if (proches.isEmpty)
                          const _MessageVide(
                            'Aucune alerte près de chez vous pour le moment.',
                          )
                        else
                          for (final alerte in proches)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: _CarteAlerte(
                                alerte: alerte,
                                lieu: position.lieu,
                                auAppui: () => _ouvrirDetails(alerte),
                              ),
                            ),
                      ],
                    );
                  },
                ),
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

/// En-tête : le lieu où se trouve l'utilisateur. Si la position n'est pas
/// disponible, le texte explique pourquoi et un appui permet de réessayer.
class _Lieu extends StatelessWidget {
  const _Lieu({required this.resultat, required this.auAppui});

  /// Null tant que la position est en cours de recherche.
  final ResultatLocalisation? resultat;
  final VoidCallback? auAppui;

  String _texte() {
    final r = resultat;
    if (r == null) return 'Localisation...';
    switch (r.etat) {
      case EtatLocalisation.ok:
        return r.lieu?.libelle ?? 'Position inconnue';
      case EtatLocalisation.serviceDesactive:
        return 'Activez la localisation';
      case EtatLocalisation.permissionRefusee:
      case EtatLocalisation.permissionBloquee:
        return 'Autorisez la localisation';
      case EtatLocalisation.erreur:
        return 'Position indisponible';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ok = resultat?.etat == EtatLocalisation.ok;
    return GestureDetector(
      onTap: auAppui,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on, size: 36, color: Couleurs.rouge),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _texte(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Styles.gras(
                    ok || resultat == null ? 22 : 17,
                    Colors.white,
                  ),
                ),
                Text(
                  ok || resultat == null
                      ? 'Restez informé, restez en securité'
                      : 'Appuyez ici pour réessayer',
                  style: Styles.gras(
                    11.5,
                    Colors.white,
                    poids: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

/// Message simple quand il n'y a rien à montrer (liste vide, erreur).
class _MessageVide extends StatelessWidget {
  const _MessageVide(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: BoxDecoration(
        color: Couleurs.grisFond,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        texte,
        textAlign: TextAlign.center,
        style: Styles.gras(13, Couleurs.grisTexte, hauteur: 1.5),
      ),
    );
  }
}

/// Carte d'une alerte proche : photo en haut, puis pastille, textes et flèche.
class _CarteAlerte extends StatelessWidget {
  const _CarteAlerte({
    required this.alerte,
    required this.lieu,
    required this.auAppui,
  });

  final Alerte alerte;

  /// La position de l'utilisateur, pour calculer la distance.
  final LieuActuel? lieu;
  final VoidCallback auAppui;

  @override
  Widget build(BuildContext context) {
    final couleur = alerte.type.couleur;
    final distance = alerte.distanceKm(lieu?.latitude, lieu?.longitude);
    final details = distance == null
        ? alerte.lieu
        : '${alerte.lieu} • ${libelleDistance(distance)}';

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
            PhotoAlerte(photo: alerte.photo),
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
                    child: alerte.type.icone(taille: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alerte.categorie,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Styles.gras(13, couleur),
                        ),
                        Text(
                          details,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                              tempsEcoule(alerte.creeLe),
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
