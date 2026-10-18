import 'package:flutter/services.dart';

/// La tonalité que l'appelant entend pendant que ça sonne chez l'autre
/// personne (« tuuut... tuuut... »). Elle est produite par le téléphone
/// lui-même (code Android dans `MainActivity.kt`) : aucun fichier son.
class SonnerieAppel {
  const SonnerieAppel._();

  static const MethodChannel _canal = MethodChannel('starpole/sonnerie');

  /// Lance la tonalité. [hautParleur] : sur le haut-parleur (appel vidéo) ou
  /// dans l'écouteur (appel vocal).
  static Future<void> demarrer({required bool hautParleur}) async {
    try {
      await _canal.invokeMethod<void>('demarrer', {'hautParleur': hautParleur});
    } catch (_) {
      // Pas de son possible (par exemple dans un test) : l'appel continue.
    }
  }

  /// Coupe la tonalité.
  static Future<void> arreter() async {
    try {
      await _canal.invokeMethod<void>('arreter');
    } catch (_) {
      // Rien à couper.
    }
  }
}
