import 'package:flutter/material.dart';

import '../../application/couleurs.dart';
import '../../partage/composants/avatar_personne.dart';
import '../../partage/composants/champ_recherche.dart';
import '../../partage/composants/puce.dart';
import '../../partage/styles.dart';
import 'ecran_conversation.dart';

/// Onglet Message : liste des conversations.
class EcranMessagerie extends StatefulWidget {
  const EcranMessagerie({super.key});

  @override
  State<EcranMessagerie> createState() => _EcranMessagerieState();
}

class _EcranMessagerieState extends State<EcranMessagerie> {
  /// Filtre choisi : vrai pour « Tous », faux pour « Groupes ».
  bool _tousChoisi = true;

  void _ouvrir(BuildContext context, ContactDemo contact) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EcranConversation(contact: contact),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Messagerie', style: Styles.gras(24, Colors.black)),
                      const Puce(
                        texte: "Appels d'urgence",
                        fond: Couleurs.fondPuceRouge,
                        couleurTexte: Couleurs.rouge,
                        taille: 11,
                        ombre: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const ChampRecherche(
                    indication: 'Rechercher une conversation',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _Filtre(
                        texte: 'Tous',
                        choisi: _tousChoisi,
                        auAppui: () => setState(() => _tousChoisi = true),
                      ),
                      const SizedBox(width: 12),
                      _Filtre(
                        texte: 'Groupes',
                        choisi: !_tousChoisi,
                        auAppui: () => setState(() => _tousChoisi = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(height: 1, color: Couleurs.grisBordure),
                  _LigneConversation(
                    nom: 'Mariam',
                    apercu: 'Merci beaucoup pour votre aide !',
                    heure: '14:25',
                    nonLus: 2,
                    couleurAvatar: const Color(0xFFE7B7B7),
                    auAppui: () => _ouvrir(context, ContactDemo.mariam),
                  ),
                  const _LigneConversation(
                    nom: 'Voisin yves',
                    apercu: "Alerte rouge, j'arrive sur place !",
                    heure: '15:21',
                    nonLus: 1,
                    couleurAvatar: Color(0xFFD9A58B),
                  ),
                  const _LigneConversation(
                    nom: 'Service mairie',
                    apercu: "Informations sur l'aide",
                    heure: 'Hier',
                    couleurAvatar: Color(0xFFB9C4A6),
                    dernier: true,
                  ),
                ],
              ),
            ),
          ),
          // Bouton flottant « nouvelle conversation ».
          Positioned(
            right: 28,
            bottom: 28,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: Styles.ombre,
              ),
              child: const Icon(Icons.forum, size: 30, color: Couleurs.rouge),
            ),
          ),
        ],
      ),
    );
  }
}

class _LigneConversation extends StatelessWidget {
  const _LigneConversation({
    required this.nom,
    required this.apercu,
    required this.heure,
    required this.couleurAvatar,
    this.nonLus = 0,
    this.auAppui,
    this.dernier = false,
  });

  final String nom;
  final String apercu;
  final String heure;
  final Color couleurAvatar;
  final int nonLus;
  final VoidCallback? auAppui;
  final bool dernier;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: auAppui,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                AvatarPersonne(taille: 52, couleurFond: couleurAvatar),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nom, style: Styles.gras(15.5, Colors.black)),
                      const SizedBox(height: 2),
                      Text(
                        apercu,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Styles.gras(
                          11,
                          Colors.black,
                          poids: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      heure,
                      style: Styles.gras(
                        10.5,
                        Couleurs.rouge,
                        poids: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (nonLus > 0)
                      Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Couleurs.rouge,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$nonLus',
                          style: Styles.gras(9.5, Colors.white),
                        ),
                      )
                    else
                      const SizedBox(height: 18),
                  ],
                ),
              ],
            ),
          ),
          if (!dernier) Container(height: 1, color: Couleurs.grisBordure),
        ],
      ),
    );
  }
}

/// Étiquette de filtre (Tous, Groupes) : rouge quand elle est choisie, grise
/// sinon, toujours avec l'effet en creux.
class _Filtre extends StatelessWidget {
  const _Filtre({
    required this.texte,
    required this.choisi,
    required this.auAppui,
  });

  final String texte;
  final bool choisi;
  final VoidCallback auAppui;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: auAppui,
      child: Puce(
        texte: texte,
        fond: choisi ? Couleurs.rouge : const Color(0xFFE6E6E6),
        couleurTexte: choisi ? Colors.white : Couleurs.rouge,
        taille: 11.5,
        enCreux: true,
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 5),
      ),
    );
  }
}
