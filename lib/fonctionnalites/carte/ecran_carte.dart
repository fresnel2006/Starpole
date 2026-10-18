import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/alerte.dart';
import '../../noyau/format_temps.dart';
import '../../noyau/position_utilisateur.dart';
import '../../noyau/service_alertes.dart';
import '../../partage/composants/apparence_alerte.dart';
import '../../partage/composants/carte_3d.dart';
import '../../partage/styles.dart';
import '../alertes/ecran_details_alerte.dart';

/// Onglet Carte : carte Mapbox en 3D, vraies alertes en repères colorés et
/// fiche de l'alerte choisie en bas.
class EcranCarte extends StatefulWidget {
  const EcranCarte({super.key});

  @override
  State<EcranCarte> createState() => _EcranCarteState();
}

class _EcranCarteState extends State<EcranCarte> {
  late final Stream<List<Alerte>> _flux = context
      .read<ServiceAlertes>()
      .alertes();

  /// L'alerte dont la fiche est affichée (choisie en appuyant sur un repère).
  String? _choisieId;

  /// Le type d'alerte montré sur la carte (null : tous).
  TypeAlerte? _filtre;

  /// Feuille du bas : choisir le type d'alertes à montrer.
  Future<void> _choisirFiltre() async {
    final choix = await showModalBottomSheet<_ChoixFiltre>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FeuilleFiltre(actuel: _filtre),
    );
    if (choix == null || !mounted) return;
    setState(() {
      _filtre = choix.type;
      _choisieId = null;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final position = context.read<PositionUtilisateur>();
      if (position.resultat == null) position.actualiser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lieu = context.watch<PositionUtilisateur>().lieu;

    return StreamBuilder<List<Alerte>>(
      stream: _flux,
      builder: (context, instantane) {
        // Les alertes en cours qui ont une position, dans ma ville.
        final alertes = (instantane.data ?? const <Alerte>[])
            .where(
              (a) =>
                  a.statut == StatutAlerte.enCours &&
                  a.aUnePosition &&
                  (_filtre == null || a.type == _filtre) &&
                  (lieu == null || a.ville.isEmpty || a.ville == lieu.ville),
            )
            .toList();

        Alerte? choisie;
        for (final a in alertes) {
          if (a.id == _choisieId) choisie = a;
        }
        choisie ??= alertes.isEmpty ? null : alertes.first;

        return Stack(
          children: [
            // La carte 3D prend tout l'écran, sous le bandeau et la fiche.
            Positioned.fill(
              child: context.read<ConstructeurCarte>()(
                context,
                DonneesCarte(
                  alertes: alertes,
                  choisieId: choisie?.id,
                  auChoix: (id) => setState(() => _choisieId = id),
                  hautEntete: MediaQuery.paddingOf(context).top + 80,
                  basFiche: choisie == null ? 90 : 235,
                  latitude: lieu?.latitude,
                  longitude: lieu?.longitude,
                ),
              ),
            ),
            // Bandeau du haut : filtre et titre.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  24,
                  MediaQuery.paddingOf(context).top + 14,
                  24,
                  16,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Filtrer les alertes',
                      child: GestureDetector(
                        onTap: _choisirFiltre,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // L'icône prend la couleur du type choisi (bleu pour
                            // les services, vert pour les dons, rouge pour les
                            // urgences), noire quand tout est montré.
                            Icon(
                              Icons.filter_alt_outlined,
                              size: 28,
                              color: _filtre == null
                                  ? Colors.black
                                  : couleurFiltre(_filtre!),
                            ),
                            // Un point de la même couleur rappelle qu'un
                            // filtre est actif.
                            if (_filtre != null)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: couleurFiltre(_filtre!),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Carte des alertes',
                          style: Styles.gras(16.5, Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),
                  ],
                ),
              ),
            ),
            // Fiche de l'alerte choisie, ou un message s'il n'y en a pas.
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: choisie == null
                  ? _FicheVide(chargement: instantane.data == null)
                  : _FicheAlerte(
                      alerte: choisie,
                      distance: choisie.distanceKm(
                        lieu?.latitude,
                        lieu?.longitude,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// La couleur d'un type dans le filtre : rouge pour les urgences, vert pour les
/// dons et bleu pour les services (comme les tuiles de « Poster une alerte »).
Color couleurFiltre(TypeAlerte type) =>
    type == TypeAlerte.service ? Couleurs.tuileService : type.couleur;

/// Ce que renvoie la feuille de filtre (un type, ou null pour « tous »).
class _ChoixFiltre {
  const _ChoixFiltre(this.type);

  final TypeAlerte? type;
}

/// La feuille du bas pour choisir le type d'alertes de la carte.
class _FeuilleFiltre extends StatelessWidget {
  const _FeuilleFiltre({required this.actuel});

  final TypeAlerte? actuel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            Text('Filtrer les alertes', style: Styles.gras(18, Colors.black)),
            const SizedBox(height: 8),
            _OptionFiltre(
              texte: 'Toutes les alertes',
              couleur: Colors.black,
              choisie: actuel == null,
              choix: const _ChoixFiltre(null),
            ),
            for (final type in TypeAlerte.values)
              _OptionFiltre(
                texte: type.libelle,
                couleur: couleurFiltre(type),
                choisie: actuel == type,
                choix: _ChoixFiltre(type),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionFiltre extends StatelessWidget {
  const _OptionFiltre({
    required this.texte,
    required this.couleur,
    required this.choisie,
    required this.choix,
  });

  final String texte;
  final Color couleur;
  final bool choisie;
  final _ChoixFiltre choix;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(choix),
      // L'option choisie se reconnaît à sa couleur : fond teinté, texte et
      // coche de la couleur du type (bleu pour les services).
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: choisie ? couleur.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                texte,
                style: Styles.gras(15, choisie ? couleur : Colors.black),
              ),
            ),
            if (choisie) Icon(Icons.check, size: 24, color: couleur),
          ],
        ),
      ),
    );
  }
}

const BoxDecoration _decorationFiche = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
  boxShadow: [
    BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, -3)),
  ],
);

