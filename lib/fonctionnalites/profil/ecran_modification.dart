import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/normalisation.dart';
import '../../noyau/service_auth.dart';
import '../../partage/composants/bouton_google.dart';
import '../../partage/composants/bouton_rouge.dart';
import '../../partage/composants/champ_texte.dart';
import '../../partage/composants/photo_profil.dart';
import '../../partage/styles.dart';

/// Page « Modification » : changer sa photo, son nom et son numéro. Les champs
/// blancs montrent les valeurs actuelles, les champs gris reçoivent les
/// nouvelles. Se ferme avec `true` quand le profil a été modifié.
class EcranModification extends StatefulWidget {
  const EcranModification({super.key});

  @override
  State<EcranModification> createState() => _EcranModificationState();
}

class _EcranModificationState extends State<EcranModification> {
  late final ServiceAuth _auth = context.read<ServiceAuth>();
  ProfilUtilisateur? _profil;

  // Valeurs actuelles (champs blancs, non modifiables).
  final TextEditingController _nomActuel = TextEditingController();
  final TextEditingController _telephoneActuel = TextEditingController();

  // Nouvelles valeurs (champs gris).
  final TextEditingController _nouveauNom = TextEditingController();
  final TextEditingController _nouveauTelephone = TextEditingController();
  final GlobalKey<ChampTexteState> _cleNom = GlobalKey();
  final GlobalKey<ChampTexteState> _cleTelephone = GlobalKey();

  bool _enCours = false;
  bool _modifie = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _nomActuel.dispose();
    _telephoneActuel.dispose();
    _nouveauNom.dispose();
    _nouveauTelephone.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    final profil = await _auth.chargerProfil();
    if (!mounted) return;
    setState(() {
      _profil = profil;
      _nomActuel.text = profil?.nom ?? '';
      _telephoneActuel.text = (profil?.telephone ?? '').isEmpty
          ? 'Aucun numero enregistre'
          : profil!.telephone;
    });
  }

  void _afficherMessage(String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texte)));
  }

  /// Enregistre ce qui a été saisi. Un champ vide ou incorrect vibre.
  Future<void> _valider() async {
    final nom = _nouveauNom.text.trim();
    final telephone = _nouveauTelephone.text.trim();
    if (nom.isEmpty && telephone.isEmpty) {
      _cleNom.currentState?.signalerErreur();
      _cleTelephone.currentState?.signalerErreur();
      return;
    }
    if (telephone.isNotEmpty && normaliserTelephone(telephone).length < 8) {
      _cleTelephone.currentState?.signalerErreur();
      return;
    }

    setState(() => _enCours = true);
    try {
      await _auth.modifierProfil(
        nom: nom.isEmpty ? null : nom,
        telephone: telephone.isEmpty ? null : telephone,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ErreurAuth catch (e) {
      if (mounted) _afficherMessage(e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  /// La photo a changé : on recharge le profil, et l'écran d'avant devra aussi
  /// se mettre à jour.
  void _photoChangee() {
    _modifie = true;
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_modifie);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        color: Colors.transparent,
                        alignment: Alignment.centerLeft,
                        child: const Icon(
                          Icons.chevron_left,
                          size: 34,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Modification',
                          style: Styles.gras(22, Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 18),
                Center(
                  child: PhotoProfilModifiable(
                    profil: _profil,
                    auChangement: _photoChangee,
                    taille: 104,
                  ),
                ),
                const SizedBox(height: 26),
                const _Etiquette('Nom complet'),
                const SizedBox(height: 8),
                ChampTexte(
                  controleur: _nomActuel,
                  icone: Icons.person,
                  indication: 'Nom complet',
                  modifiable: false,
                ),
                const SizedBox(height: 10),
                ChampTexte(
                  key: _cleNom,
                  controleur: _nouveauNom,
                  icone: Icons.draw,
                  indication: 'Saisissez le nouveau nom',
                  enCreux: true,
                  erreurEnRouge: true,
                ),
                const SizedBox(height: 22),
                const _Etiquette('Numero'),
                const SizedBox(height: 8),
                ChampTexte(
                  controleur: _telephoneActuel,
                  icone: Icons.phone_in_talk_outlined,
                  indication: 'Numero de telephone',
                  modifiable: false,
                ),
                const SizedBox(height: 10),
                ChampTexte(
                  key: _cleTelephone,
                  controleur: _nouveauTelephone,
                  icone: Icons.draw,
                  indication: 'Saisissez un autre numero',
                  type: TextInputType.phone,
                  enCreux: true,
                  erreurEnRouge: true,
                ),
                const SizedBox(height: 22),
                const _Etiquette('Email'),
                const SizedBox(height: 8),
                BoutonGoogle(
                  libelle: "Changer d'Email",
                  auAppui: () => _afficherMessage(
                    "Votre e-mail est lié à votre compte. Pour en changer, "
                    'connectez-vous avec un autre compte.',
                  ),
                ),
                const SizedBox(height: 40),
                BoutonRouge(
                  libelle: 'Valider',
                  enCours: _enCours,
                  auAppui: _valider,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Titre rouge d'une section (« Nom complet », « Numero », « Email »).
class _Etiquette extends StatelessWidget {
  const _Etiquette(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Text(texte, style: Styles.gras(14, Couleurs.rouge));
  }
}
