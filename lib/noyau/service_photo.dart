import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'traitement_photo.dart';

export 'traitement_photo.dart' show FormePhoto;

/// Erreur lors du choix d'une photo, avec un message en français.
class ErreurPhoto implements Exception {
  const ErreurPhoto(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Permet de choisir une photo. Les écrans utilisent cette classe et non
/// `image_picker` directement, ce qui permet de la remplacer dans les tests.
abstract class ServicePhoto {
  /// Ouvre le sélecteur de photos du téléphone. Il ne demande aucune
  /// autorisation et propose aussi l'appareil photo quand le téléphone le
  /// permet. Renvoie la photo choisie, déjà coupée autour de son centre à la
  /// [forme] voulue et réduite, ou null si l'utilisateur annule.
  Future<Uint8List?> choisir({FormePhoto forme = FormePhoto.carre});
}

/// Version réelle, basée sur `image_picker`.
class ServicePhotoReel implements ServicePhoto {
  final ImagePicker _selecteur = ImagePicker();

  @override
  Future<Uint8List?> choisir({FormePhoto forme = FormePhoto.carre}) async {
    try {
      // On demande une photo assez grande pour bien la recadrer ensuite
      // (1200 pixels, qualité 85). Elle est ensuite coupée et réduite à la
      // taille finale : elle reste légère, car elle est enregistrée dans la
      // base de données.
      final fichier = await _selecteur.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (fichier == null) return null;
      final octets = await fichier.readAsBytes();
      return await preparerPhoto(octets, forme);
    } on PlatformException {
      throw const ErreurPhoto("Impossible d'ouvrir la photo. Réessayez.");
    }
  }
}
