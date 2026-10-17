import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/invitation.dart';
import '../../noyau/messagerie.dart';
import '../../noyau/normalisation.dart';
import '../../noyau/service_carnet.dart';
import '../../noyau/service_messagerie.dart';
import '../../partage/composants/bouton_rouge.dart';
import '../../partage/composants/champ_texte.dart';
import '../../partage/styles.dart';

/// Ajouter un contact : prénom, nom et numéro de téléphone. Si la personne a un
/// compte StarPole, elle est ajoutée à mes contacts ; sinon on propose de
/// l'inviter. Le contact peut aussi être enregistré dans le téléphone.
class EcranAjouterContact extends StatefulWidget {
  const EcranAjouterContact({super.key});

  @override
  State<EcranAjouterContact> createState() => _EcranAjouterContactState();
}

class _EcranAjouterContactState extends State<EcranAjouterContact> {
  late final ServiceMessagerie _messagerie = context.read<ServiceMessagerie>();
  late final ServiceCarnet _carnet = context.read<ServiceCarnet>();

  final TextEditingController _prenom = TextEditingController();
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _numero = TextEditingController();
  final GlobalKey<ChampTexteState> _clePrenom = GlobalKey();
  final GlobalKey<ChampTexteState> _cleNumero = GlobalKey();

  bool _synchroniser = false;
  bool _enCours = false;

  /// Un message d'information sous le bouton (pas de compte StarPole, erreur).
  String? _information;

  /// Vrai quand le numéro n'a pas de compte StarPole : on propose d'inviter.
  bool _proposerInvitation = false;

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _numero.dispose();
    super.dispose();
  }

  void _afficherMessage(String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texte)));
  }

  /// Le nom complet tel que la personne l'a tapé (« Prénom Nom »).
  String get _nomComplet => '${_prenom.text.trim()} ${_nom.text.trim()}'.trim();

  /// Vérifie les champs, enregistre dans le téléphone si demandé, puis cherche
  /// la personne sur StarPole.
  Future<void> _enregistrer() async {
    // Champ vide ou numéro trop court : il vibre et clignote, sans message.
    final prenomVide = _prenom.text.trim().isEmpty;
    final numeroInvalide = normaliserTelephone(_numero.text).length < 8;
    if (prenomVide || numeroInvalide) {
      if (prenomVide) _clePrenom.currentState?.signalerErreur();
      if (numeroInvalide) _cleNumero.currentState?.signalerErreur();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _enCours = true;
      _information = null;
      _proposerInvitation = false;
    });

    try {
      // 1. Dans le carnet du téléphone, si le bouton est activé.
      var dansLeTelephone = false;
      String? avertissement;
      if (_synchroniser) {
        final etat = await _carnet.enregistrer(
          prenom: _prenom.text.trim(),
          nom: _nom.text.trim(),
          numero: _numero.text.trim(),
        );
        dansLeTelephone = etat == EtatCarnet.ok;
        if (etat == EtatCarnet.refuse) {
          avertissement =
              'Sans autorisation, le contact n\'a pas été enregistré dans '
              'votre téléphone.';
        } else if (etat == EtatCarnet.bloque) {
          avertissement =
              'L\'accès aux contacts est bloqué : le contact n\'a pas été '
              'enregistré dans votre téléphone.';
        }
      }
      if (!mounted) return;

      // 2. Sur StarPole : la personne a-t-elle un compte ?
      final compte = await _messagerie.chercherUtilisateur(_numero.text);
      if (!mounted) return;
      if (compte == null) {
        setState(() {
          _proposerInvitation = true;
          _information = [
            "$_nomComplet n'est pas encore sur StarPole. Invitez cette "
                'personne à créer son compte, puis vous pourrez discuter.',
            ?(dansLeTelephone
                ? 'Le contact est enregistré dans votre téléphone.'
                : null),
            ?avertissement,
          ].join('\n');
        });
        return;
      }

      await _messagerie.ajouterContact(
        Contact(
          id: compte.id,
          nom: _nomComplet,
          telephone: _numero.text.trim(),
        ),
      );
      if (!mounted) return;
      _afficherMessage(
        avertissement ?? '$_nomComplet a été ajouté à vos contacts.',
      );
      Navigator.of(context).maybePop();
    } on ErreurMessagerie catch (e) {
      if (mounted) setState(() => _information = e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ajouter un contact',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Styles.gras(17, Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              // Prénom et nom, avec le bonhomme rouge à gauche.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Icon(Icons.person, size: 34, color: Couleurs.rouge),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      children: [
                        ChampTexte(
                          key: _clePrenom,
                          controleur: _prenom,
                          indication: 'Prénom',
                          enCreux: true,
                          rayon: 10,
                          erreurEnRouge: true,
                        ),
                        const SizedBox(height: 14),
                        ChampTexte(
                          controleur: _nom,
                          indication: 'Nom',
                          enCreux: true,
                          rayon: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              // Numéro de téléphone.
              Row(
                children: [
                  const Icon(
                    Icons.phone_in_talk_outlined,
                    size: 34,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: ChampTexte(
                      key: _cleNumero,
                      controleur: _numero,
                      indication: 'Numéro de téléphone',
                      type: TextInputType.phone,
                      enCreux: true,
                      rayon: 10,
                      erreurEnRouge: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Enregistrer aussi dans le carnet du téléphone.
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Synchroniser le contact sur le téléphone',
                          style: Styles.gras(15, Colors.black, hauteur: 1.35),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Seuls les contacts avec un numéro de téléphone '
                          'peuvent être synchronisés',
                          style: Styles.gras(
                            11.5,
                            Colors.black,
                            hauteur: 1.4,
                            poids: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: _synchroniser,
                    onChanged: (v) => setState(() => _synchroniser = v),
                    thumbColor: const WidgetStatePropertyAll(Couleurs.rouge),
                    trackColor: WidgetStateProperty.resolveWith(
                      (etats) => etats.contains(WidgetState.selected)
                          ? Couleurs.fondPuceRouge
                          : const Color(0xFFE6E6E6),
                    ),
                    trackOutlineColor: const WidgetStatePropertyAll(
                      Colors.transparent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(height: 1, color: Couleurs.grisBordure),
              const SizedBox(height: 56),
              BoutonRouge(
                libelle: 'Enregistrer',
                enCours: _enCours,
                auAppui: _enregistrer,
              ),
              if (_information != null) ...[
                const SizedBox(height: 22),
                _Information(_information!),
              ],
              if (_proposerInvitation) ...[
                const SizedBox(height: 14),
                BoutonRouge(
                  libelle: 'Inviter sur StarPole',
                  auAppui: inviterSurStarPole,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Information extends StatelessWidget {
  const _Information(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Couleurs.grisFond,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texte,
        style: Styles.gras(13, Couleurs.grisTexte, hauteur: 1.5),
      ),
    );
  }
}
