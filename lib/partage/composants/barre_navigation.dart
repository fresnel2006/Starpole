import 'package:flutter/material.dart';

import '../../application/couleurs.dart';
import '../styles.dart';

/// Barre de navigation du bas : Accueil, Carte, bouton +, Message, Profil.
/// Les index vont de 0 (Accueil) à 4 (Profil), le + étant l'index 2.
class BarreNavigation extends StatelessWidget {
  const BarreNavigation({
    super.key,
    required this.indexActif,
    required this.auChoix,
  });

  final int indexActif;
  final ValueChanged<int> auChoix;

  @override
  Widget build(BuildContext context) {
    final basSysteme = MediaQuery.paddingOf(context).bottom;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(bottom: basSysteme),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 70,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                _Onglet(
                  icone: Icons.home_outlined,
                  iconeActive: Icons.home,
                  libelle: 'Accueil',
                  actif: indexActif == 0,
                  auAppui: () => auChoix(0),
                ),
                _Onglet(
                  icone: Icons.map_outlined,
                  iconeActive: Icons.map,
                  libelle: 'Carte',
                  actif: indexActif == 1,
                  auAppui: () => auChoix(1),
                ),
                const Expanded(child: SizedBox()),
                _Onglet(
                  icone: Icons.chat_outlined,
                  iconeActive: Icons.chat,
                  libelle: 'Message',
                  actif: indexActif == 3,
                  auAppui: () => auChoix(3),
                ),
                _Onglet(
                  icone: Icons.person_outline,
                  iconeActive: Icons.person,
                  libelle: 'Profil',
                  actif: indexActif == 4,
                  auAppui: () => auChoix(4),
                ),
              ],
            ),
          ),
          // Gros bouton + au centre, qui dépasse de la barre.
          Positioned(
            top: -14,
            left: 0,
            right: 0,
            child: Center(
              child: Semantics(
                button: true,
                label: 'Poster une alerte',
                child: GestureDetector(
                  onTap: () => auChoix(2),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Couleurs.rouge,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: Styles.ombre,
                    ),
                    child: const Icon(Icons.add, size: 38, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Onglet extends StatelessWidget {
  const _Onglet({
    required this.icone,
    required this.iconeActive,
    required this.libelle,
    required this.actif,
    required this.auAppui,
  });

  final IconData icone;
  final IconData iconeActive;
  final String libelle;
  final bool actif;
  final VoidCallback auAppui;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: auAppui,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(actif ? iconeActive : icone, size: 31, color: Couleurs.rouge),
            const SizedBox(height: 1),
            Text(libelle, style: Styles.gras(10.5, Couleurs.rouge)),
          ],
        ),
      ),
    );
  }
}
