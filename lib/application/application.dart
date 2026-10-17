import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../fonctionnalites/info_departs/ecran_info_departs.dart';
import '../fonctionnalites/principal/ecran_principal.dart';
import '../noyau/position_utilisateur.dart';
import '../noyau/service_alertes.dart';
import '../noyau/service_appel.dart';
import '../noyau/service_auth.dart';
import '../noyau/service_carnet.dart';
import '../noyau/service_localisation.dart';
import '../noyau/service_messagerie.dart';
import '../noyau/service_photo.dart';
import '../partage/adaptatif.dart';
import '../partage/composants/carte_3d.dart';

/// Racine de l'application.
class ApplicationStarPole extends StatelessWidget {
  const ApplicationStarPole({
    super.key,
    required this.auth,
    required this.alertes,
    required this.messagerie,
    this.photos,
    this.localisation,
    this.carnet,
    this.appels,
    this.constructeurCarte,
  });

  /// Le service de compte (Firebase dans l'appli, un faux dans les tests).
  final ServiceAuth auth;

  /// Le service des alertes (Firestore dans l'appli, un faux dans les tests).
  final ServiceAlertes alertes;

  /// Le service des contacts et des conversations (un faux dans les tests).
  final ServiceMessagerie messagerie;

  /// Le service de choix de photo (un faux dans les tests).
  final ServicePhoto? photos;

  /// Le service de position (un faux dans les tests).
  final ServiceLocalisation? localisation;

  /// Le service du carnet de contacts du téléphone (un faux dans les tests).
  final ServiceCarnet? carnet;

  /// Le service des appels voix et vidéo (un faux dans les tests).
  final ServiceAppel? appels;

  /// La fabrique de la carte (une fausse carte dans les tests).
  final ConstructeurCarte? constructeurCarte;

  @override
  Widget build(BuildContext context) {
    final servicePosition = localisation ?? ServiceLocalisationReel();
    return MultiProvider(
      providers: [
        Provider<ServiceAuth>.value(value: auth),
        Provider<ServiceAlertes>.value(value: alertes),
        Provider<ServiceMessagerie>.value(value: messagerie),
        Provider<ServicePhoto>.value(value: photos ?? ServicePhotoReel()),
        Provider<ServiceLocalisation>.value(value: servicePosition),
        Provider<ServiceCarnet>.value(value: carnet ?? ServiceCarnetReel()),
        Provider<ServiceAppel>.value(value: appels ?? ServiceAppelFirebase()),
        Provider<ConstructeurCarte>.value(
          value: constructeurCarte ?? construireCarte3d,
        ),
        ChangeNotifierProvider(
          create: (_) => PositionUtilisateur(servicePosition),
        ),
      ],
      child: MaterialApp(
        title: 'StarPole',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Poppins'),
        // Largeur limitée sur grand écran, texte plafonné.
        builder: cadreAdaptatif,
        // Déjà connecté : on va directement à l'accueil.
        home: auth.estConnecte
            ? const EcranPrincipal()
            : const EcranInfoDeparts(),
      ),
    );
  }
}
