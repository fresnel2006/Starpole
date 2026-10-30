import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'alerte.dart';
import 'serveur_starpole.dart';

/// Erreur sur une alerte, avec un message en français prêt à afficher.
class ErreurAlerte implements Exception {
  const ErreurAlerte(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Tout ce que l'appli fait avec les alertes. Les écrans utilisent cette
/// classe, jamais Firestore directement (ce qui permet de la remplacer dans
/// les tests).
abstract class ServiceAlertes {
  /// L'identifiant de la personne connectée.
  String? get utilisateurId;

  /// Les alertes récentes de tout le monde, en direct (la plus récente d'abord).
  Stream<List<Alerte>> alertes();

  /// Les alertes que j'ai publiées ou que j'ai acceptées d'aider.
  Stream<List<Alerte>> mesAlertes();

  /// L'alerte que j'aide en ce moment, ou null s'il n'y en a pas.
  Stream<Alerte?> alerteEnCours();

  /// Une alerte précise, en direct (null si elle n'existe plus).
  Stream<Alerte?> alerte(String id);

  Future<void> publier({
    required TypeAlerte type,
    required String categorie,
    required String description,
    required String ville,
    String? quartier,
    double? latitude,
    double? longitude,
    Uint8List? photo,
  });

  /// J'accepte d'aider cette alerte.
  Future<void> accepter(String id);

  /// L'alerte est résolue (par son auteur ou par la personne qui aide).
  Future<void> terminer(String id);

  /// Je n'aide plus : l'alerte redevient disponible pour d'autres.
  Future<void> arreter(String id);

  /// Les messages d'avancement d'une alerte, en direct (le plus ancien d'abord).
  Stream<List<MiseAJour>> progression(String alerteId);

  /// J'écris un message d'avancement sur une alerte (auteur ou aidant).
  Future<void> envoyerProgression(String alerteId, String texte);

  Future<StatistiquesProfil> statistiques();

  /// Enregistre la note donnée à quelqu'un après une alerte.
  Future<void> noter({
    required String alerteId,
    required String pourId,
    required int etoiles,
    String commentaire = '',
    List<String> etiquettes = const [],
  });
}

/// Version réelle, basée sur Cloud Firestore.
class ServiceAlertesFirebase implements ServiceAlertes {
  final FirebaseFirestore _base = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _alertes =>
      _base.collection('alertes');

  @override
  String? get utilisateurId => _auth.currentUser?.uid;

  String get _nomUtilisateur {
    final nom = _auth.currentUser?.displayName;
    return (nom == null || nom.trim().isEmpty) ? 'Utilisateur' : nom.trim();
  }

  List<Alerte> _liste(QuerySnapshot<Map<String, dynamic>> instantane) {
    return instantane.docs
        .map((doc) => Alerte.depuisDonnees(doc.id, doc.data()))
        .toList();
  }

  @override
  Stream<List<Alerte>> alertes() {
    return _alertes
        .orderBy('creeLe', descending: true)
        .limit(50)
        .snapshots()
        .map(_liste);
  }

  @override
  Stream<List<Alerte>> mesAlertes() {
    final uid = utilisateurId;
    if (uid == null) return Stream.value(const []);
    final publiees = _alertes
        .where('auteurId', isEqualTo: uid)
        .snapshots()
        .map(_liste);
    final aidees = _alertes
        .where('aidantId', isEqualTo: uid)
        .snapshots()
        .map(_liste);
    return _fusionner(publiees, aidees);
  }

  /// Réunit deux listes d'alertes en une seule, sans doublon, la plus récente
  /// d'abord.
  Stream<List<Alerte>> _fusionner(
    Stream<List<Alerte>> a,
    Stream<List<Alerte>> b,
  ) {
    late final StreamController<List<Alerte>> controleur;
    var listeA = <Alerte>[];
    var listeB = <Alerte>[];
    StreamSubscription<List<Alerte>>? abonnementA;
    StreamSubscription<List<Alerte>>? abonnementB;

    void emettre() {
      final parId = {
        for (final alerte in [...listeA, ...listeB]) alerte.id: alerte,
      };
      final tout = parId.values.toList()
        ..sort((x, y) => y.creeLe.compareTo(x.creeLe));
      controleur.add(tout);
    }

    controleur = StreamController<List<Alerte>>(
      onListen: () {
        abonnementA = a.listen((v) {
          listeA = v;
          emettre();
        }, onError: controleur.addError);
        abonnementB = b.listen((v) {
          listeB = v;
          emettre();
        }, onError: controleur.addError);
      },
      onCancel: () async {
        await abonnementA?.cancel();
        await abonnementB?.cancel();
      },
    );
    return controleur.stream;
  }

  @override
  Stream<Alerte?> alerteEnCours() {
    final uid = utilisateurId;
    if (uid == null) return Stream.value(null);
    return _alertes
        .where('aidantId', isEqualTo: uid)
        .where('statut', isEqualTo: StatutAlerte.enCours.code)
        .limit(1)
        .snapshots()
        .map((s) {
          final liste = _liste(s);
          return liste.isEmpty ? null : liste.first;
        });
  }

  @override
  Stream<Alerte?> alerte(String id) {
    return _alertes.doc(id).snapshots().map((doc) {
      final donnees = doc.data();
      return donnees == null ? null : Alerte.depuisDonnees(doc.id, donnees);
    });
  }

  @override
  Future<void> publier({
    required TypeAlerte type,
    required String categorie,
    required String description,
    required String ville,
    String? quartier,
    double? latitude,
    double? longitude,
    Uint8List? photo,
  }) async {
    final uid = utilisateurId;
    if (uid == null) {
      throw const ErreurAlerte('Connectez-vous pour publier une alerte.');
    }
    final DocumentReference<Map<String, dynamic>> ref;
    try {
      ref = await _alertes.add({
        'type': type.code,
        'categorie': categorie,
        'description': description.trim(),
        'ville': ville,
        'quartier': quartier,
        'latitude': latitude,
        'longitude': longitude,
        'auteurId': uid,
        'auteurNom': _nomUtilisateur,
        'statut': StatutAlerte.enCours.code,
        'creeLe': FieldValue.serverTimestamp(),
        'aidantId': null,
        'aidantNom': null,
        'accepteLe': null,
        'termineLe': null,
        'photo': photo == null ? null : base64Encode(photo),
      });
    } on FirebaseException {
      throw const ErreurAlerte(
        "Impossible de publier l'alerte. Vérifiez votre connexion.",
      );
    }
    // L'alerte est en ligne tout de suite. En arrière-plan, le serveur la
    // fait vérifier par l'IA : si elle n'est pas conforme, il la supprime et
    // prévient l'auteur.
    unawaited(_faireVerifier(ref.id));
  }

  /// Demande au serveur de vérifier l'alerte. Une erreur ici n'empêche rien :
  /// l'alerte reste publiée.
  Future<void> _faireVerifier(String alerteId) async {
    try {
      final jeton = await _auth.currentUser?.getIdToken();
      if (jeton == null) return;
      await ServeurStarPole.envoyer('/moderation/alerte', {
        'alerteId': alerteId,
      }, jeton: jeton);
    } catch (_) {
      // Vérification non faite : sans conséquence pour la publication.
    }
  }

  @override
  Future<void> accepter(String id) async {
    final uid = utilisateurId;
    if (uid == null) {
      throw const ErreurAlerte('Connectez-vous pour aider.');
    }
    try {
      await _alertes.doc(id).update({
        'aidantId': uid,
        'aidantNom': _nomUtilisateur,
        'accepteLe': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      // Les règles refusent si quelqu'un d'autre a déjà accepté entre-temps.
      if (e.code == 'permission-denied') {
        throw const ErreurAlerte(
          'Cette alerte est déjà prise en charge par quelqu\'un d\'autre.',
        );
      }
      throw const ErreurAlerte(
        'Impossible d\'accepter l\'alerte. Vérifiez votre connexion.',
      );
    }
  }

  @override
  Future<void> terminer(String id) async {
    try {
      await _alertes.doc(id).update({
        'statut': StatutAlerte.resolue.code,
        'termineLe': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      throw const ErreurAlerte(
        "Impossible de terminer l'alerte. Vérifiez votre connexion.",
      );
    }
  }

  @override
  Future<void> arreter(String id) async {
    try {
      await _alertes.doc(id).update({
        'aidantId': null,
        'aidantNom': null,
        'accepteLe': null,
      });
    } on FirebaseException {
      throw const ErreurAlerte(
        'Impossible d\'arrêter. Vérifiez votre connexion.',
      );
    }
  }

  @override
  Stream<List<MiseAJour>> progression(String alerteId) {
    return _alertes
        .doc(alerteId)
        .collection('progression')
        .orderBy('creeLe')
        .snapshots()
        .map(
          (s) => s.docs
              .map((doc) => MiseAJour.depuisDonnees(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> envoyerProgression(String alerteId, String texte) async {
    final uid = utilisateurId;
    if (uid == null) {
      throw const ErreurAlerte('Connectez-vous pour écrire un message.');
    }
    try {
      await _alertes.doc(alerteId).collection('progression').add({
        'texte': texte.trim(),
        'auteurId': uid,
        'auteurNom': _nomUtilisateur,
        'creeLe': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      throw const ErreurAlerte(
        "Impossible d'envoyer le message. Vérifiez votre connexion.",
      );
    }
  }

  @override
  Future<StatistiquesProfil> statistiques() async {
    final uid = utilisateurId;
    if (uid == null) return const StatistiquesProfil();

    // Chaque chiffre est cherché séparément : si l'un échoue, les autres
    // restent affichés.
    Future<int> compter(Query<Map<String, dynamic>> requete) async {
      try {
        return (await requete.count().get()).count ?? 0;
      } on FirebaseException {
        return 0;
      }
    }

    final publiees = await compter(_alertes.where('auteurId', isEqualTo: uid));
    final aidees = await compter(_alertes.where('aidantId', isEqualTo: uid));
    final dons = await compter(
      _alertes
          .where('auteurId', isEqualTo: uid)
          .where('type', isEqualTo: TypeAlerte.don.code)
          .where('statut', isEqualTo: StatutAlerte.resolue.code),
    );

    double? note;
    var nombreAvis = 0;
    try {
      final avis = await _base
          .collection('avis')
          .where('pourId', isEqualTo: uid)
          .aggregate(average('etoiles'), count())
          .get();
      note = avis.getAverage('etoiles');
      nombreAvis = avis.count ?? 0;
    } on FirebaseException {
      // Pas de note affichée si elle est introuvable.
    }

    return StatistiquesProfil(
      alertesPubliees: publiees,
      aidesApportees: aidees,
      donsEffectues: dons,
      noteMoyenne: note,
      nombreAvis: nombreAvis,
    );
  }

  @override
  Future<void> noter({
    required String alerteId,
    required String pourId,
    required int etoiles,
    String commentaire = '',
    List<String> etiquettes = const [],
  }) async {
    final uid = utilisateurId;
    if (uid == null) {
      throw const ErreurAlerte('Connectez-vous pour noter.');
    }
    try {
      await _base.collection('avis').add({
        'alerteId': alerteId,
        'deId': uid,
        'pourId': pourId,
        'etoiles': etoiles,
        'commentaire': commentaire.trim(),
        'etiquettes': etiquettes,
        'creeLe': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      throw const ErreurAlerte(
        'Impossible d\'envoyer la note. Vérifiez votre connexion.',
      );
    }
  }
}
