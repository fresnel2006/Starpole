import 'package:flutter/material.dart';

import '../../application/couleurs.dart';
import '../styles.dart';

/// Champ de recherche blanc arrondi avec une loupe.
class ChampRecherche extends StatelessWidget {
  const ChampRecherche({super.key, required this.indication});

  final String indication;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Couleurs.grisBordure),
        boxShadow: Styles.ombre,
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 28, color: Colors.black),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: Styles.gras(12, Colors.black),
              decoration: InputDecoration(
                hintText: indication,
                hintStyle: Styles.gras(11.5, Couleurs.grisIndication),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
