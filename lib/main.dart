import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'application/application.dart';
import 'firebase_options.dart';
import 'noyau/service_alertes.dart';
import 'noyau/service_auth.dart';
import 'noyau/service_messagerie.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ApplicationStarPole(
      auth: ServiceAuthFirebase(),
      alertes: ServiceAlertesFirebase(),
      messagerie: ServiceMessagerieFirebase(),
    ),
  );
}
