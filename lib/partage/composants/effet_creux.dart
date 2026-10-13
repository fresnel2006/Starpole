import 'package:flutter/material.dart';

/// Donne un effet « en creux » : un bord sombre à l'intérieur sur tout le
/// tour, un reflet clair en bas et une légère ombre sous le bouton.
class EffetCreux extends StatelessWidget {
  const EffetCreux({
    super.key,
    required this.child,
    required this.fond,
    this.rayon = 14,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final Color fond;
  final double rayon;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _PeintreCreux(rayon),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: fond,
          borderRadius: BorderRadius.circular(rayon),
          // Légère ombre sous le bouton, comme sur la maquette.
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _PeintreCreux extends CustomPainter {
  _PeintreCreux(this.rayon);

  final double rayon;

  @override
  void paint(Canvas canvas, Size size) {
    final zone = Offset.zero & size;
    final forme = RRect.fromRectAndRadius(zone, Radius.circular(rayon));

    // Tout ce qui est autour de la forme : on s'en sert pour faire
    // entrer l'ombre à l'intérieur.
    final autour = Path.combine(
      PathOperation.difference,
      Path()..addRect(zone.inflate(24)),
      Path()..addRRect(forme),
    );

    canvas.save();
    canvas.clipRRect(forme);

    // Bord légèrement sombre sur tout le tour.
    canvas.drawPath(
      autour,
      Paint()
        ..color = const Color(0x40000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // Ombre un peu plus marquée qui vient du haut.
    canvas.drawPath(
      autour.shift(const Offset(0, 2)),
      Paint()
        ..color = const Color(0x40000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // Reflet clair le long du bord du bas.
    canvas.drawPath(
      autour.shift(const Offset(0, -2)),
      Paint()
        ..color = const Color(0x99FFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_PeintreCreux ancien) => ancien.rayon != rayon;
}
