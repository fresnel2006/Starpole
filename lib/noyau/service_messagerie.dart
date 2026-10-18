import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'messagerie.dart';
import 'normalisation.dart';
import 'serveur_starpole.dart';

/// Erreur de messagerie, avec un message en français prêt à afficher.
class ErreurMessagerie implements Exception {
  const ErreurMessagerie(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Contacts et conversations. Les écrans utilisent cette classe, jamais
/// Firestore directement (ce qui permet de la remplacer dans les tests).
abstract class ServiceMessagerie {
  /// L'identifiant de la personne connectée.
  String? get utilisateurId;

  /// Cherche quelqu'un qui a un compte, par numéro de téléphone ou par e-mail.
  /// Renvoie null s'il n'y a personne.
  Future<Contact?> chercherUtilisateur(String saisie);

  /// Cherche, parmi les numéros donnés (déjà normalisés), ceux qui
  /// appartiennent à des personnes inscrites. Renvoie pour chacun la personne
  /// trouvée. Mon propre compte est ignoré.
  Future<Map<String, Contact>> trouverParTelephones(Iterable<String> numeros);

  /// Ajoute quelqu'un à mes contacts.
  Future<void> ajouterContact(Contact contact);

  /// Mes contacts, par ordre alphabétique, en direct.
  Stream<List<Contact>> contacts();

  /// Mes conversations qui contiennent des messages, la plus récente d'abord.
  Stream<List<Conversation>> conversations();

  /// Ouvre la conversation avec un contact (la crée au besoin) et renvoie son
  /// identifiant.
  Future<String> ouvrirConversation(Contact contact);

  /// Les messages d'une conversation, le plus ancien d'abord, en direct.
  Stream<List<Message>> messages(String conversationId);

  /// Envoie un message. Une [photo] ou une position ([latitude] et
  /// [longitude]) peuvent l'accompagner. Pour répondre à un message précis,
  /// [reponseTexte] est le texte cité et [reponseAuteurId] son auteur.
  Future<void> envoyerMessage(
    String conversationId,
    String texte, {
    Uint8List? photo,
    double? latitude,
    double? longitude,
    String? reponseTexte,
    String? reponseAuteurId,
  });

  /// Modifie le texte d'un de mes messages. [dernier] dit si c'est le dernier
  /// de la conversation (l'aperçu de la liste est alors mis à jour).
  Future<void> modifierMessage(
    String conversationId,
    String messageId,
    String texte, {
    required bool dernier,
  });

  /// Indique que j'ai lu la conversation.
  Future<void> marquerLu(String conversationId);

  /// Dit que je suis connecté en ce moment (à répéter tant que l'appli est
  /// ouverte) : c'est ce qui affiche deux coches chez l'expéditeur.
  Future<void> signalerPresence();

  /// La date à laquelle [autreId] a lu la conversation (null s'il ne l'a
  /// jamais ouverte), en direct.
  Stream<DateTime?> luParAutre(String conversationId, String autreId);

  /// La dernière fois que [autreId] était connecté, en direct.
  Stream<DateTime?> presenceDe(String autreId);

  /// Le nom et la photo d'une personne (gardés en mémoire après la 1re fois).
  Future<Contact?> profilDe(String id);
}

/// Version réelle, basée sur Cloud Firestore.
class ServiceMessagerieFirebase implements ServiceMessagerie {
  final FirebaseFirestore _base = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Map<String, Contact?> _profils = {};

  @override
  String? get utilisateurId => _auth.currentUser?.uid;

  String get _nomUtilisateur {
    final nom = _auth.currentUser?.displayName;
    return (nom == null || nom.trim().isEmpty) ? 'Utilisateur' : nom.trim();
  }

  String _moi() {
    final uid = utilisateurId;
    if (uid == null) {
      throw const ErreurMessagerie(
        'Connectez-vous pour utiliser la messagerie.',
      );
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _mesContacts(String uid) =>
      _base.collection('utilisateurs').doc(uid).collection('contacts');

  Contact _contactDepuis(String id, Map<String, dynamic> d) {
    final photo = d['photo'] as String?;
    return Contact(
      id: id,
      nom: (d['nom'] as String?) ?? '',
      telephone: (d['telephone'] as String?) ?? '',
      photo: (photo == null || photo.isEmpty) ? null : base64Decode(photo),
    );
  }

  @override
  Future<Contact?> chercherUtilisateur(String saisie) async {
    final moi = _moi();
    final texte = saisie.trim();
    final parEmail = ressembleAUnEmail(texte);
    final valeur = parEmail
        ? normaliserEmail(texte)
        : normaliserTelephone(texte);
    if (valeur.length < 8) {
      throw ErreurMessagerie(
        parEmail
            ? 'Adresse e-mail trop courte.'
            : 'Numéro de téléphone trop court.',
      );
    }
    try {
      final resultat = await _base
          .collection('utilisateurs')
          .where(
            parEmail ? 'emailNormalise' : 'telephoneNormalise',
            isEqualTo: valeur,
          )
          .limit(1)
          .get();
      if (resultat.docs.isEmpty) return null;
      final doc = resultat.docs.first;
      if (doc.id == moi) {
        throw const ErreurMessagerie("C'est votre propre compte.");
      }
      return _contactDepuis(doc.id, doc.data());
    } on FirebaseException {
      throw const ErreurMessagerie(
        'Recherche impossible. Vérifiez votre connexion.',
      );
    }
  }

  @override
  Future<Map<String, Contact>> trouverParTelephones(
    Iterable<String> numeros,
  ) async {
    final moi = _moi();
    final liste = numeros.toSet().toList();
    final trouves = <String, Contact>{};
    try {
      // Firestore accepte au plus 30 valeurs par recherche : on envoie les
      // numéros par paquets de 30, tous en même temps.
      final paquets = <List<String>>[
        for (var i = 0; i < liste.length; i += 30)
          liste.sublist(i, i + 30 > liste.length ? liste.length : i + 30),
      ];
      final reponses = await Future.wait(
        paquets.map(
          (paquet) => _base
              .collection('utilisateurs')
              .where('telephoneNormalise', whereIn: paquet)
              .limit(30)
              .get(),
        ),
      );
      for (final reponse in reponses) {
        for (final doc in reponse.docs) {
          if (doc.id == moi) continue;
          final numero = (doc.data()['telephoneNormalise'] as String?) ?? '';
          if (numero.isNotEmpty) {
            trouves[numero] = _contactDepuis(doc.id, doc.data());
          }
        }
      }
    } on FirebaseException {
      throw const ErreurMessagerie(
        'Recherche impossible. Vérifiez votre connexion.',
      );
    }
    return trouves;
  }

  @override
  Future<void> ajouterContact(Contact contact) async {
    final moi = _moi();
    try {
      await _mesContacts(moi).doc(contact.id).set({
        'nom': contact.nom,
        'telephone': contact.telephone,
        'ajouteLe': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      throw const ErreurMessagerie(
        "Impossible d'ajouter le contact. Vérifiez votre connexion.",
      );
    }
  }

  @override
  Stream<List<Contact>> contacts() {
    final uid = utilisateurId;
    if (uid == null) return Stream.value(const []);
    return _mesContacts(uid)
        .orderBy('nom')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((doc) => _contactDepuis(doc.id, doc.data())).toList(),
        );
  }

  @override
  Stream<List<Conversation>> conversations() {
    final uid = utilisateurId;
    if (uid == null) return Stream.value(const []);
    return _base
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((s) {
          final liste =
              s.docs
                  .map(
                    (doc) =>
                        Conversation.depuisDonnees(doc.id, doc.data(), uid),
                  )
                  // Une conversation sans message n'apparaît pas encore.
                  .where((c) => c.dernierMessage.isNotEmpty)
                  .toList()
                ..sort((a, b) => b.dernierTemps.compareTo(a.dernierTemps));
          return liste;
        });
  }

  @override
  Future<String> ouvrirConversation(Contact contact) async {
    final moi = _moi();
    // Même identifiant pour les deux personnes : les deux uid triés.
    final participants = [moi, contact.id]..sort();
    final id = participants.join('_');
    final ref = _base.collection('conversations').doc(id);
    try {
      final existante = await ref.get();
      if (!existante.exists) {
        await ref.set({
          'participants': participants,
          'noms': {moi: _nomUtilisateur, contact.id: contact.nom},
          'creeLe': FieldValue.serverTimestamp(),
          'dernierMessage': '',
          'dernierAuteurId': '',
          'dernierTemps': FieldValue.serverTimestamp(),
          'lu': <String, dynamic>{},
        });
      }
      return id;
    } on FirebaseException {
      throw const ErreurMessagerie(
        'Impossible ouvrir la conversation. Vérifiez votre connexion.',
      );
    }
  }

  @override
  Stream<List<Message>> messages(String conversationId) {
    return _base
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('creeLe')
        .snapshots()
        .map(
          (s) => s.docs
              .map((doc) => Message.depuisDonnees(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> envoyerMessage(
    String conversationId,
    String texte, {
    Uint8List? photo,
    double? latitude,
    double? longitude,
    String? reponseTexte,
    String? reponseAuteurId,
  }) async {
    final moi = _moi();
    final nettoye = texte.trim();
    if (nettoye.isEmpty) return;
    final conversation = _base.collection('conversations').doc(conversationId);
    try {
      // Le message et le « dernier message » de la liste partent ensemble.
      final lot = _base.batch();
      lot.set(conversation.collection('messages').doc(), {
        'texte': nettoye,
        'auteurId': moi,
        'creeLe': FieldValue.serverTimestamp(),
        if (photo != null) 'photo': base64Encode(photo),
        'latitude': ?latitude,
        'longitude': ?longitude,
        if (reponseTexte != null) ...{
          'reponseTexte': _apercu(reponseTexte, 150),
          'reponseAuteurId': reponseAuteurId ?? '',
        },
      });
      lot.update(conversation, {
        'dernierMessage': _apercu(nettoye, 120),
        'dernierAuteurId': moi,
        'dernierTemps': FieldValue.serverTimestamp(),
        'lu.$moi': FieldValue.serverTimestamp(),
      });
      await lot.commit();
    } on FirebaseException {
      throw const ErreurMessagerie(
        "Impossible d'envoyer le message. Vérifiez votre connexion.",
      );
    }
    // Le message est parti : on prévient le serveur, qui envoie la
    // notification à l'autre personne (sans attendre sa réponse).
    unawaited(_prevenirLeServeur(conversationId));
  }

  /// Coupe un texte trop long en ajoutant « ... ».
  String _apercu(String texte, int max) =>
      texte.length > max ? '${texte.substring(0, max)}...' : texte;

  @override
  Future<void> modifierMessage(
    String conversationId,
    String messageId,
    String texte, {
    required bool dernier,
  }) async {
    final nettoye = texte.trim();
    if (nettoye.isEmpty) return;
    final conversation = _base.collection('conversations').doc(conversationId);
    try {
      final lot = _base.batch();
      lot.update(conversation.collection('messages').doc(messageId), {
        'texte': nettoye,
        'modifie': true,
      });
      if (dernier) {
        lot.update(conversation, {'dernierMessage': _apercu(nettoye, 120)});
      }
      await lot.commit();
    } on FirebaseException {
      throw const ErreurMessagerie(
        'Impossible de modifier le message. Vérifiez votre connexion.',
      );
    }
  }

  /// Demande au serveur de notifier l'autre personne. Une erreur ici n'est pas
  /// grave : le message est déjà envoyé et se lira en ouvrant l'appli.
  Future<void> _prevenirLeServeur(String conversationId) async {
    try {
      final jeton = await _auth.currentUser?.getIdToken();
      if (jeton == null) return;
      await ServeurStarPole.envoyer('/notifications/message', {
        'conversationId': conversationId,
      }, jeton: jeton);
    } catch (_) {
      // Notification non envoyée : sans conséquence pour le message.
    }
  }

  @override
  Future<void> marquerLu(String conversationId) async {
    final moi = utilisateurId;
    if (moi == null) return;
    try {
      await _base.collection('conversations').doc(conversationId).update({
        'lu.$moi': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      // Pas grave : ce sera refait à la prochaine ouverture.
    }
  }

  @override
  Future<void> signalerPresence() async {
    final moi = utilisateurId;
    if (moi == null) return;
    try {
      await _base.collection('utilisateurs').doc(moi).update({
        'vuLe': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      // Pas grave : ce sera refait au prochain signal.
    }
  }

  @override
  Stream<DateTime?> luParAutre(String conversationId, String autreId) {
    return _base
        .collection('conversations')
        .doc(conversationId)
        .snapshots()
        .map((doc) {
          final lu = doc.data()?['lu'];
          final date = lu is Map ? lu[autreId] : null;
          return date is Timestamp ? date.toDate() : null;
        });
  }

  @override
  Stream<DateTime?> presenceDe(String autreId) {
    return _base.collection('utilisateurs').doc(autreId).snapshots().map((doc) {
      final date = doc.data()?['vuLe'];
      return date is Timestamp ? date.toDate() : null;
    });
  }

  @override
  Future<Contact?> profilDe(String id) async {
    if (_profils.containsKey(id)) return _profils[id];
    try {
      final doc = await _base.collection('utilisateurs').doc(id).get();
      final donnees = doc.data();
      final profil = donnees == null ? null : _contactDepuis(id, donnees);
      _profils[id] = profil;
      return profil;
    } on FirebaseException {
      return null;
    }
  }
}
