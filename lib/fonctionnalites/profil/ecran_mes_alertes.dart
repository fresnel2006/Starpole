import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/alerte.dart';
import '../../noyau/format_temps.dart';
import '../../noyau/position_utilisateur.dart';
import '../../noyau/service_alertes.dart';
import '../../partage/composants/apparence_alerte.dart';
import '../../partage/composants/champ_recherche.dart';
import '../../partage/composants/entete_retour.dart';
import '../../partage/composants/ligne_alerte.dart';
import '../../partage/composants/puce.dart';
import '../../partage/styles.dart';
import '../alertes/ecran_suivi_alerte.dart';

/// Mes alertes, aides et dons : celles que j'ai publiées et celles que j'aide,
/// avec leur statut. La liste est en direct.
class EcranMesAlertes extends StatefulWidget {
  const EcranMesAlertes({super.key});

  @override
  State<EcranMesAlertes> createState() => _EcranMesAlertesState();
}

class _EcranMesAlertesState extends State<EcranMesAlertes> {
  late final Stream<List<Alerte>> _flux = context
      .read<ServiceAlertes>()
      .mesAlertes();
  String _recherche = '';

  bool _correspond(Alerte alerte) {
    final mot = _recherche.trim().toLowerCase();
    if (mot.isEmpty) return true;
    return alerte.categorie.toLowerCase().contains(mot) ||
        alerte.description.toLowerCase().contains(mot) ||
        alerte.lieu.toLowerCase().contains(mot);
  }

  @override
  Widget build(BuildContext context) {
    final lieu = context.watch<PositionUtilisateur>().lieu;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EnteteRetour(
                titre: 'Mes alertes, aides & dons',
                tailleTitre: 15.5,
              ),
              const SizedBox(height: 14),
              ChampRecherche(
                indication: 'Recherche ....',
                auChangement: (texte) => setState(() => _recherche = texte),
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: Couleurs.grisBordure),
              Expanded(
                child: StreamBuilder<List<Alerte>>(
                  stream: _flux,
                  builder: (context, instantane) {
                    if (instantane.hasError) {
                      return const _Message(
                        'Impossible de charger vos alertes. '
                        'Vérifiez votre connexion.',
                      );
                    }
                    final toutes = instantane.data;
                    if (toutes == null) {
                      return const Center(
                        child: CircularProgressIndicator(color: Couleurs.rouge),
                      );
                    }
                    final liste = toutes.where(_correspond).toList();
                    if (liste.isEmpty) {
                      return _Message(
                        toutes.isEmpty
                            ? "Vous n'avez encore aucune alerte."
                            : 'Aucun résultat pour cette recherche.',
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        for (final alerte in liste)
                          _Element(
                            alerte: alerte,
                            distance: alerte.distanceKm(
                              lieu?.latitude,
                              lieu?.longitude,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Une alerte de la liste : ligne cliquable, avec son statut, puis un trait.
class _Element extends StatelessWidget {
  const _Element({required this.alerte, required this.distance});

  final Alerte alerte;
  final double? distance;

  @override
  Widget build(BuildContext context) {
    final resolue = alerte.statut == StatutAlerte.resolue;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EcranSuiviAlerte(alerteId: alerte.id),
        ),
      ),
      child: Column(
        children: [
          LigneAlerte(
            couleur: alerte.type.couleur,
            icone: alerte.type.icone(taille: 26),
            titre: alerte.categorie,
            details: distance == null
                ? alerte.lieu
                : '${alerte.lieu} • ${libelleDistance(distance!)}',
            temps: tempsEcoule(alerte.creeLe),
            statut: Puce(
              texte: alerte.statut.libelle,
              fond: resolue ? Couleurs.fondPuceVerte : Couleurs.fondPuceOrange,
              couleurTexte: resolue ? Couleurs.vert : Couleurs.orange,
              taille: 10.5,
            ),
          ),
          Container(height: 1, color: Couleurs.grisBordure),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Text(
          texte,
          textAlign: TextAlign.center,
          style: Styles.gras(13, Couleurs.grisTexte, hauteur: 1.5),
        ),
      ),
    );
  }
}
