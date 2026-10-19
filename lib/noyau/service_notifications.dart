import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Une notification (reçue ou touchée).
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

/// Les notifications du téléphone : autoriser, enregistrer le téléphone auprès
/// du serveur et recevoir ce qui arrive (barre de notifications, même quand
/// l'appli est ouverte). Les écrans utilisent cette classe, jamais Firebase
/// directement (ce qui permet de la remplacer dans les tests).
abstract class ServiceNotifications {
  /// Demande l'autorisation, puis enregistre ce téléphone pour la personne
  /// connectée (son jeton est écrit dans Firestore, où le serveur le lit).
  Future<void> activer();

  /// Retire ce téléphone de la personne connectée : à faire avant de se
  /// déconnecter, pour ne plus recevoir ses notifications.
  Future<void> desactiver();

  /// Les notifications sur lesquelles la personne a appuyé (appli ouverte ou
  /// en arrière-plan).
  Stream<NotificationRecue> get ouvertures;

  /// La notification qui a ouvert l'appli alors qu'elle était fermée, s'il y en
  /// a une.
  Future<NotificationRecue?> ouvertureInitiale();
}

/// Version réelle, basée sur Firebase Cloud Messaging. Appli fermée ou en
/// arrière-plan, Android affiche lui-même la notification ; appli ouverte, on
/// l'affiche avec `flutter_local_notifications`.
class ServiceNotificationsFirebase implements ServiceNotifications {
  FirebaseMessaging get _messagerie => FirebaseMessaging.instance;

  /// Le canal des messages (importance haute : le téléphone sonne et affiche
  /// la notification en haut de l'écran). Son identifiant est aussi déclaré
  /// dans AndroidManifest.xml pour les notifications reçues appli fermée.
  static const AndroidNotificationChannel _canal = AndroidNotificationChannel(
    'messages',
    'Messages',
    description: 'Nouveaux messages de vos voisins',
    importance: Importance.high,
  );

  static const String _icone = '@drawable/ic_launcher_foreground';

  final FlutterLocalNotificationsPlugin _locales =
      FlutterLocalNotificationsPlugin();
  final StreamController<NotificationRecue> _ouvertures =
      StreamController<NotificationRecue>.broadcast();

  bool _localesPretes = false;
  StreamSubscription<String>? _abonnementJeton;
  StreamSubscription<RemoteMessage>? _abonnementPremierPlan;
  StreamSubscription<RemoteMessage>? _abonnementOuvertures;
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

  /// Prépare les notifications affichées par l'appli et crée le canal.
  Future<void> _preparerLocales() async {
    if (_localesPretes) return;
    await _locales.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_icone),
      ),
      // Toucher une notification affichée par l'appli ouvre la conversation.
      onDidReceiveNotificationResponse: (reponse) {
        final payload = reponse.payload;
        if (payload == null) return;
        try {
          final d = jsonDecode(payload) as Map<String, dynamic>;
          _ouvertures.add(
            NotificationRecue(
              titre: d['titre'] as String? ?? '',
              texte: d['texte'] as String? ?? '',
              type: d['type'] as String? ?? '',
              conversationId: d['conversationId'] as String?,
              expediteurId: d['expediteurId'] as String?,
            ),
          );
        } catch (_) {
          // Contenu illisible : on ignore.
        }
      },
    );
    await _locales
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_canal);
    _localesPretes = true;
  }

  /// Un message arrive pendant que l'appli est ouverte : Android ne montre
  /// rien tout seul, donc on affiche la notification, sauf si on est déjà en
  /// train de lire cette conversation.
  Future<void> _afficher(RemoteMessage message) async {
    final notification = _depuis(message);
    if (notification.type != 'message') return;
    if (notification.conversationId == conversationAffichee.value) return;
    await _locales.show(
      id:
          (notification.conversationId ?? notification.titre).hashCode &
          0x7fffffff,
      title: notification.titre,
      body: notification.texte,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _canal.id,
          _canal.name,
          channelDescription: _canal.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: _icone,
        ),
      ),
      payload: jsonEncode({
        'titre': notification.titre,
        'texte': notification.texte,
        'type': notification.type,
        'conversationId': notification.conversationId,
        'expediteurId': notification.expediteurId,
      }),
    );
  }

  @override
  Future<void> activer() async {
    try {
      // Android 13 et plus : une fenêtre demande l'autorisation d'afficher des
      // notifications.
      await _messagerie.requestPermission();
      await _preparerLocales();
      final jeton = await _messagerie.getToken();
      if (jeton != null) await _enregistrer(jeton);
      // Le jeton peut changer : on enregistre aussi le nouveau.
      await _abonnementJeton?.cancel();
      _abonnementJeton = _messagerie.onTokenRefresh.listen(_enregistrer);
      await _abonnementPremierPlan?.cancel();
      _abonnementPremierPlan = FirebaseMessaging.onMessage.listen(_afficher);
      await _abonnementOuvertures?.cancel();
      _abonnementOuvertures = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _ouvertures.add(_depuis(message)),
      );
    } catch (e) {
      debugPrint('Notifications : activation impossible ($e)');
    }
  }

  @override
  Future<void> desactiver() async {
    try {
      await _abonnementJeton?.cancel();
      _abonnementJeton = null;
      await _abonnementPremierPlan?.cancel();
      _abonnementPremierPlan = null;
      await _abonnementOuvertures?.cancel();
      _abonnementOuvertures = null;
      final jeton = _jetonEnregistre ?? await _messagerie.getToken();
      if (jeton != null) await _appareil(jeton)?.delete();
      _jetonEnregistre = null;
    } catch (e) {
      debugPrint('Notifications : désactivation impossible ($e)');
    }
  }

  @override
  Stream<NotificationRecue> get ouvertures => _ouvertures.stream;

  @override
  Future<NotificationRecue?> ouvertureInitiale() async {
    final message = await _messagerie.getInitialMessage();
    return message == null ? null : _depuis(message);
  }
}
