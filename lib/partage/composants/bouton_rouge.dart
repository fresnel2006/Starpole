import 'package:flutter/material.dart';

import '../../application/couleurs.dart';

/// Grand bouton rouge arrondi (Se connecter, S'inscrire).
class BoutonRouge extends StatelessWidget {
  const BoutonRouge({
    super.key,
    required this.libelle,
    required this.auAppui,
    this.enCours = false,
  });

  final String libelle;
  final VoidCallback auAppui;

  /// Si vrai, un cercle de chargement remplace le texte et le bouton est bloqué.
  final bool enCours;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: libelle,
      child: GestureDetector(
        onTap: enCours ? null : auAppui,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Couleurs.rouge,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: enCours
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
              : Text(
                  libelle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20.8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
