import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/messagerie.dart';
import '../../noyau/service_messagerie.dart';
import '../../partage/composants/avatar_personne.dart';
import '../../partage/composants/bouton_rouge.dart';
import '../../partage/composants/champ_texte.dart';
import '../../partage/composants/entete_retour.dart';
import '../../partage/styles.dart';

/// Ajouter un contact : on tape son numéro de téléphone ou son e-mail, on
/// voit son nom et sa photo s'il a un compte StarPole, puis on l'ajoute.
class EcranAjouterContact extends StatefulWidget {
  const EcranAjouterContact({super.key});

  @override
  State<EcranAjouterContact> createState() => _EcranAjouterContactState();
}

class _EcranAjouterContactState extends State<EcranAjouterContact> {
  late final ServiceMessagerie _service = context.read<ServiceMessagerie>();

  final TextEditingController _saisie = TextEditingController();
  final GlobalKey<ChampTexteState> _cleSaisie = GlobalKey();

  bool _recherche = false;
  bool _ajout = false;

  /// La personne trouvée, s'il y en a une.
  Contact? _trouve;

  /// Vrai quand la recherche n'a trouvé personne.
  bool _introuvable = false;

  /// Vrai si la personne trouvée est déjà dans mes contacts.
  bool _dejaContact = false;

  /// Un message d'erreur (par exemple « C'est votre propre compte. »).
  String? _erreur;

  @override
  void dispose() {
    _saisie.dispose();
    super.dispose();
  }

  void _reinitialiser() {
    _trouve = null;
    _introuvable = false;
    _dejaContact = false;
    _erreur = null;
  }

  Future<void> _chercher() async {
    final texte = _saisie.text.trim();
    // Rien de tapé : le champ vibre et clignote, sans message.
    if (texte.isEmpty) {
      _cleSaisie.currentState?.signalerErreur();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _recherche = true;
      _reinitialiser();
    });
    try {
      final contact = await _service.chercherUtilisateur(texte);
      var deja = false;
      if (contact != null) {
        final miens = await _service.contacts().first;
        deja = miens.any((c) => c.id == contact.id);
      }
      if (!mounted) return;
      setState(() {
        _trouve = contact;
        _introuvable = contact == null;
        _dejaContact = deja;
      });
    } on ErreurMessagerie catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _recherche = false);
    }
  }

  Future<void> _ajouter(Contact contact) async {
    setState(() => _ajout = true);
    try {
      await _service.ajouterContact(contact);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${contact.nom} a été ajouté à vos contacts.'),
          ),
        );
      Navigator.of(context).maybePop();
    } on ErreurMessagerie catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _ajout = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EnteteRetour(titre: 'Ajouter un contact'),
              const SizedBox(height: 18),
              Text(
                'Tapez le numéro de téléphone ou l\'e-mail de la personne. '
                'Elle doit avoir un compte StarPole.',
                style: Styles.gras(
                  13,
                  Couleurs.grisTexte,
                  hauteur: 1.5,
                  poids: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              ChampTexte(
                key: _cleSaisie,
                controleur: _saisie,
                icone: Icons.contact_phone,
                indication: 'Numéro de téléphone ou e-mail',
                type: TextInputType.emailAddress,
                erreurEnRouge: true,
              ),
              const SizedBox(height: 18),
              BoutonRouge(
                libelle: 'Rechercher',
                enCours: _recherche,
                auAppui: _chercher,
              ),
              const SizedBox(height: 24),
              if (_erreur != null) _Information(_erreur!),
              if (_introuvable)
                const _Information(
                  "Personne n'a été trouvé avec ce numéro ou cet e-mail. "
                  'Cette personne doit d\'abord créer un compte StarPole.',
                ),
              if (_trouve != null)
                _Resultat(
                  contact: _trouve!,
                  dejaContact: _dejaContact,
                  enCours: _ajout,
                  ajouter: () => _ajouter(_trouve!),
                ),
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
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        texte,
        style: Styles.gras(13, Couleurs.grisTexte, hauteur: 1.5),
      ),
    );
  }
}

/// La personne trouvée : photo, nom, et le bouton pour l'ajouter.
class _Resultat extends StatelessWidget {
  const _Resultat({
    required this.contact,
    required this.dejaContact,
    required this.enCours,
    required this.ajouter,
  });

  final Contact contact;
  final bool dejaContact;
  final bool enCours;
  final VoidCallback ajouter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Couleurs.grisBordure),
        boxShadow: Styles.ombre,
      ),
      child: Row(
        children: [
          AvatarPersonne(taille: 60, photo: contact.photo, avecOmbre: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.nom,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Styles.gras(16, Colors.black),
                ),
                if (dejaContact)
                  Text(
                    'Déjà dans vos contacts',
                    style: Styles.gras(11.5, Couleurs.vert),
                  ),
              ],
            ),
          ),
          if (!dejaContact)
            GestureDetector(
              onTap: enCours ? null : ajouter,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Couleurs.rouge,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: Styles.ombre,
                ),
                child: enCours
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : Text('Ajouter', style: Styles.gras(13, Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}
