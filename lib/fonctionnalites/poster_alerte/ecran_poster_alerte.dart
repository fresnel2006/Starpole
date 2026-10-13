import 'package:flutter/material.dart';

import '../../application/couleurs.dart';
import '../../partage/composants/entete_retour.dart';
import '../../partage/composants/icone_sirene.dart';
import '../../partage/styles.dart';

/// Onglet « + » : formulaire pour poster une alerte, un don ou un service.
class EcranPosterAlerte extends StatelessWidget {
  const EcranPosterAlerte({super.key, required this.auRetour});

  /// Appelé par la flèche retour (revient à l'accueil).
  final VoidCallback auRetour;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EnteteRetour(
              titre: 'Poster une alerte',
              auRetour: auRetour,
              tailleTitre: 16.5,
            ),
            const SizedBox(height: 26),
            const Row(
              children: [
                Expanded(
                  child: _TuileType(
                    couleur: Couleurs.rouge,
                    icone: IconeSirene(taille: 36),
                    libelle: 'Urgence',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _TuileType(
                    couleur: Couleurs.vert,
                    icone: Icon(
                      Icons.volunteer_activism_outlined,
                      size: 36,
                      color: Colors.white,
                    ),
                    libelle: 'Dons',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _TuileType(
                    couleur: Couleurs.bleu,
                    icone: Icon(
                      Icons.room_service_outlined,
                      size: 36,
                      color: Colors.white,
                    ),
                    libelle: 'Services',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _Titre('Catégorie'),
            const SizedBox(height: 8),
            const _ChampListe(
              icone: IconeSirene(taille: 22, couleur: Colors.black),
              texte: 'Personne en detresse',
            ),
            const SizedBox(height: 18),
            const _Titre('Description'),
            const SizedBox(height: 8),
            const _ChampDescription(),
            const SizedBox(height: 18),
            const _Titre('Localisation'),
            const SizedBox(height: 8),
            const _ChampListe(
              icone: Icon(
                Icons.location_on_outlined,
                size: 22,
                color: Colors.black,
              ),
              texte: 'Ma position actuelle',
            ),
            const SizedBox(height: 22),
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: Couleurs.grisFond,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Couleurs.grisBordure),
                boxShadow: Styles.ombre,
              ),
              child: Row(
                children: [
                  const Icon(Icons.photo_camera, size: 24, color: Colors.black),
                  const SizedBox(width: 22),
                  Text(
                    'Ajouter une photo (optionnelle)',
                    style: Styles.gras(13.5, Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Titre extends StatelessWidget {
  const _Titre(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Text(texte, style: Styles.gras(17, Colors.black));
  }
}

class _TuileType extends StatelessWidget {
  const _TuileType({
    required this.couleur,
    required this.icone,
    required this.libelle,
  });

  final Color couleur;
  final Widget icone;
  final String libelle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: couleur,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Styles.ombre,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          icone,
          Text(libelle, style: Styles.gras(12.5, Colors.white)),
        ],
      ),
    );
  }
}

/// Champ blanc avec une icône, un texte et une petite flèche vers le bas.
class _ChampListe extends StatelessWidget {
  const _ChampListe({required this.icone, required this.texte});

  final Widget icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Couleurs.grisBordure),
        boxShadow: Styles.ombre,
      ),
      child: Row(
        children: [
          SizedBox(width: 26, child: Center(child: icone)),
          const SizedBox(width: 12),
          Expanded(child: Text(texte, style: Styles.gras(12.5, Colors.black))),
          const Icon(Icons.keyboard_arrow_down, size: 28, color: Colors.black),
        ],
      ),
    );
  }
}

class _ChampDescription extends StatelessWidget {
  const _ChampDescription();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Couleurs.grisBordure),
        boxShadow: Styles.ombre,
      ),
      child: TextField(
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: Styles.gras(12.5, Colors.black),
        decoration: InputDecoration(
          hintText: 'Decrivez la situation en queique phrase ...',
          hintStyle: Styles.gras(12, Couleurs.grisIndication),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}
