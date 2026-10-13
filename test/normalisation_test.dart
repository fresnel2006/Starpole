import 'package:flutter_test/flutter_test.dart';

import 'package:projet_starpole/noyau/normalisation.dart';

void main() {
  group('Numéro de téléphone', () {
    test('Toutes les écritures donnent le même résultat', () {
      const attendu = '0707070707';
      expect(normaliserTelephone('0707070707'), attendu);
      expect(normaliserTelephone('07 07 07 07 07'), attendu);
      expect(normaliserTelephone('+225 07 07 07 07 07'), attendu);
      expect(normaliserTelephone('00225-07-07-07-07-07'), attendu);
      expect(normaliserTelephone('(+225) 0707070707'), attendu);
    });

    test('Un numéro trop court est gardé tel quel (chiffres seulement)', () {
      expect(normaliserTelephone('07 07'), '0707');
    });

    test('Des lettres sont ignorées', () {
      expect(normaliserTelephone('tel: 07 07 07 07 07'), '0707070707');
    });
  });

  group('E-mail', () {
    test('Majuscules et espaces ne comptent pas', () {
      expect(normaliserEmail('  Kouassi@Exemple.CI '), 'kouassi@exemple.ci');
    });

    test('Reconnaît ce qui ressemble à un e-mail', () {
      expect(ressembleAUnEmail('a@b.ci'), isTrue);
      expect(ressembleAUnEmail('0707070707'), isFalse);
    });
  });
}
