import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/alerte_en_cours.dart';
import '../../partage/composants/avatar_personne.dart';
import '../../partage/composants/entete_retour.dart';
import '../../partage/composants/icone_sirene.dart';
import '../../partage/composants/puce.dart';
import '../../partage/styles.dart';
import '../evaluation/ecran_noter_aidant.dart';

/// Détail d'une alerte en cours : auteur, description et déroulement.
class EcranSuiviAlerte extends StatelessWidget {
  const EcranSuiviAlerte({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const EnteteRetour(titre: "Detail de l'alerte"),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Couleurs.rouge,
                            shape: BoxShape.circle,
                            boxShadow: Styles.ombre,
                          ),
                          child: const IconeSirene(taille: 30),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Personne en detresse',
                                      style: Styles.gras(15, Couleurs.rouge),
                                    ),
                                  ),
                                  const Puce(
                                    texte: 'En cours',
                                    fond: Couleurs.fondPuceOrange,
                                    couleurTexte: Couleurs.orange,
                                    taille: 10,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Treichville • 1.2 km',
                                style: Styles.gras(11.5, Colors.black),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    size: 15,
                                    color: Couleurs.grisTexte,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "Reçu il y'a 15 min",
                                    style: Styles.gras(
                                      10.5,
                                      Couleurs.grisTexte,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(height: 1, color: Couleurs.grisBordure),
                    const SizedBox(height: 12),
                    Text(
                      'Temoin / auteur',
                      style: Styles.gras(
                        11.5,
                        Couleurs.grisTexte,
                        poids: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const AvatarPersonne(
                          taille: 52,
                          couleurFond: Color(0xFFBDBDBD),
                          avecOmbre: true,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Kouadio Eliezer',
                          style: Styles.gras(14.5, Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(height: 1, color: Couleurs.grisBordure),
                    const SizedBox(height: 14),
                    Text('Description', style: Styles.gras(14, Colors.black)),
                    const SizedBox(height: 8),
                    Text(
                      'Une personne agée est perdu a treichville, pres du '
                      'marché. Elle semble desorienté et est muette',
                      style: Styles.gras(
                        12.5,
                        Colors.black,
                        hauteur: 1.55,
                        poids: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Timeline', style: Styles.gras(14, Colors.black)),
                    const SizedBox(height: 12),
                    const _EtapeTimeline(
                      heure: '09:15',
                      texte: 'Alerte crée',
                      faite: true,
                    ),
                    const _EtapeTimeline(
                      heure: '09:40',
                      texte: 'Kouadio repond',
                      faite: true,
                    ),
                    const _EtapeTimeline(
                      heure: '09:50',
                      texte: 'Fresnel arrive sur place',
                      faite: true,
                    ),
                    const _EtapeTimeline(
                      heure: '',
                      texte: '-',
                      faite: false,
                      derniere: true,
                    ),
                  ],
                ),
              ),
            ),
            const _BasDePage(),
          ],
        ),
      ),
    );
  }
}

/// Une étape de la timeline : pastille verte cochée (ou rouge) et texte.
class _EtapeTimeline extends StatelessWidget {
  const _EtapeTimeline({
    required this.heure,
    required this.texte,
    required this.faite,
    this.derniere = false,
  });

  final String heure;
  final String texte;
  final bool faite;
  final bool derniere;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: derniere ? 0 : 14),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: faite ? Couleurs.vert : Couleurs.rouge,
              shape: BoxShape.circle,
            ),
            child: faite
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 14),
          if (heure.isNotEmpty)
            Text(heure, style: Styles.gras(13, Couleurs.grisTexte)),
          if (heure.isNotEmpty) const SizedBox(width: 12),
          Text(texte, style: Styles.gras(13, Couleurs.grisTexte)),
        ],
      ),
    );
  }
}

/// Termine l'alerte (le bandeau disparaît), puis ouvre « Noter l'aidant ».
/// C'est la même chose pour « Terminé » et « Stopper ». On remplace cet écran
/// par celui de la note : après « Envoyer », on revient où l'on était avant.
void _terminerEtNoter(BuildContext context) {
  context.read<AlerteEnCoursNotifier>().terminer();
  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(builder: (_) => const EcranNoterAidant()),
  );
}

/// Bas de page : champ de saisie et boutons Terminé / Stopper.
class _BasDePage extends StatelessWidget {
  const _BasDePage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Couleurs.grisBordure),
                    boxShadow: Styles.ombre,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sentiment_satisfied_alt,
                        size: 24,
                        color: Color(0xFFFFB300),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          style: Styles.gras(12, Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Decrivez la situation ...',
                            hintStyle: Styles.gras(
                              11.5,
                              Couleurs.grisIndication,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Couleurs.rouge,
                  shape: BoxShape.circle,
                  boxShadow: Styles.ombre,
                ),
                child: const Icon(Icons.send, size: 22, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: () => _terminerEtNoter(context),
                child: const Puce(
                  texte: 'Terminé',
                  fond: Couleurs.rouge,
                  couleurTexte: Colors.white,
                  taille: 11,
                  ombre: true,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => _terminerEtNoter(context),
                child: const Puce(
                  texte: 'Stopper',
                  fond: Colors.white,
                  couleurTexte: Couleurs.rouge,
                  taille: 11,
                  ombre: true,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
