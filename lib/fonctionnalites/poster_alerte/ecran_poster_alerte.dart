import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/alerte.dart';
import '../../noyau/position_utilisateur.dart';
import '../../noyau/service_alertes.dart';
import '../../noyau/service_localisation.dart';
import '../../noyau/service_photo.dart';
import '../../partage/composants/apparence_alerte.dart';
import '../../partage/composants/bouton_rouge.dart';
import '../../partage/composants/puce.dart';
import '../../partage/composants/vibrant.dart';
import '../../partage/composants/couche_tuiles.dart';
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
  final TextEditingController _titre = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final GlobalKey<VibrantState> _cleTitre = GlobalKey();
  final GlobalKey<VibrantState> _cleDescription = GlobalKey();
  final GlobalKey<VibrantState> _clePhoto = GlobalKey();

  TypeAlerte _type = TypeAlerte.urgence;
  Uint8List? _photo;
  bool _enCours = false;

  @override
  void dispose() {
    _titre.dispose();
    _description.dispose();
    super.dispose();
  }

  void _afficherMessage(String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texte)));
  }

  Future<void> _choisirPhoto() async {
    try {
      final octets = await context.read<ServicePhoto>().choisir(
        forme: FormePhoto.paysage,
      );
      if (octets != null && mounted) setState(() => _photo = octets);
    } on ErreurPhoto catch (e) {
      if (mounted) _afficherMessage(e.message);
    }
  }

  /// Vérifie le formulaire, puis enregistre l'alerte avec la vraie position.
  Future<void> _publier() async {
    // Titre, description ou photo manquants : la zone vibre et clignote, sans
    // message. La photo est obligatoire pour publier une alerte.
    final titreVide = _titre.text.trim().isEmpty;
    final descriptionVide = _description.text.trim().isEmpty;
    final photoAbsente = _photo == null;
    if (titreVide || descriptionVide || photoAbsente) {
      if (titreVide) _cleTitre.currentState?.signalerErreur();
      if (descriptionVide) _cleDescription.currentState?.signalerErreur();
      if (photoAbsente) _clePhoto.currentState?.signalerErreur();
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
        // Le titre donné par la personne sert de titre à l'alerte.
        categorie: _titre.text.trim(),
        description: _description.text,
        ville: lieu.ville,
        quartier: lieu.quartier,
        latitude: lieu.latitude,
        longitude: lieu.longitude,
        photo: _photo,
      );
      if (!mounted) return;
      _titre.clear();
      _description.clear();
      setState(() {
        _photo = null;
        _type = TypeAlerte.urgence;
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
    final largeur = MediaQuery.sizeOf(context).width;
    final position = context.watch<PositionUtilisateur>();

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : pastille, flèche et titre, texte, et la carte de la
            // Côte d'Ivoire avec le mégaphone en haut à droite.
            Stack(
              children: [
                Positioned(
                  top: -4,
                  right: -26,
                  child: Image.asset(
                    'assets/images/carte_cote_d_ivoire.png',
                    width: largeur * 0.40,
                    fit: BoxFit.contain,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Puce(
                      texte: 'Nouvelle alerte',
                      fond: Couleurs.fondPuceRouge,
                      couleurTexte: Couleurs.rouge,
                      taille: 11,
                      ombre: true,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _BoutonRetour(auAppui: widget.auRetour),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              style: Styles.gras(21, Colors.black),
                              children: const [
                                TextSpan(text: 'Poster une '),
                                TextSpan(
                                  text: 'alerte',
                                  style: TextStyle(color: Couleurs.rouge),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: largeur * 0.74),
                      child: Text(
                        'Aidez votre communauté en signalant une situation '
                        'urgente, aide nécessaire ou un service utile',
                        style: Styles.gras(
                          14,
                          Couleurs.grisIndication,
                          hauteur: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                for (final type in TypeAlerte.values) ...[
                  if (type != TypeAlerte.urgence) const SizedBox(width: 12),
                  Expanded(
                    child: _TuileType(
                      couleur: switch (type) {
                        TypeAlerte.urgence => Couleurs.tuileUrgence,
                        TypeAlerte.don => Couleurs.tuileDon,
                        TypeAlerte.service => Couleurs.tuileService,
                      },
                      icone: _iconeType(type, 38),
                      libelle: type.libelle,
                      choisie: type == _type,
                      auAppui: () => setState(() => _type = type),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 22),
            // « Détails de l'alerte » : l'en-tête puis les champs.
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: switch (_type) {
                          TypeAlerte.urgence => Couleurs.rouge,
                          TypeAlerte.don => Couleurs.vert,
                          TypeAlerte.service => Couleurs.bleu,
                        },
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: _iconeType(_type, 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Détails de l'alerte",
                            style: Styles.gras(15.5, Colors.black),
                          ),
                          Text(
                            'Décrivez la situation en quelques phrases '
                            'simples',
                            style: Styles.gras(
                              11.5,
                              Couleurs.grisTexte,
                              poids: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Vibrant(
                  key: _cleTitre,
                  child: _ChampTitre(controleur: _titre),
                ),
                const SizedBox(height: 14),
                Vibrant(
                  key: _cleDescription,
                  child: _ChampDescription(controleur: _description),
                ),
                const SizedBox(height: 14),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _CartePosition(
                          lieu: position.lieu,
                          enRecherche: position.enRecherche,
                          auAppui: position.enRecherche
                              ? null
                              : position.actualiser,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Vibrant(
                          key: _clePhoto,
                          rayon: 10,
                          child: _CartePhoto(
                            photo: _photo,
                            auAppui: _choisirPhoto,
                            auRetrait: () => setState(() => _photo = null),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                BoutonRouge(
                  libelle: "Publier l'alerte",
                  enCours: _enCours,
                  auAppui: _publier,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// L'icône blanche d'un type d'alerte.
  Widget _iconeType(TypeAlerte type, double taille) {
    return switch (type) {
      TypeAlerte.urgence => type.icone(taille: taille),
      TypeAlerte.don => Icon(
        Icons.volunteer_activism_outlined,
        size: taille,
        color: Colors.white,
      ),
      TypeAlerte.service => Icon(
        Icons.room_service_outlined,
        size: taille,
        color: Colors.white,
      ),
    };
  }
}

/// Bouton rond blanc avec la flèche retour.
class _BoutonRetour extends StatelessWidget {
  const _BoutonRetour({required this.auAppui});

  final VoidCallback auAppui;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Retour',
      child: GestureDetector(
        onTap: auAppui,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Couleurs.grisBordure),
            boxShadow: Styles.ombre,
          ),
          child: const Icon(Icons.chevron_left, size: 28, color: Colors.black),
        ),
      ),
    );
  }
}

/// Tuile de type (Urgence, Dons, Services). La tuile choisie est cerclée de
/// blanc et ombrée de sa couleur.
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 104,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: couleur,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: choisie ? Colors.white : Colors.transparent,
              width: 3,
            ),
            boxShadow: choisie
                ? [
                    BoxShadow(
                      color: couleur.withValues(alpha: 0.55),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : Styles.ombre,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              icone,
              Text(libelle, style: Styles.gras(13, Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Champ blanc arrondi du formulaire (ombre légère, bord gris).
BoxDecoration _decorationChamp(double rayon) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(rayon),
  border: Border.all(color: Couleurs.grisBordure),
  boxShadow: Styles.ombre,
);

class _ChampTitre extends StatelessWidget {
  const _ChampTitre({required this.controleur});

  final TextEditingController controleur;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _decorationChamp(10),
      child: Row(
        children: [
          Text('#', style: Styles.gras(16, Colors.black)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controleur,
              maxLength: 50,
              buildCounter: (
                _, {
                required currentLength,
                required isFocused,
                maxLength,
              }) => null,
              style: Styles.gras(12.5, Colors.black),
              decoration: InputDecoration(
                hintText: "Donner un titre à l'alerte",
                hintStyle: Styles.gras(12, Couleurs.grisIndication),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
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
      height: 124,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: _decorationChamp(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.draw, size: 22, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                hintText:
                    "Décrivez la situation, ce qui s'est passé, ce dont vous "
                    'avez besoin ...',
                hintStyle: Styles.gras(12, Couleurs.grisIndication),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Petite carte blanche du bas du formulaire : une icône, un titre, une ligne
/// d'explication et, en dessous, un contenu au format 2 pour 1.
class _CartePetite extends StatelessWidget {
  const _CartePetite({
    required this.icone,
    required this.titre,
    required this.detail,
    required this.contenu,
  });

  final IconData icone;
  final String titre;
  final String detail;
  final Widget contenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _decorationChamp(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 20, color: Couleurs.grisTexte),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Le titre rétrécit un peu au lieu d'être coupé.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        titre,
                        style: Styles.gras(11.5, Colors.black),
                      ),
                    ),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Styles.gras(
                        9.5,
                        Couleurs.grisTexte,
                        poids: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AspectRatio(aspectRatio: 2, child: contenu),
        ],
      ),
    );
  }
}

/// « Localisation » : la vraie position, sur une petite carte. Un appui
/// cherche la position de nouveau.
class _CartePosition extends StatelessWidget {
  const _CartePosition({
    required this.lieu,
    required this.enRecherche,
    required this.auAppui,
  });

  final LieuActuel? lieu;
  final bool enRecherche;
  final VoidCallback? auAppui;

  @override
  Widget build(BuildContext context) {
    final latitude = lieu?.latitude;
    final longitude = lieu?.longitude;
    final Widget carte;
    if (latitude != null && longitude != null) {
      final point = LatLng(latitude, longitude);
      carte = IgnorePointer(
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            tuilesCarte(context),
            mentionCarte(petite: true),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Couleurs.rouge.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Icon(
                        Icons.location_on,
                        size: 30,
                        color: Couleurs.rouge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      carte = Container(
        color: Couleurs.grisFond,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(6),
        child: Text(
          enRecherche
              ? 'Recherche de votre position...'
              : 'Position introuvable. Appuyez pour réessayer.',
          textAlign: TextAlign.center,
          style: Styles.gras(9.5, Couleurs.grisTexte, poids: FontWeight.w500),
        ),
      );
    }

    return GestureDetector(
      onTap: auAppui,
      child: _CartePetite(
        icone: Icons.location_on_outlined,
        titre: 'Localisation',
        detail: lieu != null ? lieu!.libelle : 'Ma localisation actuelle',
        contenu: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: carte,
        ),
      ),
    );
  }
}

/// « Ajouter une photo » : une zone en pointillés, qui devient l'aperçu de la
/// photo telle qu'elle sera publiée (coupée en 2 pour 1 autour de son centre).
class _CartePhoto extends StatelessWidget {
  const _CartePhoto({
    required this.photo,
    required this.auAppui,
    required this.auRetrait,
  });

  final Uint8List? photo;
  final VoidCallback auAppui;
  final VoidCallback auRetrait;

  @override
  Widget build(BuildContext context) {
    final Widget contenu;
    if (photo != null) {
      contenu = ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              photo!,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              gaplessPlayback: true,
            ),
            // Retirer la photo.
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: auRetrait,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      contenu = CustomPaint(
        painter: _BordureTiretee(),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image_outlined, size: 22, color: Colors.black),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  'Appuyer pour prendre une photo',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Styles.gras(
                    8.5,
                    Couleurs.grisTexte,
                    poids: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: auAppui,
      child: _CartePetite(
        icone: Icons.photo_camera_outlined,
        titre: 'Ajouter une photo',
        detail: 'Prenez une photo',
        contenu: contenu,
      ),
    );
  }
}

/// Contour en pointillés arrondi de la zone photo.
class _BordureTiretee extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final trait = Paint()
      ..color = Couleurs.grisIndication
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final forme = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)),
      );
    for (final mesure in forme.computeMetrics()) {
      var debut = 0.0;
      while (debut < mesure.length) {
        canvas.drawPath(mesure.extractPath(debut, debut + 4), trait);
        debut += 7;
      }
    }
  }

  @override
  bool shouldRepaint(_BordureTiretee ancien) => false;
}
