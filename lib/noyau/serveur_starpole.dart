import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Erreur renvoyée par le serveur StarPole, avec un message en français prêt à
/// afficher.
class ErreurServeur implements Exception {
  const ErreurServeur(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Les demandes au serveur StarPole (FastAPI sur Vercel) : codes de connexion
/// par e-mail et notifications.
class ServeurStarPole {
  const ServeurStarPole._();

  /// L'adresse du serveur. Elle est publique.
  static const String adresse = 'https://starpole-backend.vercel.app';

  /// Envoie [corps] en JSON à [chemin] et renvoie la réponse. Pour les routes
  /// qui demandent d'être connecté, [jeton] est le jeton d'identité Firebase
  /// de la personne. Les erreurs du serveur ont déjà un message en français,
  /// repris tel quel dans une [ErreurServeur].
  static Future<Map<String, dynamic>> envoyer(
    String chemin,
    Map<String, dynamic> corps, {
    String? jeton,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final requete = await client.postUrl(Uri.parse('$adresse$chemin'));
      requete.headers.contentType = ContentType.json;
      if (jeton != null) {
        requete.headers.set(HttpHeaders.authorizationHeader, 'Bearer $jeton');
      }
      requete.write(jsonEncode(corps));
      final reponse = await requete.close().timeout(
        const Duration(seconds: 30),
      );
      final texte = await reponse.transform(utf8.decoder).join();
      Map<String, dynamic> donnees = {};
      try {
        donnees = jsonDecode(texte) as Map<String, dynamic>;
      } catch (_) {
        // Réponse inattendue : on garde un dictionnaire vide.
      }
      if (reponse.statusCode >= 400) {
        throw ErreurServeur(
          (donnees['erreur'] as String?) ??
              'Le serveur a rencontré un problème. Réessayez.',
        );
      }
      return donnees;
    } on SocketException {
      throw const ErreurServeur('Pas de connexion internet.');
    } on TimeoutException {
      throw const ErreurServeur('Le serveur ne répond pas. Réessayez.');
    } on HandshakeException {
      throw const ErreurServeur('Connexion au serveur impossible. Réessayez.');
    } finally {
      client.close();
    }
  }
}
