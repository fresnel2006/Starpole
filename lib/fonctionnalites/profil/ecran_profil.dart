import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/alerte.dart';
import '../../noyau/service_alertes.dart';
import '../../noyau/service_auth.dart';
import '../../noyau/service_photo.dart';
import '../../partage/composants/avatar_personne.dart';
import '../../partage/composants/choix_source_photo.dart';
import '../../partage/styles.dart';
import 'ecran_mes_alertes.dart';

/// Onglet Profil : photo, nom, statistiques et menu.
class EcranProfil extends StatefulWidget {
  const EcranProfil({super.key});

  @override
  State<EcranProfil> createState() => _EcranProfilState();
}

class _EcranProfilState extends State<EcranProfil> {
  late Future<ProfilUtilisateur?> _profil = context
      .read<ServiceAuth>()
      .chargerProfil();

  /// Les chiffres du profil (alertes publiées, aides, dons, note), lus en base.
  late final Future<StatistiquesProfil> _statistiques = context
      .read<ServiceAlertes>()
      .statistiques();

  /// Vrai pendant que la nouvelle photo est enregistrée.
  bool _envoiEnCours = false;

  void _afficherMessage(String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texte)));
  }

  /// Propose caméra ou galerie, puis enregistre la photo choisie.
  Future<void> _modifierPhoto() async {
    final source = await choisirSourcePhoto(context);
    if (source == null || !mounted) return;

    final photos = context.read<ServicePhoto>();
    final auth = context.read<ServiceAuth>();
    setState(() => _envoiEnCours = true);
    try {
      final octets = await photos.choisir(source);
      if (octets == null) return; // l'utilisateur a annulé
      await auth.changerPhoto(octets);
      if (!mounted) return;
      // On recharge le profil pour afficher la nouvelle photo.
      setState(() {
        _profil = auth.chargerProfil();
      });
    } on ErreurPhoto catch (e) {
      if (mounted) _afficherMessage(e.message);
    } on ErreurAuth catch (e) {
      if (mounted) _afficherMessage(e.message);
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.settings, size: 36, color: Colors.black),
                Expanded(
                  child: Center(
                    child: Text(
                      'Mon profil',
                      style: Styles.gras(23, Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
            const SizedBox(height: 30),
            // La photo vient du profil (la sienne, ou celle de son compte Google).
            FutureBuilder<ProfilUtilisateur?>(
              future: _profil,
              builder: (context, instantane) => _PhotoProfil(
                profil: instantane.data,
                enCours: _envoiEnCours,
                auAppui: _modifierPhoto,
              ),
            ),
            const SizedBox(height: 22),
            // Le nom vient du profil enregistré dans Firestore.
            FutureBuilder<ProfilUtilisateur?>(
              future: _profil,
              builder: (context, instantane) {
                final nom = instantane.data?.nom ?? '';
                return Text(
                  nom.isEmpty ? ' ' : nom,
                  textAlign: TextAlign.center,
                  style: Styles.gras(19, Colors.black),
                );
              },
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Couleurs.rouge,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text('Membre actif', style: Styles.gras(12.5, Couleurs.rouge)),
              ],
            ),
            const SizedBox(height: 4),
            FutureBuilder<StatistiquesProfil>(
              future: _statistiques,
              builder: (context, instantane) {
                final stats = instantane.data;
                final note = stats?.noteMoyenne;
                return Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 1; i <= 5; i++)
                          Icon(
                            Icons.star,
                            size: 20,
                            color: note != null && i <= note.round()
                                ? const Color(0xFFFFB800)
                                : Couleurs.grisBordure,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note == null
                          ? 'Pas encore de note'
                          : '${note.toStringAsFixed(1)} • '
                                '${stats!.nombreAvis} '
                                'avis',
                      style: Styles.gras(11, Couleurs.grisTexte),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            FutureBuilder<StatistiquesProfil>(
              future: _statistiques,
              builder: (context, instantane) =>
                  _Statistiques(stats: instantane.data),
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: Couleurs.grisBordure),
            _LigneMenu(
              icone: Icons.edit_note,
              texte: 'Mes alertes, aides & dons',
              auAppui: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EcranMesAlertes(),
                ),
              ),
            ),
            const _LigneMenu(icone: Icons.help, texte: 'Aides & support'),
            const _LigneMenu(icone: Icons.help, texte: 'A propos'),
          ],
        ),
      ),
    );
  }
}

/// Photo de profil ronde avec la pastille de modification (le crayon).
/// Un appui sur la photo ou sur le crayon ouvre le choix de la source.
class _PhotoProfil extends StatelessWidget {
  const _PhotoProfil({
    required this.profil,
    required this.enCours,
    required this.auAppui,
  });

  final ProfilUtilisateur? profil;
  final bool enCours;
  final VoidCallback auAppui;

  /// La photo à montrer, de côté [cote] : la sienne, sinon celle de Google,
  /// sinon l'icône de compte. Elle remplit tout le cercle, centrée (on garde
  /// le milieu de l'image et on coupe ce qui dépasse).
  Widget _contenu(double cote) {
    const icone = IconeCompte();
    final photo = profil?.photo;
    final url = profil?.photoUrl;
    if (photo != null) {
      return Image.memory(
        photo,
        width: cote,
        height: cote,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => icone,
      );
    }
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: cote,
        height: cote,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, _, _) => icone,
      );
    }
    return icone;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Modifier la photo de profil',
      child: GestureDetector(
        onTap: enCours ? null : auAppui,
        child: SizedBox(
          width: 126,
          height: 126,
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: Styles.ombre,
                ),
                // 114 = 120 moins les 2 bordures de 3.
                child: ClipOval(child: _contenu(114)),
              ),
              if (enCours)
                Container(
                  width: 120,
                  height: 120,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0x80000000),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 6,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: Styles.ombre,
                  ),
                  child: const Icon(Icons.edit, size: 16, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Statistiques extends StatelessWidget {
  const _Statistiques({required this.stats});

  /// Null tant que les chiffres sont en cours de chargement.
  final StatistiquesProfil? stats;

  String _valeur(int? nombre) => nombre == null ? '-' : '$nombre';

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _Statistique(
              valeur: _valeur(stats?.alertesPubliees),
              libelle: 'Alertes\npubliées',
            ),
          ),
          Container(width: 1, color: Colors.black54),
          Expanded(
            child: _Statistique(
              valeur: _valeur(stats?.aidesApportees),
              libelle: 'Aides\napportées',
            ),
          ),
          Container(width: 1, color: Colors.black54),
          Expanded(
            child: _Statistique(
              valeur: _valeur(stats?.donsEffectues),
              libelle: 'Dons\neffectués',
            ),
          ),
        ],
      ),
    );
  }
}

class _Statistique extends StatelessWidget {
  const _Statistique({required this.valeur, required this.libelle});

  final String valeur;
  final String libelle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(valeur, style: Styles.gras(13.5, Colors.black)),
        const SizedBox(height: 2),
        Text(
          libelle,
          textAlign: TextAlign.center,
          style: Styles.gras(11.5, Colors.black, hauteur: 1.35),
        ),
      ],
    );
  }
}

class _LigneMenu extends StatelessWidget {
  const _LigneMenu({required this.icone, required this.texte, this.auAppui});

  final IconData icone;
  final String texte;
  final VoidCallback? auAppui;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: auAppui,
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                Icon(icone, size: 30, color: Colors.black),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    texte,
                    style: Styles.gras(13.5, Couleurs.grisTexte),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 28, color: Colors.black),
              ],
            ),
          ),
          Container(height: 1, color: Couleurs.grisBordure),
        ],
      ),
    );
  }
}
