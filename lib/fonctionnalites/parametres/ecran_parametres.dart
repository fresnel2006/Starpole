import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/service_auth.dart';
import '../../noyau/service_carnet.dart';
import '../../noyau/service_notifications.dart';
import '../../partage/composants/entete_retour.dart';
import '../../partage/composants/ligne_menu.dart';
import '../../partage/styles.dart';
import '../connexion/ecran_connexion.dart';
import '../legal/ecran_texte_legal.dart';
import '../legal/textes_legaux.dart';

/// Page « Paramètres » : les autorisations de l'appli, les textes légaux, des
/// informations sur StarPole et la déconnexion.
class EcranParametres extends StatelessWidget {
  const EcranParametres({super.key});

  void _ouvrirTexte(BuildContext context, TexteLegal texte) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EcranTexteLegal(texte: texte)),
    );
  }

  /// Un petit titre de section.
  Widget _section(String titre) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 2),
    child: Text(titre, style: Styles.gras(13, Couleurs.rouge)),
  );

  Future<void> _aPropos(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (contexte) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'À propos de StarPole',
          style: Styles.gras(17, Colors.black),
        ),
        content: Text(
          "Une étoile pour ne jamais rester seul.\n\n"
          "StarPole est l'application d'entraide de quartier d'Abidjan : "
          "alerter, demander, donner. Projet du Groupe 7 de l'ESATIC, "
          "encadré par M. Cédric Cissé.\n\n"
          "Bientôt disponible.",
          style: Styles.gras(
            13,
            Couleurs.grisTexte,
            hauteur: 1.55,
            poids: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexte).pop(),
            child: Text('Fermer', style: Styles.gras(14, Couleurs.rouge)),
          ),
        ],
      ),
    );
  }

  /// Demande confirmation, puis déconnecte et revient à la page de connexion.
  Future<void> _seDeconnecter(BuildContext context) async {
    final auth = context.read<ServiceAuth>();
    final notifications = context.read<ServiceNotifications>();
    final navigateur = Navigator.of(context);
    final confirme = await showDialog<bool>(
      context: context,
      builder: (contexte) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Se déconnecter ?', style: Styles.gras(17, Colors.black)),
        content: Text(
          'Vous devrez vous reconnecter pour utiliser StarPole.',
          style: Styles.gras(
            13,
            Couleurs.grisTexte,
            hauteur: 1.5,
            poids: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexte).pop(false),
            child: Text('Annuler', style: Styles.gras(14, Couleurs.grisTexte)),
          ),
          TextButton(
            onPressed: () => Navigator.of(contexte).pop(true),
            child: Text(
              'Se déconnecter',
              style: Styles.gras(14, Couleurs.rouge),
            ),
          ),
        ],
      ),
    );
    if (confirme != true) return;
    // Ce téléphone ne doit plus recevoir les notifications de ce compte.
    await notifications.desactiver();
    await auth.deconnecter();
    await navigateur.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const EcranConnexion()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EnteteRetour(titre: 'Paramètres'),
              _section('Application'),
              LigneMenu(
                icone: Icons.shield_outlined,
                texte: "Autorisations de l'application",
                auAppui: () => context.read<ServiceCarnet>().ouvrirReglages(),
              ),
              _section('Informations légales'),
              LigneMenu(
                icone: Icons.description_outlined,
                texte: "Conditions d'utilisation",
                auAppui: () => _ouvrirTexte(context, conditionsUtilisation),
              ),
              LigneMenu(
                icone: Icons.privacy_tip_outlined,
                texte: 'Politique de confidentialité',
                auAppui: () => _ouvrirTexte(context, politiqueConfidentialite),
              ),
              LigneMenu(
                icone: Icons.info_outline,
                texte: 'À propos',
                auAppui: () => _aPropos(context),
              ),
              _section('Compte'),
              LigneMenu(
                icone: Icons.logout,
                texte: 'Se déconnecter',
                couleur: Couleurs.rouge,
                auAppui: () => _seDeconnecter(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
