import 'package:flutter/material.dart';

import '../styles.dart';

/// Une ligne du menu déroulant des trois points.
class EntreeMenu {
  const EntreeMenu({
    required this.valeur,
    required this.icone,
    required this.texte,
    this.separateurAvant = false,
  });

  /// Ce qui est renvoyé quand on choisit cette ligne.
  final String valeur;
  final IconData icone;
  final String texte;

  /// Vrai pour tracer un trait fin au-dessus de la ligne.
  final bool separateurAvant;
}

/// Les trois points qui ouvrent un menu déroulant blanc, avec une icône fine
/// devant chaque texte (comme dans WhatsApp).
class MenuTroisPoints extends StatelessWidget {
  const MenuTroisPoints({
    super.key,
    required this.entrees,
    required this.auChoix,
  });

  final List<EntreeMenu> entrees;
  final ValueChanged<String> auChoix;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: "Plus d'options",
      padding: EdgeInsets.zero,
      offset: const Offset(0, 40),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: auChoix,
      itemBuilder: (_) => [
        for (final entree in entrees) ...[
          if (entree.separateurAvant) const PopupMenuDivider(height: 8),
          PopupMenuItem<String>(
            value: entree.valeur,
            height: 48,
            child: Row(
              children: [
                Icon(entree.icone, size: 22, color: Colors.black),
                const SizedBox(width: 14),
                Text(
                  entree.texte,
                  style: Styles.gras(
                    13.5,
                    Colors.black,
                    poids: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.more_vert, size: 24, color: Colors.black),
      ),
    );
  }
}
