import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/normalisation.dart';
import '../../noyau/service_auth.dart';
import '../../partage/adaptatif.dart';
import '../../partage/composants/bouton_google.dart';
import '../../partage/composants/bouton_rouge.dart';
import '../../partage/composants/case_a_cocher.dart';
import '../../partage/composants/champ_texte.dart';
import '../../partage/composants/separateur_ou.dart';
import '../connexion/ecran_connexion.dart';
import '../legal/ecran_texte_legal.dart';
import '../otp/ecran_code_otp.dart';
import '../legal/textes_legaux.dart';
import '../principal/ecran_principal.dart';

/// Page « Créer un compte » (fond rouge foncé).
class EcranInscription extends StatefulWidget {
  const EcranInscription({super.key});

  @override
  State<EcranInscription> createState() => _EcranInscriptionState();
}

class _EcranInscriptionState extends State<EcranInscription> {
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _identifiant = TextEditingController();
  bool _conditionsAcceptees = false;
  bool _enCours = false;

  // Pour faire vibrer un champ précis quand il est vide ou incorrect.
  final GlobalKey<ChampTexteState> _cleNom = GlobalKey();
  final GlobalKey<ChampTexteState> _cleIdentifiant = GlobalKey();
  final GlobalKey<CaseACocherState> _cleConditions = GlobalKey();

  // Les deux liens soulignés de la case des conditions.
  late final TapGestureRecognizer _lienConditions = TapGestureRecognizer()
    ..onTap = () => _ouvrirTexte(conditionsUtilisation);
  late final TapGestureRecognizer _lienConfidentialite = TapGestureRecognizer()
    ..onTap = () => _ouvrirTexte(politiqueConfidentialite);

