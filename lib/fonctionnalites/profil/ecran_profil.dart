import 'package:flutter/material.dart';

import '../../application/couleurs.dart';
import '../../partage/styles.dart';
import 'ecran_mes_alertes.dart';

/// Onglet Profil : photo, nom, statistiques et menu.
class EcranProfil extends StatelessWidget {
  const EcranProfil({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.settings, size: 36, color: Colors.black),
                Expanded(
                  child: Center(
                    child: Text(
                      'Mon profil',
                      style: Styles.gras(23, Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
            const SizedBox(height: 30),
            const _PhotoProfil(),
            const SizedBox(height: 22),
            Text('Traore Ange Fresnel', style: Styles.gras(19, Colors.black)),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Couleurs.rouge,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text('Membre actif', style: Styles.gras(12.5, Couleurs.rouge)),
              ],
            ),
            const SizedBox(height: 4),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 20, color: Color(0xFFFFB800)),
                Icon(Icons.star, size: 20, color: Color(0xFFFFB800)),
                Icon(Icons.star, size: 20, color: Color(0xFFFFB800)),
              ],
            ),
            const SizedBox(height: 22),
            const _Statistiques(),
            const SizedBox(height: 20),
            Container(height: 1, color: Couleurs.grisBordure),
            _LigneMenu(
              icone: Icons.edit_note,
              texte: 'Mes alertes, aides & dons',
              auAppui: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EcranMesAlertes(),
                ),
              ),
            ),
            const _LigneMenu(icone: Icons.help, texte: 'Aides & support'),
            const _LigneMenu(icone: Icons.help, texte: 'A propos'),
          ],
        ),
      ),
    );
  }
}

/// Photo de profil ronde avec la pastille de modification.
class _PhotoProfil extends StatelessWidget {
  const _PhotoProfil();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 126,
      height: 126,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF3B9BFF),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: Styles.ombre,
            ),
            child: const Icon(Icons.person, size: 78, color: Colors.white),
          ),
          Positioned(
            right: 0,
            bottom: 6,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: Styles.ombre,
              ),
              child: const Icon(Icons.edit, size: 16, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _Statistiques extends StatelessWidget {
  const _Statistiques();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          const Expanded(
            child: _Statistique(valeur: '12', libelle: 'Alertes\npubliées'),
          ),
          Container(width: 1, color: Colors.black54),
          const Expanded(
            child: _Statistique(valeur: '8', libelle: 'Aides\napportées'),
          ),
          Container(width: 1, color: Colors.black54),
          const Expanded(
            child: _Statistique(valeur: '5', libelle: 'Dons\neffectués'),
          ),
        ],
      ),
    );
  }
}

class _Statistique extends StatelessWidget {
  const _Statistique({required this.valeur, required this.libelle});

  final String valeur;
  final String libelle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(valeur, style: Styles.gras(13.5, Colors.black)),
        const SizedBox(height: 2),
        Text(
          libelle,
          textAlign: TextAlign.center,
          style: Styles.gras(11.5, Colors.black, hauteur: 1.35),
        ),
      ],
    );
  }
}

class _LigneMenu extends StatelessWidget {
  const _LigneMenu({required this.icone, required this.texte, this.auAppui});

  final IconData icone;
  final String texte;
  final VoidCallback? auAppui;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: auAppui,
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                Icon(icone, size: 30, color: Colors.black),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    texte,
                    style: Styles.gras(13.5, Couleurs.grisTexte),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 28, color: Colors.black),
              ],
            ),
          ),
          Container(height: 1, color: Couleurs.grisBordure),
        ],
      ),
    );
  }
}
