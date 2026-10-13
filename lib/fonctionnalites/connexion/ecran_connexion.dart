import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/service_auth.dart';
import '../../partage/composants/bouton_google.dart';
import '../../partage/composants/bouton_rouge.dart';
import '../../partage/composants/case_a_cocher.dart';
import '../../partage/composants/champ_texte.dart';
import '../../partage/composants/separateur_ou.dart';
import '../inscription/ecran_inscription.dart';
import '../principal/ecran_principal.dart';

/// Page de connexion (fond blanc).
class EcranConnexion extends StatefulWidget {
  const EcranConnexion({super.key});

  @override
  State<EcranConnexion> createState() => _EcranConnexionState();
}

class _EcranConnexionState extends State<EcranConnexion> {
  final TextEditingController _identifiant = TextEditingController();
  final TextEditingController _motDePasse = TextEditingController();
  bool _enCours = false;

  // Pour faire vibrer un champ précis quand il est vide ou incorrect.
  final GlobalKey<ChampTexteState> _cleIdentifiant = GlobalKey();
  final GlobalKey<ChampTexteState> _cleMotDePasse = GlobalKey();

  @override
  void dispose() {
    _identifiant.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  void _afficherMessage(String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texte)));
  }

  /// Vérifie les champs, puis connecte l'utilisateur avec Firebase.
  Future<void> _seConnecter() async {
    final identifiant = _identifiant.text.trim();
    // Les champs vides vibrent et clignotent en rouge, sans message.
    if (identifiant.isEmpty || _motDePasse.text.isEmpty) {
      if (identifiant.isEmpty) _cleIdentifiant.currentState?.signalerErreur();
      if (_motDePasse.text.isEmpty) {
        _cleMotDePasse.currentState?.signalerErreur();
      }
      return;
    }
    if (!identifiant.contains('@')) {
      // La connexion par numéro n'existe pas encore : on explique pourquoi.
      _cleIdentifiant.currentState?.signalerErreur();
      _afficherMessage(
        'Pour le moment, connectez-vous avec votre adresse e-mail.',
      );
      return;
    }

    final auth = context.read<ServiceAuth>();
    setState(() => _enCours = true);
    try {
      await auth.connecter(email: identifiant, motDePasse: _motDePasse.text);
      if (!mounted) return;
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const EcranPrincipal()),
        (_) => false,
      );
    } on ErreurAuth catch (e) {
      if (!mounted) return;
      // Les champs concernés vibrent, et le message explique le problème.
      if (e.champs.contains('email')) {
        _cleIdentifiant.currentState?.signalerErreur();
      }
      if (e.champs.contains('motDePasse')) {
        _cleMotDePasse.currentState?.signalerErreur();
      }
      _afficherMessage(e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  /// Connexion avec Google : un seul bouton pour se connecter ou s'inscrire.
  Future<void> _avecGoogle() async {
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

  @override
  Widget build(BuildContext context) {
    final taille = MediaQuery.sizeOf(context);
    final hauteur = taille.height;
    final gauche = taille.width * 0.066;
    final droite = taille.width * 0.08;

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: hauteur,
            child: Stack(
              children: [
                // Logo StarPole. L'image est carrée avec des marges : on l'agrandit
                // pour que le dessin occupe environ la moitié de la largeur.
                placer(
                  0.139,
                  taille.width * 0.79,
                  Image.asset(
                    'assets/images/Starpole logo.png',
                    fit: BoxFit.contain,
                  ),
                  avecMarges: false,
                ),
                placer(
                  0.243,
                  40,
                  const Center(
                    child: Text(
                      'StarPole',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 31.5,
                        fontWeight: FontWeight.w700,
                        color: Couleurs.rougeMarque,
                      ),
                    ),
                  ),
                  avecMarges: false,
                ),
                placer(
                  0.354,
                  34,
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Connexion',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                placer(
                  0.425,
                  50,
                  ChampTexte(
                    key: _cleIdentifiant,
                    erreurEnRouge: true,
                    controleur: _identifiant,
                    icone: Icons.contact_phone,
                    indication: 'Email ou numero de telephone',
                    type: TextInputType.emailAddress,
                  ),
                ),
                placer(
                  0.499,
                  50,
                  ChampTexte(
                    key: _cleMotDePasse,
                    erreurEnRouge: true,
                    controleur: _motDePasse,
                    icone: Icons.lock,
                    indication: 'Mot de passe',
                    masque: true,
                  ),
                ),
                placer(
                  0.557,
                  24,
                  const Row(
                    children: [
                      CaseACocher(couleurFond: Color(0xFFD9D9D9)),
                      SizedBox(width: 9),
                      Text(
                        'Se souvenir de moi',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.6,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.6,
                          fontWeight: FontWeight.w700,
                          color: Couleurs.rouge,
                        ),
                      ),
                    ],
                  ),
                ),
                placer(
                  0.639,
                  50,
                  BoutonRouge(
                    libelle: 'Se connecter',
                    enCours: _enCours,
                    auAppui: _seConnecter,
                  ),
                ),
                placer(0.708, 24, const SeparateurOu(couleur: Colors.black)),
                placer(
                  0.762,
                  50,
                  BoutonGoogle(auAppui: _avecGoogle, enCours: _enCours),
                ),
                // « Vous n'avez pas de compte ? S'inscrire »
                placer(
                  0.856,
                  50,
                  Column(
                    children: [
                      const Text(
                        "Vous n'avez pas de compte ?",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15.6,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const EcranInscription(),
                          ),
                        ),
                        child: const Text(
                          "S'inscrire",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15.6,
                            fontWeight: FontWeight.w700,
                            color: Couleurs.rouge,
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
