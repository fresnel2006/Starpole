import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:projet_starpole/noyau/traitement_photo.dart';

/// Une photo verticale (300 x 500) : fond blanc, un carré rouge exactement au
/// centre, une bande bleue en haut et une bande verte en bas.
Uint8List photoVerticale() {
  final photo = img.Image(width: 300, height: 500);
  img.fill(photo, color: img.ColorRgb8(255, 255, 255));
  img.fillRect(
    photo,
    x1: 0,
    y1: 0,
    x2: 299,
    y2: 60,
    color: img.ColorRgb8(0, 0, 255),
  );
  img.fillRect(
    photo,
    x1: 0,
    y1: 440,
    x2: 299,
    y2: 499,
    color: img.ColorRgb8(0, 160, 0),
  );
  img.fillRect(
    photo,
    x1: 120,
    y1: 220,
    x2: 180,
    y2: 280,
    color: img.ColorRgb8(255, 0, 0),
  );
  return Uint8List.fromList(img.encodePng(photo));
}

bool estRouge(img.Pixel p) => p.r > 200 && p.g < 90 && p.b < 90;

void main() {
  test('Paysage : coupe en 2 pour 1 et garde le centre au centre', () async {
    final resultat = img.decodeJpg(
      await preparerPhoto(photoVerticale(), FormePhoto.paysage),
    )!;

    // 300 x 500 devient 300 x 150 : le plus grand 2 pour 1 qui tient.
    expect(resultat.width, 300);
    expect(resultat.height, 150);

    // Le carré rouge, qui était au centre de la photo, est au centre.
    expect(estRouge(resultat.getPixel(150, 75)), isTrue);
    // Les bandes du haut et du bas ont été coupées.
    for (var y = 0; y < resultat.height; y += 10) {
      final p = resultat.getPixel(10, y);
      expect(p.b > 200 && p.r < 90, isFalse, reason: 'bande bleue à $y');
      expect(p.g > 120 && p.r < 90, isFalse, reason: 'bande verte à $y');
    }
  });

  test('Entière : rien n est coupé, la forme est gardée', () async {
    final resultat = img.decodeJpg(
      await preparerPhoto(photoVerticale(), FormePhoto.entiere),
    )!;

    // 300 x 500 reste 300 x 500 : les bandes du haut et du bas sont là.
    expect(resultat.width, 300);
    expect(resultat.height, 500);
    final haut = resultat.getPixel(10, 10);
    expect(haut.b > 200 && haut.r < 90, isTrue);
    expect(estRouge(resultat.getPixel(150, 250)), isTrue);
  });

  test(
    'Entière : une grande photo est réduite sans changer de forme',
    () async {
      final grande = img.Image(width: 3000, height: 2000);
      img.fill(grande, color: img.ColorRgb8(200, 200, 200));
      final resultat = img.decodeJpg(
        await preparerPhoto(
          Uint8List.fromList(img.encodePng(grande)),
          FormePhoto.entiere,
        ),
      )!;

      expect(resultat.width, FormePhoto.entiere.largeurMax);
      expect(resultat.height, FormePhoto.entiere.largeurMax * 2 ~/ 3);
    },
  );

  test('Carré : coupe en carré et garde le centre au centre', () async {
    final resultat = img.decodeJpg(
      await preparerPhoto(photoVerticale(), FormePhoto.carre),
    )!;

    expect(resultat.width, 300);
    expect(resultat.height, 300);
    expect(estRouge(resultat.getPixel(150, 150)), isTrue);
  });

  test('Une grande photo est réduite à la largeur maximale', () async {
    final grande = img.Image(width: 2000, height: 1000);
    img.fill(grande, color: img.ColorRgb8(200, 200, 200));
    final resultat = img.decodeJpg(
      await preparerPhoto(
        Uint8List.fromList(img.encodePng(grande)),
        FormePhoto.paysage,
      ),
    )!;

    expect(resultat.width, FormePhoto.paysage.largeurMax);
    expect(resultat.height, FormePhoto.paysage.largeurMax ~/ 2);
  });

  test('Une photo enregistrée reste légère', () async {
    final resultat = await preparerPhoto(photoVerticale(), FormePhoto.paysage);
    // La base accepte au plus 300 000 caractères en base64, soit 225 000 octets.
    expect(resultat.length, lessThan(100000));
  });

  test("Un fichier qui n'est pas une image est rendu tel quel", () async {
    final texte = Uint8List.fromList([1, 2, 3, 4, 5]);
    expect(await preparerPhoto(texte, FormePhoto.carre), texte);
  });
}
