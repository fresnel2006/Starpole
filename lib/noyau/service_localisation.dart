import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'quartiers.dart';

/// Où se trouve l'utilisateur.
class LieuActuel {
  const LieuActuel({
    required this.ville,
    this.quartier,
    this.latitude,
    this.longitude,
  });

  final String ville;

  /// Le quartier, connu seulement à Abidjan.
  final String? quartier;

  /// La position exacte, ou null si elle n'est pas connue.
  final double? latitude;
  final double? longitude;

  /// Le texte affiché : « Abidjan, Plateau », ou seulement la ville.
  String get libelle => quartier == null ? ville : '$ville, $quartier';
}

/// Ce qui s'est passé quand on a cherché la position.
enum EtatLocalisation {
  ok,

  /// Le GPS (la localisation) du téléphone est éteint.
  serviceDesactive,

  /// L'utilisateur a refusé, mais on peut redemander.
  permissionRefusee,

  /// L'utilisateur a refusé définitivement : il faut passer par les réglages.
  permissionBloquee,

  /// Autre problème (pas de signal, délai dépassé...).
  erreur,
}

class ResultatLocalisation {
  const ResultatLocalisation(this.etat, [this.lieu]);

  final EtatLocalisation etat;
  final LieuActuel? lieu;
}

/// Trouve la position de l'utilisateur. Les écrans utilisent cette classe,
/// jamais `geolocator` directement (pour pouvoir la remplacer dans les tests).
abstract class ServiceLocalisation {
  Future<ResultatLocalisation> localiser();

  /// Ouvre les réglages utiles pour un [etat] donné (GPS ou autorisations).
  Future<void> ouvrirReglages(EtatLocalisation etat);
}

/// Version réelle, basée sur `geolocator` et `geocoding`.
class ServiceLocalisationReel implements ServiceLocalisation {
  @override
  Future<ResultatLocalisation> localiser() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const ResultatLocalisation(EtatLocalisation.serviceDesactive);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const ResultatLocalisation(EtatLocalisation.permissionBloquee);
      }
      if (permission == LocationPermission.denied) {
        return const ResultatLocalisation(EtatLocalisation.permissionRefusee);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final lat = position.latitude;
      final lon = position.longitude;

      // À Abidjan, on connaît la ville et on devine le quartier avec notre
      // propre liste : c'est fiable même sans internet.
      if (Quartiers.estDansAbidjan(lat, lon)) {
        return ResultatLocalisation(
          EtatLocalisation.ok,
          LieuActuel(
            ville: 'Abidjan',
            quartier: Quartiers.plusProche(lat, lon).nom,
            latitude: lat,
            longitude: lon,
          ),
        );
      }

      // Ailleurs, on demande le nom de la ville au service de géocodage.
      final ville = await _nomDeLaVille(lat, lon);
      if (ville == null) {
        return const ResultatLocalisation(EtatLocalisation.erreur);
      }
      return ResultatLocalisation(
        EtatLocalisation.ok,
        LieuActuel(ville: ville, latitude: lat, longitude: lon),
      );
    } catch (e) {
      debugPrint('Localisation : $e');
      return const ResultatLocalisation(EtatLocalisation.erreur);
    }
  }

  /// Le nom de la ville pour des coordonnées, ou null si introuvable.
  Future<String?> _nomDeLaVille(double lat, double lon) async {
    try {
      final lieux = await Geocoding().placemarkFromCoordinates(lat, lon);
      for (final lieu in lieux) {
        for (final nom in [
          lieu.locality,
          lieu.subAdministrativeArea,
          lieu.administrativeArea,
        ]) {
          if (nom != null && nom.trim().isNotEmpty) return nom.trim();
        }
      }
    } catch (e) {
      debugPrint('Géocodage : $e');
    }
    return null;
  }

  @override
  Future<void> ouvrirReglages(EtatLocalisation etat) async {
    if (etat == EtatLocalisation.serviceDesactive) {
      await Geolocator.openLocationSettings();
    } else if (etat == EtatLocalisation.permissionBloquee) {
      await Geolocator.openAppSettings();
    }
  }
}
