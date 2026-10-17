import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/alerte.dart';
import '../../noyau/service_alertes.dart';
import '../../noyau/service_auth.dart';
import '../../partage/composants/ligne_menu.dart';
import '../../partage/composants/photo_profil.dart';
import '../../partage/styles.dart';
import 'ecran_mes_alertes.dart';
import '../parametres/ecran_parametres.dart';
import 'ecran_modification.dart';

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

  void _afficherMessage(String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texte)));
  }

  /// Recharge le profil (après un changement de photo, de nom ou de numéro).
  void _recharger() {
    setState(() {
      _profil = context.read<ServiceAuth>().chargerProfil();
    });
  }

  /// Ouvre la page « Paramètres » (le rouage).
  void _ouvrirParametres() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const EcranParametres()));
  }

  /// Ouvre la page de modification du profil (le crayon).
  Future<void> _modifierProfil() async {
    final modifie = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const EcranModification()),
    );
    if (modifie != true || !mounted) return;
    _recharger();
    _afficherMessage('Profil mis à jour.');
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
                Semantics(
                  button: true,
                  label: 'Paramètres',
                  child: GestureDetector(
                    onTap: _ouvrirParametres,
                    child: const Icon(
                      Icons.settings,
                      size: 36,
                      color: Colors.black,
                    ),
                  ),
                ),
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
              builder: (context, instantane) => PhotoProfilModifiable(
                profil: instantane.data,
                auChangement: _recharger,
                // Le crayon ouvre la page de modification du profil.
                auAppui: _modifierProfil,
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
            LigneMenu(
              icone: Icons.edit_note,
              texte: 'Mes alertes, aides & dons',
              auAppui: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EcranMesAlertes(),
                ),
              ),
            ),
            const LigneMenu(icone: Icons.help, texte: 'Aides & support'),
            const LigneMenu(icone: Icons.help, texte: 'A propos'),
          ],
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