  void _ouvrirTexte(TexteLegal texte) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EcranTexteLegal(texte: texte)),
    );
  }

  @override
  void dispose() {
    _lienConditions.dispose();
    _lienConfidentialite.dispose();
    _nom.dispose();
    _identifiant.dispose();
    super.dispose();
  }

  void _afficherMessage(String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texte)));
  }

  /// Vérifie les champs, puis demande le code de confirmation par e-mail.
  Future<void> _sInscrire() async {
    // Les champs vides vibrent et clignotent en rouge, sans message.
    final vides = <GlobalKey<ChampTexteState>>[
      if (_nom.text.trim().isEmpty) _cleNom,
      if (_identifiant.text.trim().isEmpty) _cleIdentifiant,
    ];
    if (vides.isNotEmpty) {
      for (final cle in vides) {
        cle.currentState?.signalerErreur();
      }
      return;
    }
    final email = normaliserEmail(_identifiant.text);
    if (!emailValide(email)) {
      _cleIdentifiant.currentState?.signalerErreur();
      return;
    }
    if (!_conditionsAcceptees) {
      _cleConditions.currentState?.signalerErreur();
      return;
    }

    final auth = context.read<ServiceAuth>();
    setState(() => _enCours = true);
    try {
      // Le serveur envoie un code par e-mail, qu'on saisit sur l'écran suivant.
      await auth.demanderCode(email: email);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EcranCodeOtp.parEmail(
            titre: 'Création du compte',
            auth: auth,
            email: email,
            nom: _nom.text,
          ),
        ),
      );
    } on ErreurAuth catch (e) {
      if (!mounted) return;
      _afficherMessage(e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  /// La flèche retour : revient à l'écran d'avant, ou à la connexion s'il n'y
  /// en a pas (sinon l'écran deviendrait noir).
  void _retour() {
    final navigateur = Navigator.of(context);
    if (navigateur.canPop()) {
      navigateur.pop();
    } else {
      navigateur.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const EcranConnexion()),
      );
    }
  }

  /// Connexion avec Google : un seul bouton pour se connecter ou s'inscrire.
  /// Comme pour l'inscription par e-mail, il faut d'abord accepter les
  /// conditions d'utilisation et la politique de confidentialité.
  Future<void> _avecGoogle() async {
    if (!_conditionsAcceptees) {
      _cleConditions.currentState?.signalerErreur();
      return;
    }
    final auth = context.read<ServiceAuth>();
    setState(() => _enCours = true);
    try {
      final reussi = await auth.connecterAvecGoogle();
      if (!mounted || !reussi) return;
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const EcranPrincipal()),
        (_) => false,
      );
    } on ErreurAuth catch (e) {
      if (mounted) _afficherMessage(e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  static const TextStyle _styleBlanc = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12.8,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const TextStyle _styleLien = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12.8,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    decoration: TextDecoration.underline,
    decorationColor: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    final taille = MediaQuery.sizeOf(context);
    // Sur un petit écran, la page défile au lieu de se tasser.
    final hauteur = hauteurConception(context, 600);
    final gauche = taille.width * 0.077;
    final droite = taille.width * 0.083;

    // Place un élément dont le centre est à [centre] (part de la hauteur).
    Widget placer(
      double centre,
      double hauteurElement,
      Widget enfant, {
      bool avecMarges = true,
    }) {
      return Positioned(
        top: hauteur * centre - hauteurElement / 2,
        left: avecMarges ? gauche : 0,
        right: avecMarges ? droite : 0,
        height: hauteurElement,
        child: enfant,
      );
    }

    return Scaffold(
      backgroundColor: Couleurs.rougeFonce,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: hauteur,
            child: Stack(
              children: [
                // Flèche retour.
                Positioned(
                  top: hauteur * 0.064 - 20,
                  left: taille.width * 0.04,
                  child: Semantics(
                    button: true,
                    label: 'Retour',
                    child: GestureDetector(
                      onTap: _retour,
                      child: Container(
                        width: 40,
                        height: 40,
                        color: Colors.transparent,
                        child: const Icon(
                          Icons.chevron_left,
                          size: 38,
                          color: Color(0xFFD60000),
                        ),
                      ),
                    ),
                  ),
                ),
                // Titre et sous-titre.
                Positioned(
                  top: hauteur * 0.1226 - 20,
                  left: taille.width * 0.095,
                  right: droite,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Le titre rétrécit au lieu de passer sur 2 lignes.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Créer un compte',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Rejoignez la communauté\nStarPole',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 17.3,
                          fontWeight: FontWeight.w700,
                          height: 1.46,
                          color: Color(0x99FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
                placer(
                  0.323,
                  50,
                  ChampTexte(
                    key: _cleNom,
                    controleur: _nom,
                    icone: Icons.person,
                    indication: 'Nom complet',
                  ),
                ),
                placer(
                  0.405,
                  50,
                  ChampTexte(
                    key: _cleIdentifiant,
                    controleur: _identifiant,
                    icone: Icons.mark_email_unread_outlined,
                    indication: 'Email',
                    type: TextInputType.emailAddress,
                  ),
                ),
                // Acceptation des conditions.
                placer(
                  0.498,
                  70,
                  Row(
                    children: [
                      CaseACocher(
                        key: _cleConditions,
                        couleurFond: Colors.white,
                        auChangement: (v) => _conditionsAcceptees = v,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: _styleBlanc,
                            children: [
                              const TextSpan(text: "J'accepte les "),
                              TextSpan(
                                text: "conditions d'utilisation",
                                style: _styleLien,
                                recognizer: _lienConditions,
                              ),
                              const TextSpan(text: ' et la '),
                              TextSpan(
                                text: 'politique de confidentialité',
                                style: _styleLien,
                                recognizer: _lienConfidentialite,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                placer(
                  0.623,
                  50,
                  BoutonRouge(
                    libelle: "S'inscrire",
                    enCours: _enCours,
                    auAppui: _sInscrire,
                  ),
                ),
                placer(0.685, 24, const SeparateurOu(couleur: Colors.white)),
                placer(
                  0.738,
                  50,
                  BoutonGoogle(auAppui: _avecGoogle, enCours: _enCours),
                ),
                // « Vous avez deja un compte ? Se connecter »
                placer(
                  0.831,
                  84,
                  Column(
                    children: [
                      const Text(
                        'Vous avez deja un compte ?',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15.4,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const EcranConnexion(),
                          ),
                        ),
                        child: const Text(
                          'Se connecter',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15.4,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  avecMarges: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
