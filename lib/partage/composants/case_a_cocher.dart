import 'package:flutter/material.dart';

/// Petite case carrée à cocher (Se souvenir de moi, conditions d'utilisation).
class CaseACocher extends StatefulWidget {
  const CaseACocher({super.key, required this.couleurFond});

  /// Couleur de la case quand elle est vide.
  final Color couleurFond;

  @override
  State<CaseACocher> createState() => _CaseACocherState();
}

class _CaseACocherState extends State<CaseACocher> {
  bool _cochee = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _cochee = !_cochee),
      child: Container(
        width: 19,
        height: 19,
        decoration: BoxDecoration(
          color: widget.couleurFond,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: _cochee
            ? const Icon(Icons.check, size: 15, color: Colors.black)
            : null,
      ),
    );
  }
}
