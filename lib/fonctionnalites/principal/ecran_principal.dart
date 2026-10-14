import 'dart:async';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../noyau/appel.dart';
import '../../noyau/service_appel.dart';
import '../../noyau/service_auth.dart';
import '../../partage/composants/barre_navigation.dart';
import '../accueil/ecran_accueil.dart';
import '../alertes/bandeau_alerte_en_cours.dart';
import '../appel/ecran_appel_entrant.dart';
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
  StreamSubscription<AppelEntrant?>? _abonAppels;
  bool _appelAffiche = false;

  @override
  void initState() {
    super.initState();
    // Quand quelqu'un m'appelle, l'écran d'appel entrant s'ouvre par-dessus.
    _abonAppels = context.read<ServiceAppel>().appelsEntrants().listen(
      _surAppelEntrant,
    );
    // Rend ce compte recherchable par son numéro et son e-mail (utile pour
    // les comptes créés avant l'ajout de contacts).
    context.read<ServiceAuth>().assurerRecherchable();
  }

  @override
  void dispose() {
    _abonAppels?.cancel();
    super.dispose();
  }

  void _surAppelEntrant(AppelEntrant? appel) {
    if (appel == null || _appelAffiche || !mounted) return;
    _appelAffiche = true;
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => EcranAppelEntrant(appel: appel),
          ),
        )
        .whenComplete(() => _appelAffiche = false);
  }

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
      body: Stack(
        children: [
          Positioned.fill(child: _onglet()),
          // Bandeau « Alerte en cours », au-dessus de la barre du bas (le
          // gros bouton + dépasse un peu, d'où la marge).
          const Positioned(
            left: 14,
            right: 14,
            bottom: 26,
            child: BandeauAlerteEnCours(),
          ),
        ],
      ),
      bottomNavigationBar: BarreNavigation(
        indexActif: _index,
        auChoix: (i) => setState(() => _index = i),
      ),
    );
  }
}
