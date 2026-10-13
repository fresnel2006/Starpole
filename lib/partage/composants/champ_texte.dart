import 'package:flutter/material.dart';

/// Champ blanc arrondi avec une icône à gauche (téléphone, mail, mot de passe...).
/// Si [masque] est vrai, le texte est caché et un oeil permet de l'afficher.
class ChampTexte extends StatefulWidget {
  const ChampTexte({
    super.key,
    required this.icone,
    required this.indication,
    this.masque = false,
    this.avecOeil = false,
    this.type = TextInputType.text,
  });

  final IconData icone;
  final String indication;
  final bool masque;
  final bool avecOeil;
  final TextInputType type;

  @override
  State<ChampTexte> createState() => _ChampTexteState();
}

class _ChampTexteState extends State<ChampTexte> {
  late bool _cache = widget.masque;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E2E2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(widget.icone, size: 28, color: Colors.black),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              obscureText: _cache,
              keyboardType: widget.type,
              cursorColor: Colors.black,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: widget.indication,
                hintStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF555555),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (widget.avecOeil)
            GestureDetector(
              onTap: () => setState(() => _cache = !_cache),
              child: Icon(
                _cache
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 26,
                color: Colors.black,
              ),
            ),
        ],
      ),
    );
  }
}
