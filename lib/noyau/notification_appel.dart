import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Les appels entrants en notification, comme WhatsApp : quand l'appli est
/// fermée ou en arrière-plan, le téléphone sonne (sonnerie en boucle) et
/// affiche le nom de l'appelant avec « Répondre » et « Refuser ».

/// Une seule notification d'appel à la fois.
const int idNotificationAppel = 7001;

const String _icone = '@drawable/ic_launcher_foreground';

/// L'appel sur lequel on a touché « Répondre » dans la notification : l'écran
/// d'appel entrant décroche tout seul quand il le voit.
final ValueNotifier<String?> appelARepondre = ValueNotifier(null);

/// Le canal des appels : importance maximale, sonnerie du téléphone.
const AndroidNotificationChannel canalAppels = AndroidNotificationChannel(
  'appels',
  'Appels',
  description: 'Appels vocaux et vidéo entrants',
  importance: Importance.max,
  sound: UriAndroidNotificationSound('content://settings/system/ringtone'),
  audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
);

/// Réglages communs pour initialiser les notifications de l'appli.
const InitializationSettings reglagesNotifications = InitializationSettings(
  android: AndroidInitializationSettings(_icone),
);

/// Ce qu'une notification d'appel transporte (identifiant, appelant...).
class DonneesAppel {
  const DonneesAppel({
    required this.appelId,
    required this.appelantNom,
    required this.video,
  });

  final String appelId;
  final String appelantNom;
  final bool video;

  /// Lit les données envoyées par le serveur, ou null si ce n'est pas un appel.
  static DonneesAppel? depuis(Map<String, dynamic> d) {
    if (d['type'] != 'appel') return null;
    final id = d['appelId'];
    if (id is! String || id.isEmpty) return null;
    return DonneesAppel(
      appelId: id,
      appelantNom: (d['appelantNom'] as String?)?.trim().isNotEmpty == true
          ? (d['appelantNom'] as String).trim()
          : 'Quelqu\'un',
      video: d['video'] == 'true' || d['video'] == true,
    );
  }

  /// Lit le contenu (payload) d'une notification touchée.
  static DonneesAppel? depuisContenu(String? contenu) {
    if (contenu == null) return null;
    try {
      return depuis(jsonDecode(contenu) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  String get contenu => jsonEncode({
    'type': 'appel',
    'appelId': appelId,
    'appelantNom': appelantNom,
    'video': video ? 'true' : 'false',
  });
}

/// Affiche la notification d'appel : plein écran si le téléphone le permet,
/// sonnerie répétée jusqu'à la réponse, et disparition après 45 secondes.
Future<void> afficherNotificationAppel(
  FlutterLocalNotificationsPlugin plugin,
  DonneesAppel appel,
) async {
  await plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(canalAppels);
  await plugin.show(
    id: idNotificationAppel,
    title: appel.appelantNom,
    body: appel.video ? 'Appel vidéo StarPole' : 'Appel vocal StarPole',
    payload: appel.contenu,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        canalAppels.id,
        canalAppels.name,
        channelDescription: canalAppels.description,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.call,
        fullScreenIntent: true,
        ongoing: true,
        autoCancel: false,
        timeoutAfter: 45000,
        visibility: NotificationVisibility.public,
        icon: _icone,
        sound: canalAppels.sound,
        audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
        // FLAG_INSISTENT (4) : la sonnerie se répète jusqu'à la réponse.
        additionalFlags: Int32List.fromList(<int>[4]),
        actions: const [
          AndroidNotificationAction(
            'refuser',
            'Refuser',
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'repondre',
            'Répondre',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
    ),
  );
}

/// Retire la notification d'appel (l'appli est ouverte, ou l'appel est fini).
Future<void> retirerNotificationAppel() async {
  try {
    await FlutterLocalNotificationsPlugin().cancel(id: idNotificationAppel);
  } catch (_) {
    // Rien à retirer (ou pas de notifications, par exemple dans un test).
  }
}

/// Refuse l'appel directement dans Firestore (bouton « Refuser » de la
/// notification, sans ouvrir l'appli).
Future<void> refuserAppelDepuisNotification(String appelId) async {
  try {
    // En arrière-plan, la session met un instant à être relue.
    final utilisateur =
        FirebaseAuth.instance.currentUser ??
        await FirebaseAuth.instance.authStateChanges().first;
    if (utilisateur == null) return;
    await FirebaseFirestore.instance.collection('appels').doc(appelId).update({
      'statut': 'refuse',
    });
  } catch (e) {
    debugPrint('Refus de l\'appel impossible ($e)');
  }
}

/// Réponse à une notification quand l'appli n'est pas au premier plan (bouton
/// « Refuser »). Fonction de premier niveau : Android l'appelle à part.
@pragma('vm:entry-point')
Future<void> reponseNotificationArrierePlan(
  NotificationResponse reponse,
) async {
  final appel = DonneesAppel.depuisContenu(reponse.payload);
  if (appel == null || reponse.actionId != 'refuser') return;
  await Firebase.initializeApp();
  await refuserAppelDepuisNotification(appel.appelId);
}

/// Message reçu du serveur quand l'appli est fermée ou en arrière-plan : pour
/// un appel, on affiche la notification qui sonne. (Les messages, eux, ont
/// une notification affichée par Android.)
@pragma('vm:entry-point')
Future<void> gestionnaireMessageArrierePlan(RemoteMessage message) async {
  final appel = DonneesAppel.depuis(message.data);
  if (appel == null) return;
  await Firebase.initializeApp();
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: reglagesNotifications,
    onDidReceiveBackgroundNotificationResponse: reponseNotificationArrierePlan,
  );
  await afficherNotificationAppel(plugin, appel);
}