class _FicheVide extends StatelessWidget {
  const _FicheVide({required this.chargement});

  final bool chargement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      decoration: _decorationFiche,
      child: Text(
        chargement
            ? 'Chargement des alertes...'
            : "Aucune alerte avec une position pour l'instant.",
        textAlign: TextAlign.center,
        style: Styles.gras(13, Couleurs.grisTexte),
      ),
    );
  }
}

class _FicheAlerte extends StatelessWidget {
  const _FicheAlerte({required this.alerte, required this.distance});

  final Alerte alerte;
  final double? distance;

  @override
  Widget build(BuildContext context) {
    final couleur = alerte.type.couleur;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: _decorationFiche,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: couleur,
                  shape: BoxShape.circle,
                  boxShadow: Styles.ombre,
                ),
                child: alerte.type.icone(taille: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alerte.categorie,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Styles.gras(15.5, couleur),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alerte.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Styles.gras(
                        11,
                        Couleurs.rougeDoux,
                        poids: FontWeight.w500,
                        hauteur: 1.45,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      distance == null
                          ? tempsEcoule(alerte.creeLe).toLowerCase()
                          : '${tempsEcoule(alerte.creeLe).toLowerCase()} • '
                                '${libelleDistance(distance!)}',
                      style: Styles.gras(
                        11,
                        Colors.black,
                        poids: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => EcranDetailsAlerte(alerte: alerte),
              ),
            ),
            child: Container(
              width: 215,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Couleurs.rouge,
                borderRadius: BorderRadius.circular(14),
                boxShadow: Styles.ombre,
              ),
              child: Text(
                'Voir les détails',
                style: Styles.gras(16.5, Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
