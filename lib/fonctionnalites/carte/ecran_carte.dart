import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/alerte.dart';
import '../../noyau/format_temps.dart';
import '../../noyau/position_utilisateur.dart';
import '../../noyau/service_alertes.dart';
import '../../partage/composants/apparence_alerte.dart';
import '../../partage/styles.dart';
import '../alertes/ecran_details_alerte.dart';

/// Onglet Carte : carte OpenStreetMap, vraies alertes en repères colorés et
/// fiche de l'alerte choisie en bas.
class EcranCarte extends StatefulWidget {
  const EcranCarte({super.key});

  @override
  State<EcranCarte> createState() => _EcranCarteState();
}

class _EcranCarteState extends State<EcranCarte> {
  // Si on ne connaît pas la position, la carte s'ouvre sur le Plateau, à Abidjan.
  static const LatLng _centreParDefaut = LatLng(5.3197, -4.0167);

  late final Stream<List<Alerte>> _flux = context
      .read<ServiceAlertes>()
      .alertes();

  /// L'alerte dont la fiche est affichée (choisie en appuyant sur un repère).
  String? _choisieId;

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
    final positionConnue = lieu?.latitude != null && lieu?.longitude != null;
    final centre = positionConnue
        ? LatLng(lieu!.latitude!, lieu.longitude!)
        : _centreParDefaut;

    return StreamBuilder<List<Alerte>>(
      stream: _flux,
      builder: (context, instantane) {
        // Les alertes en cours qui ont une position, dans ma ville.
        final alertes = (instantane.data ?? const <Alerte>[])
            .where(
              (a) =>
                  a.statut == StatutAlerte.enCours &&
                  a.aUnePosition &&
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
            Positioned.fill(
              child: FlutterMap(
                options: MapOptions(initialCenter: centre, initialZoom: 13.5),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.projet_starpole',
                  ),
                  MarkerLayer(
                    markers: [
                      for (final a in alertes)
                        Marker(
                          point: LatLng(a.latitude!, a.longitude!),
                          width: 44,
                          height: 52,
                          alignment: Alignment.topCenter,
                          child: GestureDetector(
                            onTap: () => setState(() => _choisieId = a.id),
                            child: Icon(
                              Icons.location_on,
                              size: a.id == choisie?.id ? 54 : 44,
                              color: a.type.couleur,
                            ),
                          ),
                        ),
                      if (positionConnue)
                        Marker(
                          point: centre,
                          width: 26,
                          height: 26,
                          child: const _PositionUtilisateur(),
                        ),
                    ],
                  ),
                ],
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
                    const Icon(
                      Icons.filter_alt_outlined,
                      size: 28,
                      color: Colors.black,
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

/// Le point bleu de la position de l'utilisateur.
class _PositionUtilisateur extends StatelessWidget {
  const _PositionUtilisateur();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A73E8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: Styles.ombre,
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
