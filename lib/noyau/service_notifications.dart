import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Une notification qui arrive pendant que l'appli est ouverte.
class NotificationRecue {
  const NotificationRecue({
    required this.titre,
    required this.texte,
    required this.type,
    this.conversationId,
    this.expediteurId,
  });

  final String titre;
  final String texte;

  /// « message » (les autres types viendront : appel, alerte).
  final String type;
  final String? conversationId;
  final String? expediteurId;
}

/// L'identifiant de la conversation actuellement affichée à l'écran (null s'il
/// n'y en a pas). Sert à ne pas annoncer un message qu'on est déjà en train de
/// lire.
final ValueNotifier<String?> conversationAffichee = ValueNotifier(null);

/// Les notifications : autoriser, enregistrer le téléphone auprès du serveur et
/// recevoir ce qui arrive. Les écrans utilisent cette classe, jamais Firebase
/// directement (ce qui permet de la remplacer dans les tests).
abstract class ServiceNotifications {
  /// Demande l'autorisation, puis enregistre ce téléphone pour la personne
  /// connectée (son jeton est écrit dans Firestore, où le serveur le lit).
  Future<void> activer();

  /// Retire ce téléphone de la personne connectée : à faire avant de se
  /// déconnecter, pour ne plus recevoir ses notifications.
  Future<void> desactiver();

  /// Les notifications reçues quand l'appli est ouverte.
  Stream<NotificationRecue> get auPremierPlan;

  /// Les notifications sur lesquelles la personne a appuyé (appli en
  /// arrière-plan).
  Stream<NotificationRecue> get ouvertures;

  /// La notification qui a ouvert l'appli alors qu'elle était fermée, s'il y en
  /// a une.
  Future<NotificationRecue?> ouvertureInitiale();
}

/// Version réelle, basée sur Firebase Cloud Messaging.
class ServiceNotificationsFirebase implements ServiceNotifications {
  FirebaseMessaging get _messagerie => FirebaseMessaging.instance;

  StreamSubscription<String>? _abonnementJeton;
  String? _jetonEnregistre;

  NotificationRecue _depuis(RemoteMessage message) {
    final donnees = message.data;
    return NotificationRecue(
      titre: message.notification?.title ?? '',
      texte: message.notification?.body ?? '',
      type: donnees['type'] as String? ?? '',
      conversationId: donnees['conversationId'] as String?,
      expediteurId: donnees['expediteurId'] as String?,
    );
  }

  DocumentReference<Map<String, dynamic>>? _appareil(String jeton) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(uid)
        .collection('appareils')
        .doc(jeton);
  }

  Future<void> _enregistrer(String jeton) async {
    try {
      await _appareil(jeton)?.set({
        'creeLe': FieldValue.serverTimestamp(),
        'plateforme': defaultTargetPlatform.name,
      });
      _jetonEnregistre = jeton;
    } on FirebaseException {
      // Pas de réseau : ce sera refait au prochain démarrage.
    }
  }

  @override
  Future<void> activer() async {
    try {
      // Android 13 et plus : une fenêtre demande l'autorisation d'afficher des
      // notifications.
      await _messagerie.requestPermission();
      final jeton = await _messagerie.getToken();
      if (jeton != null) await _enregistrer(jeton);
      // Le jeton peut changer : on enregistre aussi le nouveau.
      await _abonnementJeton?.cancel();
      _abonnementJeton = _messagerie.onTokenRefresh.listen(_enregistrer);
    } catch (e) {
      debugPrint('Notifications : activation impossible ($e)');
    }
  }

  @override
  Future<void> desactiver() async {
    try {
      await _abonnementJeton?.cancel();
      _abonnementJeton = null;
      final jeton = _jetonEnregistre ?? await _messagerie.getToken();
      if (jeton != null) await _appareil(jeton)?.delete();
      _jetonEnregistre = null;
    } catch (e) {
      debugPrint('Notifications : désactivation impossible ($e)');
    }
  }

  @override
  Stream<NotificationRecue> get auPremierPlan =>
      FirebaseMessaging.onMessage.map(_depuis);

  @override
  Stream<NotificationRecue> get ouvertures =>
      FirebaseMessaging.onMessageOpenedApp.map(_depuis);

  @override
  Future<NotificationRecue?> ouvertureInitiale() async {
    final message = await _messagerie.getInitialMessage();
    return message == null ? null : _depuis(message);
  }
}
