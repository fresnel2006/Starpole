import 'package:flutter_test/flutter_test.dart';

import 'package:projet_starpole/noyau/quartiers.dart';

void main() {
  test('Chaque quartier est reconnu à son propre point central', () {
    for (final quartier in Quartiers.abidjan) {
      final trouve = Quartiers.plusProche(
        quartier.latitude,
        quartier.longitude,
      );
      expect(trouve.nom, quartier.nom);
    }
  });

  test('Une position proche de Treichville donne Treichville', () {
    // Un peu à côté du point central de Treichville.
    expect(Quartiers.plusProche(5.2985, -4.0050).nom, 'Treichville');
  });

  test('Abidjan est reconnue, pas les autres villes', () {
    expect(Quartiers.estDansAbidjan(5.3197, -4.0167), isTrue); // Plateau
    expect(Quartiers.estDansAbidjan(5.4200, -4.0200), isTrue); // Abobo
    expect(Quartiers.estDansAbidjan(7.6900, -5.0300), isFalse); // Bouaké
    expect(Quartiers.estDansAbidjan(48.85, 2.35), isFalse); // Paris
  });

  test('La distance est correcte (Plateau - Treichville, environ 3 km)', () {
    final d = Quartiers.distanceKm(5.3197, -4.0167, 5.2950, -4.0090);
    expect(d, inInclusiveRange(2.5, 3.5));
  });
}
