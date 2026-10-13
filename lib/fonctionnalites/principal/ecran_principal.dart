import 'package:flutter/material.dart';

import '../../partage/composants/barre_navigation.dart';
import '../accueil/ecran_accueil.dart';
import '../carte/ecran_carte.dart';
import '../messagerie/ecran_messagerie.dart';
import '../poster_alerte/ecran_poster_alerte.dart';
import '../profil/ecran_profil.dart';

/// Écran qui contient la barre de navigation du bas et l'onglet affiché.
/// Index : 0 Accueil, 1 Carte, 2 Poster une alerte (+), 3 Message, 4 Profil.
class EcranPrincipal extends StatefulWidget {
  const EcranPrincipal({super.key});

  @override
  State<EcranPrincipal> createState() => _EcranPrincipalState();
}

class _EcranPrincipalState extends State<EcranPrincipal> {
  int _index = 0;

  Widget _onglet() {
    switch (_index) {
      case 1:
        return const EcranCarte();
      case 2:
        return EcranPosterAlerte(auRetour: () => setState(() => _index = 0));
      case 3:
        return const EcranMessagerie();
      case 4:
        return const EcranProfil();
      default:
        return const EcranAccueil();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _onglet(),
      bottomNavigationBar: BarreNavigation(
        indexActif: _index,
        auChoix: (i) => setState(() => _index = i),
      ),
    );
  }
}
