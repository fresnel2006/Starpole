import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// La forme dans laquelle une photo est enregistrée.
enum FormePhoto {
  /// Un carré (photo de profil, affichée dans un cercle).
  carre(1, 400),

  /// Un rectangle deux fois plus large que haut (photo d'une alerte).
  paysage(2, 640),

  /// La photo en entier, sans la couper (photo d'une alerte, que les détails
  /// montrent complète). Le ratio n'est pas utilisé ; [largeurMax] est le plus
  /// grand côté, en pixels.
  entiere(0, 900);

  const FormePhoto(this.ratio, this.largeurMax);

  /// Largeur divisée par hauteur (0 pour une photo gardée entière).
  final double ratio;

  /// Largeur maximale en pixels : au-delà, la photo est réduite.
  final int largeurMax;
}

/// Prépare une photo à enregistrer : corrige son orientation, la coupe autour
/// de son centre à la [forme] voulue, la réduit, puis l'enregistre en JPEG.
///
/// Si l'image ne peut pas être lue ou est minuscule, on la rend telle quelle.
/// Le travail se fait à part pour ne pas bloquer l'écran.
Future<Uint8List> preparerPhoto(Uint8List source, FormePhoto forme) {
  return compute(_preparer, (source, forme));
}

Uint8List _preparer((Uint8List, FormePhoto) parametres) {
  final (source, forme) = parametres;

  final lue = img.decodeImage(source);
  if (lue == null) return source;

  // Beaucoup de téléphones enregistrent la photo « couchée » avec une
  // indication de rotation : on la remet droite avant de couper.
  final droite = img.bakeOrientation(lue);

  if (forme == FormePhoto.entiere) return _garderEntiere(droite, forme);

  // Le plus grand rectangle de la bonne forme qui tient dans la photo.
  final largeur = droite.width;
  final hauteur = droite.height;
  final int largeurCoupe;
  final int hauteurCoupe;
  if (largeur / hauteur > forme.ratio) {
    hauteurCoupe = hauteur;
    largeurCoupe = (hauteur * forme.ratio).round();
  } else {
    largeurCoupe = largeur;
    hauteurCoupe = (largeur / forme.ratio).round();
  }
  if (largeurCoupe < 2 || hauteurCoupe < 2) return source;

  // On le centre dans la photo, au pixel près.
  final x = (largeur - largeurCoupe) ~/ 2;
  final y = (hauteur - hauteurCoupe) ~/ 2;
  var resultat = img.copyCrop(
    droite,
    x: x,
    y: y,
    width: largeurCoupe,
    height: hauteurCoupe,
  );

  if (resultat.width > forme.largeurMax) {
    resultat = img.copyResize(
      resultat,
      width: forme.largeurMax,
      interpolation: img.Interpolation.average,
    );
  }
  return Uint8List.fromList(img.encodeJpg(resultat, quality: 80));
}

/// Réduit la photo (son plus grand côté ne dépasse pas [FormePhoto.largeurMax])
/// sans la couper, puis l'enregistre en JPEG. La qualité baisse si besoin pour
/// que la photo reste assez légère pour la base de données.
Uint8List _garderEntiere(img.Image photo, FormePhoto forme) {
  var resultat = photo;
  final grand = photo.width > photo.height ? photo.width : photo.height;
  if (grand > forme.largeurMax) {
    resultat = photo.width >= photo.height
        ? img.copyResize(
            photo,
            width: forme.largeurMax,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            photo,
            height: forme.largeurMax,
            interpolation: img.Interpolation.average,
          );
  }
  // Environ 200 Ko au plus (la base refuse un texte de plus de 300 000
  // caractères une fois la photo encodée).
  var octets = Uint8List.fromList(img.encodeJpg(resultat, quality: 80));
  for (
    var qualite = 70;
    octets.length > 200000 && qualite >= 40;
    qualite -= 10
  ) {
    octets = Uint8List.fromList(img.encodeJpg(resultat, quality: qualite));
  }
  return octets;
}
