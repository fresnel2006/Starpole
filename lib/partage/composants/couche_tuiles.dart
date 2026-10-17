import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../noyau/cle_mapbox.dart';

/// Le style de la carte Mapbox : « streets » est coloré et lisible (rues,
/// hôpitaux, hôtels, noms de quartiers). Pour en changer, remplacer par
/// `mapbox/outdoors-v12` (relief), `mapbox/light-v11` (très clair) ou
/// `mapbox/satellite-streets-v12` (satellite).
const String styleCarte = 'mapbox/streets-v12';

/// Les tuiles de la carte, fournies par Mapbox. Toutes les cartes de l'appli
/// (carte des alertes, position d'une alerte, position envoyée dans un
/// message) utilisent cette couche, pour avoir le même aspect partout.
TileLayer tuilesCarte(BuildContext context) {
  return TileLayer(
    urlTemplate:
        'https://api.mapbox.com/styles/v1/$styleCarte/tiles/256/{z}/{x}/{y}{r}'
        '?access_token=$jetonMapbox',
    userAgentPackageName: 'com.example.projet_starpole',
    // Tuiles plus fines sur les écrans à haute densité.
    retinaMode: RetinaMode.isHighDensity(context),
  );
}

/// La mention obligatoire de Mapbox et d'OpenStreetMap, en bas à droite de la
/// carte. [petite] sert pour les cartes miniatures.
Widget mentionCarte({bool petite = false}) {
  return Align(
    alignment: Alignment.bottomRight,
    child: IgnorePointer(
      child: Container(
        color: const Color(0xB3FFFFFF),
        padding: EdgeInsets.symmetric(horizontal: petite ? 2 : 4, vertical: 1),
        child: Text(
          '© Mapbox © OpenStreetMap',
          style: TextStyle(fontSize: petite ? 6.5 : 10, color: Colors.black87),
        ),
      ),
    ),
  );
}
