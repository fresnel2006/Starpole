import 'package:flutter/material.dart';

/// Séparateur « ou » : un trait, le mot, un trait.
class SeparateurOu extends StatelessWidget {
  const SeparateurOu({super.key, required this.couleur});

  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: couleur)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            'ou',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: couleur,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: couleur)),
      ],
    );
  }
}
