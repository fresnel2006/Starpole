import 'dart:math' as math;

/// Un quartier (commune) d'Abidjan avec un point central.
class Quartier {
  const Quartier(this.nom, this.latitude, this.longitude);

  final String nom;
  final double latitude;
  final double longitude;
}

/// Les quartiers d'Abidjan et le calcul du plus proche d'une position.
///
/// Les points centraux sont approximatifs : ils servent à deviner le quartier,
/// pas à tracer des frontières exactes.
abstract final class Quartiers {
  static const List<Quartier> abidjan = [
    Quartier('Plateau', 5.3197, -4.0167),
    Quartier('Treichville', 5.2950, -4.0090),
    Quartier('Marcory', 5.3030, -3.9850),
    Quartier('Koumassi', 5.2950, -3.9500),
    Quartier('Cocody', 5.3550, -3.9850),
    Quartier('Yopougon', 5.3400, -4.0900),
    Quartier('Adjamé', 5.3600, -4.0230),
    Quartier('Abobo', 5.4200, -4.0200),
  ];

  /// Au-delà de cette distance du Plateau, on n'est plus à Abidjan.
  static const double rayonAbidjanKm = 30;

  /// Distance en kilomètres entre deux points (formule de haversine).
  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const rayonTerreKm = 6371.0;
    double rad(double degres) => degres * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * rayonTerreKm * math.asin(math.sqrt(a));
  }

  /// Vrai si la position est dans la zone d'Abidjan.
  static bool estDansAbidjan(double latitude, double longitude) {
    final plateau = abidjan.first;
    return distanceKm(
          latitude,
          longitude,
          plateau.latitude,
          plateau.longitude,
        ) <=
        rayonAbidjanKm;
  }

  /// Le quartier d'Abidjan le plus proche de la position.
  static Quartier plusProche(double latitude, double longitude) {
    Quartier meilleur = abidjan.first;
    var distanceMin = double.infinity;
    for (final quartier in abidjan) {
      final d = distanceKm(
        latitude,
        longitude,
        quartier.latitude,
        quartier.longitude,
      );
      if (d < distanceMin) {
        distanceMin = d;
        meilleur = quartier;
      }
    }
    return meilleur;
  }
}
