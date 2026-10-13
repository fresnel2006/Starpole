import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/alerte_en_cours.dart';
import '../../partage/composants/avatar_personne.dart';
import '../../partage/composants/entete_retour.dart';
import '../../partage/composants/puce.dart';
import '../../partage/styles.dart';
import 'ecran_suivi_alerte.dart';

/// Détails d'une alerte : description, photo, lieu, et les boutons d'aide.
class EcranDetailsAlerte extends StatelessWidget {
  const EcranDetailsAlerte({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EnteteRetour(
                titre: "Details de l'alerte",
                tailleTitre: 18.5,
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Couleurs.rouge,
                        shape: BoxShape.circle,
                        boxShadow: Styles.ombre,
                      ),
                      child: const Icon(
                        Icons.volunteer_activism,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personne en detresse',
                            style: Styles.gras(19.4, Couleurs.rouge),
                          ),
                          const SizedBox(height: 4),
                          const Puce(
                            texte: 'Urgent',
                            fond: Couleurs.fondPuceRouge,
                            couleurTexte: Couleurs.rouge,
                            taille: 10.5,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 58),
                child: Text(
                  'Une personne agée est perdu a Treichville, pres du marché. '
                  'Elle semble desorienté et est muette',
                  style: Styles.gras(15.5, Colors.black, hauteur: 1.5),
                ),
              ),
              const SizedBox(height: 18),
              const _PhotoAlerte(),
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    _LigneInfo(
                      icone: Icons.location_on,
                      texte: 'Treichville, Abidjan',
                    ),
                    SizedBox(height: 14),
                    _LigneInfo(
                      icone: Icons.schedule,
                      texte: "il y'a 15 minutes",
                    ),
                    SizedBox(height: 14),
                    _LigneInfo(icone: Icons.gps_fixed, texte: '2.3 km'),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _BoutonAction(
                libelle: 'Je peux aider',
                icone: Icons.handshake_outlined,
                fond: Couleurs.vert,
                couleurTexte: Colors.white,
                auAppui: () {
                  // L'alerte est acceptée : le bandeau « Alerte en cours »
                  // s'affiche ensuite sur tous les onglets.
                  context.read<AlerteEnCoursNotifier>().accepter(
                    const AlerteEnCours(
                      titre: 'Personne en detresse',
                      lieu: 'Treichville',
                    ),
                  );
                  // On passe directement au détail de l'alerte acceptée.
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const EcranSuiviAlerte(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              const _BoutonAction(
                libelle: 'Partager',
                icone: Icons.share,
                fond: Colors.white,
                couleurTexte: Couleurs.vert,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const AvatarPersonne(
                    taille: 52,
                    couleurFond: Color(0xFFBDBDBD),
                    avecOmbre: true,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signalé par',
                        style: Styles.gras(
                          15,
                          Couleurs.grisTexte,
                          poids: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Kouadio Eliezer',
                        style: Styles.gras(15.1, Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Emplacement de la photo de l'alerte (la photo sera ajoutée plus tard).
class _PhotoAlerte extends StatelessWidget {
  const _PhotoAlerte();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 138,
      decoration: BoxDecoration(
        color: const Color(0xFFD8D2CC),
        borderRadius: BorderRadius.circular(12),
        boxShadow: Styles.ombre,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, size: 44, color: Colors.white),
    );
  }
}

class _LigneInfo extends StatelessWidget {
  const _LigneInfo({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 22, color: Colors.black),
        const SizedBox(width: 12),
        Text(texte, style: Styles.gras(14.7, Couleurs.grisTexte)),
      ],
    );
  }
}

/// Bouton large avec un texte centré et une icône à droite.
class _BoutonAction extends StatelessWidget {
  const _BoutonAction({
    required this.libelle,
    required this.icone,
    required this.fond,
    required this.couleurTexte,
    this.auAppui,
  });

  final String libelle;
  final IconData icone;
  final Color fond;
  final Color couleurTexte;
  final VoidCallback? auAppui;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: libelle,
      child: GestureDetector(
        onTap: auAppui,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: fond,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Couleurs.grisBordure),
            boxShadow: Styles.ombre,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(libelle, style: Styles.gras(18.5, couleurTexte)),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(icone, size: 24, color: couleurTexte),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
