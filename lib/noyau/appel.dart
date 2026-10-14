/// Où en est un appel.
enum EtatAppel {
  /// Ça sonne chez l'autre personne.
  sonne,

  /// L'appel est accepté, la liaison s'établit.
  connexion,

  /// On s'entend (et on se voit, en vidéo).
  enCours,

  termine,
  refuse,

  /// Personne n'a répondu.
  manque,

  /// La liaison n'a pas pu s'établir.
  echec;

  /// Vrai quand l'appel est fini, quelle qu'en soit la raison.
  bool get estFini => switch (this) {
    termine || refuse || manque || echec => true,
    _ => false,
  };
}

/// Un appel qu'on est en train de recevoir.
class AppelEntrant {
  const AppelEntrant({
    required this.id,
    required this.appelantId,
    required this.appelantNom,
    required this.video,
  });

  final String id;
  final String appelantId;
  final String appelantNom;
  final bool video;
}

/// Erreur d'appel, avec un message en français prêt à afficher.
class ErreurAppel implements Exception {
  const ErreurAppel(this.message);

  final String message;

  @override
  String toString() => message;
}
