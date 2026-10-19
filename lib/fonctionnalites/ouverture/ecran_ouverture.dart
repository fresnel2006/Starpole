import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/couleurs.dart';

/// Fond blanc de l'ouverture, comme le reste de l'appli.
const Color fondOuverture = Colors.white;

/// Animation d'ouverture : l'étoile StarPole se dessine branche par branche en
/// tournant, s'illumine et envoie deux ondes, puis le nom apparaît lettre par
/// lettre avec la signature. Ensuite, [suivant] s'affiche en fondu. Un appui
/// passe directement à la suite.
class EcranOuverture extends StatefulWidget {
  const EcranOuverture({super.key, required this.suivant});

  /// L'écran à montrer après l'animation (bienvenue ou accueil).
  final Widget suivant;

  @override
  State<EcranOuverture> createState() => _EcranOuvertureState();
}

class _EcranOuvertureState extends State<EcranOuverture>
    with SingleTickerProviderStateMixin {
  late final AnimationController _temps = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );
  bool _parti = false;

  @override
  void initState() {
    super.initState();
    _temps.forward().whenComplete(_continuer);
  }

  @override
  void dispose() {
    _temps.dispose();
    super.dispose();
  }

  void _continuer() {
    if (_parti || !mounted) return;
    _parti = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, _, _) => widget.suivant,
        transitionsBuilder: (_, animation, _, enfant) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: enfant,
        ),
      ),
    );
  }

  /// La progression (0 à 1) d'une étape qui va de [debut] à [fin] sur la durée
  /// totale, avec sa courbe.
  double _etape(
    double debut,
    double fin, [
    Curve courbe = Curves.easeOutCubic,
  ]) {
    final t = ((_temps.value - debut) / (fin - debut)).clamp(0.0, 1.0);
    return courbe.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: fondOuverture,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _continuer,
          child: AnimatedBuilder(
            animation: _temps,
            // Toute la scène occupe l'écran, centrée.
            builder: (context, _) => SizedBox.expand(child: _scene()),
          ),
        ),
      ),
    );
  }

  Widget _scene() {
    // L'étoile monte et rapetisse un peu pour laisser place au nom.
    final montee = _etape(0.42, 0.64, Curves.easeInOutCubic);
    final nom = 'StarPole';

    return Stack(
      alignment: Alignment.center,
      children: [
        // Halo rouge très doux qui respire derrière tout.
        Positioned.fill(
          child: CustomPaint(
            painter: _PeintreFond(lueur: _etape(0.22, 0.6), montee: montee),
          ),
        ),
        Transform.translate(
          offset: Offset(0, -64 * montee),
          child: Transform.scale(
            scale: 1 - 0.22 * montee,
            child: SizedBox(
              width: 190,
              height: 190,
              child: CustomPaint(
                painter: _PeintreEtoile(
                  branches: [
                    for (var i = 0; i < 4; i++)
                      _etape(0.02 + i * 0.045, 0.30 + i * 0.045),
                  ],
                  diagonales: [
                    for (var i = 0; i < 4; i++)
                      _etape(
                        0.18 + i * 0.035,
                        0.42 + i * 0.035,
                        Curves.easeOutBack,
                      ),
                  ],
                  rotation: -math.pi / 2 * (1 - _etape(0.0, 0.46)),
                  ondes: [_etape(0.3, 0.78), _etape(0.4, 0.9)],
                  eclat:
                      _etape(0.3, 0.5, Curves.easeOut) -
                      _etape(0.5, 0.7, Curves.easeIn) * 0.6,
                ),
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, 86),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Le nom, lettre par lettre : « Star » en noir, « Pole » en rouge.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < nom.length; i++)
                    _Lettre(
                      lettre: nom[i],
                      couleur: i < 4 ? Colors.black : Couleurs.rouge,
                      progression: _etape(0.5 + i * 0.022, 0.68 + i * 0.022),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Fin trait rouge qui s'étire sous le nom.
              Container(
                width: 64 * _etape(0.66, 0.82, Curves.easeInOutCubic),
                height: 2.5,
                decoration: BoxDecoration(
                  color: Couleurs.rouge,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Opacity(
                opacity: _etape(0.72, 0.88),
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - _etape(0.72, 0.88))),
                  child: const Text(
                    'Une étoile pour ne jamais rester seul.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Couleurs.grisTexte,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Une lettre du nom, qui monte en apparaissant.
class _Lettre extends StatelessWidget {
  const _Lettre({
    required this.lettre,
    required this.couleur,
    required this.progression,
  });

  final String lettre;
  final Color couleur;
  final double progression;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progression,
      child: Transform.translate(
        offset: Offset(0, 26 * (1 - progression)),
        child: Text(
          lettre,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 42,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            height: 1.1,
            color: couleur,
          ),
        ),
      ),
    );
  }
}

/// Le fond : un halo rouge diffus au centre, qui suit l'étoile.
class _PeintreFond extends CustomPainter {
  const _PeintreFond({required this.lueur, required this.montee});

  final double lueur;
  final double montee;

  @override
  void paint(Canvas canvas, Size size) {
    if (lueur <= 0) return;
    final centre = size.center(Offset(0, -64 * montee));
    final rayon = size.shortestSide * 0.75;
    final peinture = Paint()
      ..shader = RadialGradient(
        colors: [
          Couleurs.rouge.withValues(alpha: 0.10 * lueur),
          Couleurs.rouge.withValues(alpha: 0.03 * lueur),
          fondOuverture.withValues(alpha: 0),
        ],
        stops: const [0, 0.45, 1],
      ).createShader(Rect.fromCircle(center: centre, radius: rayon));
    canvas.drawCircle(centre, rayon, peinture);
  }

  @override
  bool shouldRepaint(_PeintreFond ancien) =>
      ancien.lueur != lueur || ancien.montee != montee;
}

/// L'étoile StarPole dessinée en code : quatre grandes branches et quatre
/// petites en diagonale, chacune « poussant » depuis le centre.
class _PeintreEtoile extends CustomPainter {
  const _PeintreEtoile({
    required this.branches,
    required this.diagonales,
    required this.rotation,
    required this.ondes,
    required this.eclat,
  });

  /// Croissance (0 à 1) des branches haut, droite, bas, gauche.
  final List<double> branches;

  /// Croissance des quatre petites branches en diagonale.
  final List<double> diagonales;
  final double rotation;

  /// Avancée des deux ondes qui partent de l'étoile.
  final List<double> ondes;

  /// Intensité de la lueur autour de l'étoile.
  final double eclat;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // Ondes : deux anneaux fins qui s'élargissent et s'effacent.
    for (final onde in ondes) {
      if (onde <= 0 || onde >= 1) continue;
      canvas.drawCircle(
        centre,
        r * (0.35 + onde * 1.25),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 * (1 - onde) + 0.4
          ..color = Couleurs.rouge.withValues(alpha: 0.55 * (1 - onde)),
      );
    }

    // Lueur derrière l'étoile.
    if (eclat > 0) {
      canvas.drawCircle(
        centre,
        r * 0.55,
        Paint()
          ..color = Couleurs.rouge.withValues(alpha: 0.22 * eclat)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34),
      );
    }

    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(rotation);

    // Dégradé rouge clair vers rouge foncé sur toute l'étoile.
    final degrade = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF2A30), Couleurs.rouge, Color(0xFFB00000)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

    // Les quatre grandes branches (les horizontales sont un peu plus courtes).
    for (var i = 0; i < 4; i++) {
      final longueur = i.isEven ? 1.0 : 0.88;
      _branche(
        canvas,
        degrade,
        angle: i * math.pi / 2,
        croissance: branches[i],
        r: r,
        interieur: 0.04,
        milieu: 0.40 * longueur,
        largeur: 0.11,
        pointe: longueur,
      );
    }
    // Les quatre petites branches en diagonale.
    for (var i = 0; i < 4; i++) {
      _branche(
        canvas,
        degrade,
        angle: math.pi / 4 + i * math.pi / 2,
        croissance: diagonales[i],
        r: r,
        interieur: 0.08,
        milieu: 0.26,
        largeur: 0.065,
        pointe: 0.54,
      );
    }
    canvas.restore();
  }

  /// Une branche en losange pointée vers le haut, tournée de [angle], dont la
  /// taille est multipliée par [croissance] depuis le centre.
  void _branche(
    Canvas canvas,
    Paint peinture, {
    required double angle,
    required double croissance,
    required double r,
    required double interieur,
    required double milieu,
    required double largeur,
    required double pointe,
  }) {
    if (croissance <= 0) return;
    final g = croissance * r;
    final chemin = Path()
      ..moveTo(0, -interieur * g)
      ..lineTo(-largeur * g, -milieu * g)
      ..lineTo(0, -pointe * g)
      ..lineTo(largeur * g, -milieu * g)
      ..close();
    canvas.save();
    canvas.rotate(angle);
    canvas.drawPath(chemin, peinture);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PeintreEtoile ancien) => true;
}
