import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/alerte.dart';
import '../../noyau/service_alertes.dart';
import '../../partage/composants/icone_sirene.dart';
import '../../partage/styles.dart';
import 'ecran_suivi_alerte.dart';

/// Bandeau rouge « Alerte en cours », affiché au-dessus de la barre de
/// navigation tant que l'utilisateur aide une alerte. Il vient de la base :
/// il revient donc aussi après avoir fermé puis rouvert l'appli.
/// Il n'affiche rien s'il n'y a pas d'alerte en cours.
class BandeauAlerteEnCours extends StatefulWidget {
  const BandeauAlerteEnCours({super.key});

  @override
  State<BandeauAlerteEnCours> createState() => _BandeauAlerteEnCoursState();
}

class _BandeauAlerteEnCoursState extends State<BandeauAlerteEnCours> {
  late final Stream<Alerte?> _flux = context
      .read<ServiceAlertes>()
      .alerteEnCours();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Alerte?>(
      stream: _flux,
      builder: (context, instantane) {
        final alerte = instantane.data;
        if (alerte == null) return const SizedBox.shrink();

        return Semantics(
          button: true,
          label: 'Alerte en cours : ${alerte.categorie}. Ouvrir le suivi.',
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => EcranSuiviAlerte(alerteId: alerte.id),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Couleurs.rouge,
                borderRadius: BorderRadius.circular(16),
                boxShadow: Styles.ombre,
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const IconeSirene(taille: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const _PointClignotant(),
                            const SizedBox(width: 6),
                            Text(
                              'Alerte en cours',
                              style: Styles.gras(12, Colors.white),
                            ),
                          ],
                        ),
                        Text(
                          '${alerte.categorie} • ${alerte.lieu}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Styles.gras(
                            11,
                            Colors.white,
                            poids: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text('Suivre', style: Styles.gras(12, Colors.white)),
                  const Icon(
                    Icons.chevron_right,
                    size: 22,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Petit point blanc qui clignote doucement pour montrer que c'est en direct.
class _PointClignotant extends StatefulWidget {
  const _PointClignotant();

  @override
  State<_PointClignotant> createState() => _PointClignotantState();
}

class _PointClignotantState extends State<_PointClignotant>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.25, end: 1).animate(_animation),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
