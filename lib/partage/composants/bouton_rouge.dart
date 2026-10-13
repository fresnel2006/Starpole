import 'package:flutter/material.dart';

import '../../application/couleurs.dart';

/// Grand bouton rouge arrondi (Se connecter, S'inscrire).
class BoutonRouge extends StatelessWidget {
  const BoutonRouge({super.key, required this.libelle, required this.auAppui});

  final String libelle;
  final VoidCallback auAppui;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: libelle,
      child: GestureDetector(
        onTap: auAppui,
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
          child: Text(
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
