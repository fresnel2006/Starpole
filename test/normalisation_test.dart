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

  group('IdentifiantCompte', () {
    test('un e-mail est reconnu et mis en minuscules', () {
      final id = IdentifiantCompte.depuis('  Fresnel@Exemple.CI ')!;
      expect(id.email, 'fresnel@exemple.ci');
      expect(id.telephone, isEmpty);
      expect(id.emailInterne, 'fresnel@exemple.ci');
    });

    test(
      'un numéro devient une adresse interne, quelle que soit son écriture',
      () {
        final a = IdentifiantCompte.depuis('07 07 07 07 07')!;
        final b = IdentifiantCompte.depuis('+225 0707070707')!;
        expect(a.email, isEmpty);
        expect(a.telephone, '07 07 07 07 07');
        expect(a.emailInterne, '0707070707@telephone.starpole.app');
        expect(b.emailInterne, a.emailInterne);
        expect(b.motDePasse, a.motDePasse);
        expect(a.motDePasse.length, greaterThanOrEqualTo(6));
      },
    );

    test('ce qui ne ressemble à rien est refusé', () {
      expect(IdentifiantCompte.depuis(''), isNull);
      expect(IdentifiantCompte.depuis('abc'), isNull);
      expect(IdentifiantCompte.depuis('12345'), isNull);
      expect(IdentifiantCompte.depuis('a@b'), isNull);
    });
  });
}
