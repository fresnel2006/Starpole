import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../application/couleurs.dart';
import '../../partage/composants/icone_sirene.dart';
import '../../partage/styles.dart';
import '../alertes/ecran_details_alerte.dart';

/// Onglet Carte : carte OpenStreetMap, repères d'alertes et fiche du bas.
class EcranCarte extends StatelessWidget {
  const EcranCarte({super.key});

  // Centre de la carte : le Plateau, à Abidjan.
  static const LatLng _centre = LatLng(5.3196, -4.0167);

  // Repères de démonstration autour du centre.
  static const List<(LatLng, Color)> _reperes = [
    (LatLng(5.3290, -4.0230), Couleurs.rouge),
    (LatLng(5.3340, -4.0090), Couleurs.orange),
    (LatLng(5.3265, -4.0160), Couleurs.orange),
    (LatLng(5.3200, -4.0070), Couleurs.vert),
    (LatLng(5.3120, -4.0010), Couleurs.rouge),
    (LatLng(5.3085, -4.0230), Couleurs.vert),
    (LatLng(5.3335, -3.9980), Couleurs.vert),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            options: const MapOptions(
              initialCenter: _centre,
              initialZoom: 13.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.projet_starpole',
              ),
              MarkerLayer(
                markers: [
                  for (final (point, couleur) in _reperes)
                    Marker(
                      point: point,
                      width: 44,
                      height: 52,
                      alignment: Alignment.topCenter,
                      child: Icon(Icons.location_on, size: 46, color: couleur),
                    ),
                  const Marker(
                    point: _centre,
                    width: 26,
                    height: 26,
                    child: _PositionUtilisateur(),
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
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
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
        // Fiche de l'alerte sélectionnée.
        const Positioned(bottom: 0, left: 0, right: 0, child: _FicheAlerte()),
      ],
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

class _FicheAlerte extends StatelessWidget {
  const _FicheAlerte();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 8,
            offset: Offset(0, -3),
          ),
        ],
      ),
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
                  color: Couleurs.rouge,
                  shape: BoxShape.circle,
                  boxShadow: Styles.ombre,
                ),
                child: const IconeSirene(taille: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personnes en détresse',
                      style: Styles.gras(15.5, Couleurs.rouge),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Une personne agé est perdu a Treichville, pres du marché.',
                      style: Styles.gras(
                        11,
                        Couleurs.rougeDoux,
                        poids: FontWeight.w500,
                        hauteur: 1.45,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "il y'a 15 minute • 2.3 Km",
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
                builder: (_) => const EcranDetailsAlerte(),
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
