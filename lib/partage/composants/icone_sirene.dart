import 'package:flutter/material.dart';

/// Icône de sirène d'urgence (dôme, socle et trois rayons).
class IconeSirene extends StatelessWidget {
  const IconeSirene({super.key, this.taille = 28, this.couleur = Colors.white});

  final double taille;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(taille),
      painter: _PeintreSirene(couleur),
    );
  }
}

class _PeintreSirene extends CustomPainter {
  _PeintreSirene(this.couleur);

  final Color couleur;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final plein = Paint()..color = couleur;
    final trait = Paint()
      ..color = couleur
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.07
      ..strokeCap = StrokeCap.round;

    // Dôme.
    final dome = Path()
      ..moveTo(s * 0.22, s * 0.74)
      ..arcToPoint(
        Offset(s * 0.78, s * 0.74),
        radius: Radius.circular(s * 0.28),
      )
      ..close();
    canvas.drawPath(dome, plein);

    // Socle.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.12, s * 0.78, s * 0.76, s * 0.13),
        Radius.circular(s * 0.04),
      ),
      plein,
    );

    // Rayons.
    canvas.drawLine(
      Offset(s * 0.5, s * 0.06),
      Offset(s * 0.5, s * 0.16),
      trait,
    );
    canvas.drawLine(
      Offset(s * 0.14, s * 0.2),
      Offset(s * 0.22, s * 0.28),
      trait,
    );
    canvas.drawLine(
      Offset(s * 0.86, s * 0.2),
      Offset(s * 0.78, s * 0.28),
      trait,
    );
  }

  @override
  bool shouldRepaint(_PeintreSirene ancien) => ancien.couleur != couleur;
}
