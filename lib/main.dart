import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'application/application.dart';
import 'firebase_options.dart';
import 'noyau/notification_appel.dart';
import 'noyau/service_alertes.dart';
import 'noyau/service_auth.dart';
import 'noyau/service_messagerie.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Appli fermée ou en arrière-plan : un appel entrant fait sonner le
  // téléphone avec une notification d'appel.
  FirebaseMessaging.onBackgroundMessage(gestionnaireMessageArrierePlan);
  runApp(
    ApplicationStarPole(
      auth: ServiceAuthFirebase(),
      alertes: ServiceAlertesFirebase(),
      messagerie: ServiceMessagerieFirebase(),
    ),
  );
}
