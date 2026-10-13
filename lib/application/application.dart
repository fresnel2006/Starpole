import 'package:flutter/material.dart';

import '../fonctionnalites/info_departs/ecran_info_departs.dart';

/// Racine de l'application.
class ApplicationStarPole extends StatelessWidget {
  const ApplicationStarPole({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StarPole',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      home: const EcranInfoDeparts(),
    );
  }
}
