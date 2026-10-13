import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/alerte.dart';
import '../../noyau/position_utilisateur.dart';
import '../../noyau/service_alertes.dart';
import '../../noyau/service_photo.dart';
import '../../partage/composants/apparence_alerte.dart';
import '../../partage/composants/bouton_rouge.dart';
import '../../partage/composants/choix_source_photo.dart';
import '../../partage/composants/entete_retour.dart';
import '../../partage/composants/vibrant.dart';
import '../../partage/styles.dart';

/// Onglet « + » : formulaire pour poster une urgence, un don ou un service.
class EcranPosterAlerte extends StatefulWidget {
  const EcranPosterAlerte({super.key, required this.auRetour});

  /// Appelé par la flèche retour, et après la publication (revient à l'accueil).
  final VoidCallback auRetour;

  @override
  State<EcranPosterAlerte> createState() => _EcranPosterAlerteState();
}

class _EcranPosterAlerteState extends State<EcranPosterAlerte> {
  final TextEditingController _description = TextEditingController();
  final GlobalKey<VibrantState> _cleDescription = GlobalKey();

  TypeAlerte _type = TypeAlerte.urgence;
  late String _categorie = CategoriesAlerte.parType[_type]!.first;
  Uint8List? _photo;
  bool _enCours = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _afficherMessage(String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texte)));
  }

  /// Change de type : la catégorie revient à la première du nouveau type.
  void _choisirType(TypeAlerte type) {
    setState(() {
      _type = type;
      _categorie = CategoriesAlerte.parType[type]!.first;
    });
  }

  Future<void> _choisirPhoto() async {
    final source = await choisirSourcePhoto(
      context,
      titre: "Photo de l'alerte",
    );
    if (source == null || !mounted) return;
    try {
      final octets = await context.read<ServicePhoto>().choisir(
        source,
        forme: FormePhoto.paysage,
      );
      if (octets != null && mounted) setState(() => _photo = octets);
    } on ErreurPhoto catch (e) {
      if (mounted) _afficherMessage(e.message);
    }
  }

  /// Vérifie le formulaire, puis enregistre l'alerte avec la vraie position.
  Future<void> _publier() async {
    // Description vide : la zone vibre et clignote, sans message.
    if (_description.text.trim().isEmpty) {
      _cleDescription.currentState?.signalerErreur();
      return;
    }

    final alertes = context.read<ServiceAlertes>();
    final position = context.read<PositionUtilisateur>();
    setState(() => _enCours = true);
    try {
      if (position.lieu == null) await position.actualiser();
      final lieu = position.lieu;
      if (lieu == null) {
        if (mounted) {
          _afficherMessage(
            'Activez la localisation pour publier une alerte près de chez vous.',
          );
        }
        return;
      }

      await alertes.publier(
        type: _type,
        categorie: _categorie,
        description: _description.text,
        ville: lieu.ville,
        quartier: lieu.quartier,
        latitude: lieu.latitude,
        longitude: lieu.longitude,
        photo: _photo,
      );
      if (!mounted) return;
      _description.clear();
      setState(() {
        _photo = null;
        _type = TypeAlerte.urgence;
        _categorie = CategoriesAlerte.parType[_type]!.first;
      });
      _afficherMessage('Alerte publiée.');
      widget.auRetour();
    } on ErreurAlerte catch (e) {
      if (mounted) _afficherMessage(e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = context.watch<PositionUtilisateur>();
    final lieu = position.lieu;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EnteteRetour(
              titre: 'Poster une alerte',
              auRetour: widget.auRetour,
              tailleTitre: 16.5,
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                for (final type in TypeAlerte.values) ...[
                  if (type != TypeAlerte.urgence) const SizedBox(width: 10),
                  Expanded(
                    child: _TuileType(
                      couleur: switch (type) {
                        TypeAlerte.urgence => Couleurs.rouge,
                        TypeAlerte.don => Couleurs.vert,
                        TypeAlerte.service => Couleurs.bleu,
                      },
                      icone: switch (type) {
                        TypeAlerte.urgence => type.icone(taille: 36),
                        TypeAlerte.don => const Icon(
                          Icons.volunteer_activism_outlined,
                          size: 36,
                          color: Colors.white,
                        ),
                        TypeAlerte.service => const Icon(
                          Icons.room_service_outlined,
                          size: 36,
                          color: Colors.white,
                        ),
                      },
                      libelle: type.libelle,
                      choisie: type == _type,
                      auAppui: () => _choisirType(type),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 22),
            const _Titre('Catégorie'),
            const SizedBox(height: 8),
            _ChampCategorie(
              icone: _type == TypeAlerte.urgence
                  ? _type.icone(taille: 22)
                  : Icon(
                      _type == TypeAlerte.don
                          ? Icons.volunteer_activism_outlined
                          : Icons.room_service_outlined,
                      size: 22,
                      color: Colors.black,
                    ),
              valeur: _categorie,
              choix: CategoriesAlerte.parType[_type]!,
              auChangement: (c) => setState(() => _categorie = c),
            ),
            const SizedBox(height: 18),
            const _Titre('Description'),
            const SizedBox(height: 8),
            Vibrant(
              key: _cleDescription,
              child: _ChampDescription(controleur: _description),
            ),
            const SizedBox(height: 18),
            const _Titre('Localisation'),
            const SizedBox(height: 8),
            _ChampPosition(
              detail: lieu != null
                  ? lieu.libelle
                  : position.enRecherche
                  ? 'Recherche de votre position...'
                  : 'Position introuvable : appuyez pour réessayer',
              auAppui: position.enRecherche ? null : position.actualiser,
            ),
            const SizedBox(height: 22),
            _BoutonPhoto(
              photo: _photo,
              auAppui: _choisirPhoto,
              auRetrait: () => setState(() => _photo = null),
            ),
            const SizedBox(height: 26),
            BoutonRouge(
              libelle: "Publier l'alerte",
              enCours: _enCours,
              auAppui: _publier,
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

/// Tuile de type (Urgence, Dons, Services). La tuile choisie est en pleine
/// couleur, les autres sont atténuées.
class _TuileType extends StatelessWidget {
  const _TuileType({
    required this.couleur,
    required this.icone,
    required this.libelle,
    required this.choisie,
    required this.auAppui,
  });

  final Color couleur;
  final Widget icone;
  final String libelle;
  final bool choisie;
  final VoidCallback auAppui;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: choisie,
      label: libelle,
      child: GestureDetector(
        onTap: auAppui,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: choisie ? 1 : 0.45,
          child: Container(
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
          ),
        ),
      ),
    );
  }
}

/// Liste déroulante des catégories, dans un champ blanc arrondi.
class _ChampCategorie extends StatelessWidget {
  const _ChampCategorie({
    required this.icone,
    required this.valeur,
    required this.choix,
    required this.auChangement,
  });

  final Widget icone;
  final String valeur;
  final List<String> choix;
  final ValueChanged<String> auChangement;

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
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: valeur,
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(14),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 28,
                  color: Colors.black,
                ),
                style: Styles.gras(12.5, Colors.black),
                items: [
                  for (final c in choix)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (c) {
                  if (c != null) auChangement(c);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Champ qui montre la position actuelle : un titre et, dessous, le lieu
/// trouvé. Un appui cherche la position de nouveau.
class _ChampPosition extends StatelessWidget {
  const _ChampPosition({required this.detail, required this.auAppui});

  final String detail;
  final VoidCallback? auAppui;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: auAppui,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Couleurs.grisBordure),
          boxShadow: Styles.ombre,
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 26,
              child: Center(
                child: Icon(
                  Icons.location_on_outlined,
                  size: 22,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ma position actuelle',
                    style: Styles.gras(12.5, Colors.black),
                  ),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Styles.gras(10.5, Couleurs.grisTexte),
                  ),
                ],
              ),
            ),
            const Icon(Icons.my_location, size: 22, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

class _ChampDescription extends StatelessWidget {
  const _ChampDescription({required this.controleur});

  final TextEditingController controleur;

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
        controller: controleur,
        maxLines: null,
        maxLength: 500,
        buildCounter: (
          _, {
          required currentLength,
          required isFocused,
          maxLength,
        }) => null,
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

/// Zone photo : tant qu'il n'y a pas de photo, le bouton « Ajouter une photo
/// (optionnelle) ». Ensuite, un grand aperçu de la photo telle qu'elle sera
/// publiée (coupée autour de son centre), avec de quoi la changer ou la retirer.
class _BoutonPhoto extends StatelessWidget {
  const _BoutonPhoto({
    required this.photo,
    required this.auAppui,
    required this.auRetrait,
  });

  final Uint8List? photo;
  final VoidCallback auAppui;
  final VoidCallback auRetrait;

  @override
  Widget build(BuildContext context) {
    if (photo != null) {
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: Styles.ombre,
        ),
        child: Stack(
          children: [
            PhotoAlerte(photo: photo, ratio: 2),
            // Retirer la photo.
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: auRetrait,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 22, color: Colors.black),
                ),
              ),
            ),
            // Changer la photo.
            Positioned(
              left: 8,
              bottom: 8,
              child: GestureDetector(
                onTap: auAppui,
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_camera,
                        size: 18,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Changer la photo',
                        style: Styles.gras(12, Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: auAppui,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Couleurs.grisBordure),
          boxShadow: Styles.ombre,
        ),
        child: Row(
          children: [
            const Icon(Icons.photo_camera, size: 24, color: Colors.black),
            const SizedBox(width: 22),
            Expanded(
              child: Text(
                'Ajouter une photo (optionnelle)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Styles.gras(13.5, Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
