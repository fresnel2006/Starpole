import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Bouton blanc « Continuer avec Google » avec le logo Google dessiné.
class BoutonGoogle extends StatelessWidget {
  const BoutonGoogle({super.key, required this.auAppui});

  final VoidCallback auAppui;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Continuer avec Google',
      child: GestureDetector(
        onTap: auAppui,
        child: Container(
          height: 50,
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
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 26, height: 26, child: _LogoGoogle()),
              SizedBox(width: 16),
              Text(
                'Continuer avec Google',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15.6,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le « G » de Google : quatre arcs de couleur et une barre bleue.
class _LogoGoogle extends StatelessWidget {
  const _LogoGoogle();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _PeintreGoogle());
}

class _PeintreGoogle extends CustomPainter {
  static const Color _rouge = Color(0xFFEA4335);
  static const Color _jaune = Color(0xFFFBBC05);
  static const Color _vert = Color(0xFF34A853);
  static const Color _bleu = Color(0xFF4285F4);

  @override
  void paint(Canvas canvas, Size size) {
    final epaisseur = size.width * 0.2;
    final centre = size.center(Offset.zero);
    final rayon = size.width / 2 - epaisseur / 2;
    final zone = Rect.fromCircle(center: centre, radius: rayon);

    void arc(Color couleur, double debut, double fin) {
      final peinture = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = epaisseur
        ..color = couleur;
      canvas.drawArc(
        zone,
        debut * math.pi / 180,
        (fin - debut) * math.pi / 180,
        false,
        peinture,
      );
    }

    arc(_rouge, 210, 315);
    arc(_jaune, 135, 210);
    arc(_vert, 45, 135);
    arc(_bleu, 0, 45);

    // Barre horizontale du « G ».
    final barre = Paint()..color = _bleu;
    canvas.drawRect(
      Rect.fromLTRB(
        centre.dx,
        centre.dy - epaisseur / 2,
        size.width,
        centre.dy + epaisseur / 2,
      ),
      barre,
    );
  }

  @override
  bool shouldRepaint(_PeintreGoogle ancien) => false;
}
