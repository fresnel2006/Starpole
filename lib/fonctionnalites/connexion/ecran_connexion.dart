import 'package:flutter/material.dart';

import '../../application/couleurs.dart';
import '../../partage/composants/bouton_google.dart';
import '../../partage/composants/bouton_rouge.dart';
import '../../partage/composants/case_a_cocher.dart';
import '../../partage/composants/champ_texte.dart';
import '../../partage/composants/separateur_ou.dart';
import '../inscription/ecran_inscription.dart';
import '../principal/ecran_principal.dart';

/// Page de connexion (fond blanc).
class EcranConnexion extends StatelessWidget {
  const EcranConnexion({super.key});

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
                  const ChampTexte(
                    icone: Icons.contact_phone,
                    indication: 'Email ou numero de telephone',
                    type: TextInputType.emailAddress,
                  ),
                ),
                placer(
                  0.499,
                  50,
                  const ChampTexte(
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
                    auAppui: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const EcranPrincipal(),
                      ),
                      (_) => false,
                    ),
                  ),
                ),
                placer(0.708, 24, const SeparateurOu(couleur: Colors.black)),
                placer(0.762, 50, BoutonGoogle(auAppui: () {})),
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
