import 'package:flutter/material.dart';

import '../../application/couleurs.dart';
import '../styles.dart';

/// Une ligne de menu : icône, texte et flèche, avec un trait fin dessous.
class LigneMenu extends StatelessWidget {
  const LigneMenu({
    super.key,
    required this.icone,
    required this.texte,
    this.auAppui,
    this.couleur,
  });

  final IconData icone;
  final String texte;
  final VoidCallback? auAppui;

  /// Couleur de l'icône et du texte (par défaut : noir et gris).
  final Color? couleur;

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
                Icon(icone, size: 30, color: couleur ?? Colors.black),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    texte,
                    style: Styles.gras(13.5, couleur ?? Couleurs.grisTexte),
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
