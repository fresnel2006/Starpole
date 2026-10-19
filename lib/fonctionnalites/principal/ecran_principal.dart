import 'dart:async';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../noyau/appel.dart';
import '../../noyau/service_appel.dart';
import '../../noyau/service_auth.dart';
import '../../noyau/service_messagerie.dart';
import '../../noyau/service_notifications.dart';
import '../../partage/composants/barre_navigation.dart';
import '../accueil/ecran_accueil.dart';
import '../alertes/bandeau_alerte_en_cours.dart';
import '../appel/ecran_appel_entrant.dart';
import '../carte/ecran_carte.dart';
import '../messagerie/ecran_conversation.dart';
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

class _EcranPrincipalState extends State<EcranPrincipal>
    with WidgetsBindingObserver {
  int _index = 0;
  Timer? _presence;
  StreamSubscription<AppelEntrant?>? _abonAppels;
  StreamSubscription<NotificationRecue>? _abonOuvertures;
  bool _appelAffiche = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _demarrerPresence();
    // Quand quelqu'un m'appelle, l'écran d'appel entrant s'ouvre par-dessus.
    _abonAppels = context.read<ServiceAppel>().appelsEntrants().listen(
      _surAppelEntrant,
    );
    // Rend ce compte recherchable par son numéro et son e-mail (utile pour
    // les comptes créés avant l'ajout de contacts).
    context.read<ServiceAuth>().assurerRecherchable();

    // Notifications du téléphone : autorisation, enregistrement de ce
    // téléphone, et ouverture de la conversation quand on en touche une.
    final notifications = context.read<ServiceNotifications>();
    notifications.activer();
    _abonOuvertures = notifications.ouvertures.listen(_ouvrirDepuis);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // L'appli a été ouverte en touchant une notification (elle était fermée).
      final initiale = await notifications.ouvertureInitiale();
      if (initiale != null && mounted) _ouvrirDepuis(initiale);
    });
  }

  /// Tant que l'appli est ouverte, on signale régulièrement qu'on est
  /// connecté (deux coches chez la personne qui m'écrit).
  void _demarrerPresence() {
    _presence?.cancel();
    final messagerie = context.read<ServiceMessagerie>();
    messagerie.signalerPresence();
    _presence = Timer.periodic(
      const Duration(seconds: 45),
      (_) => messagerie.signalerPresence(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    if (etat == AppLifecycleState.resumed) {
      _demarrerPresence();
    } else {
      _presence?.cancel();
      _presence = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presence?.cancel();
    _abonOuvertures?.cancel();
    _abonAppels?.cancel();
    super.dispose();
  }

  /// Ouvre la conversation d'une notification de message.
  void _ouvrirDepuis(NotificationRecue notification) {
    final conversation = notification.conversationId;
    final expediteur = notification.expediteurId;
    if (notification.type != 'message' ||
        conversation == null ||
        expediteur == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EcranConversation(
          conversationId: conversation,
          autreId: expediteur,
          autreNom: notification.titre.isEmpty ? 'Message' : notification.titre,
        ),
      ),
    );
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
