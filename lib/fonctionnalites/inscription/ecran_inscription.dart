import 'package:flutter/material.dart';

import '../../application/couleurs.dart';
import '../../partage/composants/bouton_google.dart';
import '../../partage/composants/bouton_rouge.dart';
import '../../partage/composants/case_a_cocher.dart';
import '../../partage/composants/champ_texte.dart';
import '../../partage/composants/separateur_ou.dart';
import '../connexion/ecran_connexion.dart';
import '../principal/ecran_principal.dart';

/// Page « Créer un compte » (fond rouge foncé).
class EcranInscription extends StatelessWidget {
  const EcranInscription({super.key});

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
    final hauteur = taille.height;
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
                      onTap: () => Navigator.of(context).pop(),
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
                      Text(
                        'Créer un compte',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
                  0.281,
                  50,
                  const ChampTexte(
                    icone: Icons.person,
                    indication: 'Nom complet',
                  ),
                ),
                placer(
                  0.356,
                  50,
                  const ChampTexte(
                    icone: Icons.phone_in_talk_outlined,
                    indication: 'Numero de telephone',
                    type: TextInputType.phone,
                  ),
                ),
                placer(
                  0.4325,
                  50,
                  const ChampTexte(
                    icone: Icons.mark_email_unread_outlined,
                    indication: 'Email',
                    type: TextInputType.emailAddress,
                  ),
                ),
                placer(
                  0.508,
                  50,
                  const ChampTexte(
                    icone: Icons.lock,
                    indication: 'Mot de passe',
                    masque: true,
                    avecOeil: true,
                  ),
                ),
                // Acceptation des conditions.
                placer(
                  0.584,
                  44,
                  Row(
                    children: [
                      const CaseACocher(couleurFond: Colors.white),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text.rich(
                          const TextSpan(
                            style: _styleBlanc,
                            children: [
                              TextSpan(text: "J'accepte les "),
                              TextSpan(
                                text: "conditions d'utilisation",
                                style: _styleLien,
                              ),
                              TextSpan(text: ' et la '),
                              TextSpan(
                                text: 'politique de confidentialité',
                                style: _styleLien,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                placer(
                  0.676,
                  50,
                  BoutonRouge(
                    libelle: "S'inscrire",
                    auAppui: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const EcranPrincipal(),
                      ),
                      (_) => false,
                    ),
                  ),
                ),
                placer(0.737, 24, const SeparateurOu(couleur: Colors.white)),
                placer(0.789, 50, BoutonGoogle(auAppui: () {})),
                // « Vous avez deja un compte ? Se connecter »
                placer(
                  0.881,
                  50,
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
