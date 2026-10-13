import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../fonctionnalites/info_departs/ecran_info_departs.dart';
import '../noyau/alerte_en_cours.dart';

/// Racine de l'application.
class ApplicationStarPole extends StatelessWidget {
  const ApplicationStarPole({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AlerteEnCoursNotifier(),
      child: MaterialApp(
        title: 'StarPole',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Poppins'),
        home: const EcranInfoDeparts(),
      ),
    );
  }
}
