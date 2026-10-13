import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/messagerie.dart';
import '../../noyau/service_messagerie.dart';
import '../../partage/composants/avatar_utilisateur.dart';
import '../../partage/composants/entete_retour.dart';
import '../../partage/styles.dart';
import 'ecran_ajouter_contact.dart';
import 'ecran_contacts_carnet.dart';
import 'ecran_conversation.dart';

/// Mes contacts : un appui sur l'un d'eux ouvre la conversation. Un bouton
/// permet d'en ajouter un nouveau.
class EcranContacts extends StatefulWidget {
  const EcranContacts({super.key});

  @override
  State<EcranContacts> createState() => _EcranContactsState();
}

class _EcranContactsState extends State<EcranContacts> {
  late final ServiceMessagerie _service = context.read<ServiceMessagerie>();
  late final Stream<List<Contact>> _flux = _service.contacts();

  /// Identifiant du contact dont la conversation est en train de s'ouvrir.
  String? _ouvertureEn;

  void _afficherMessage(String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texte)));
  }

  Future<void> _ouvrir(Contact contact) async {
    if (_ouvertureEn != null) return;
    setState(() => _ouvertureEn = contact.id);
    try {
      final id = await _service.ouvrirConversation(contact);
      if (!mounted) return;
      // On remplace cet écran : en revenant, on retrouve la liste des
      // conversations, pas celle des contacts.
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => EcranConversation(
            conversationId: id,
            autreId: contact.id,
            autreNom: contact.nom,
          ),
        ),
      );
    } on ErreurMessagerie catch (e) {
      if (mounted) {
        setState(() => _ouvertureEn = null);
        _afficherMessage(e.message);
      }
    }
  }

  void _depuisLeCarnet() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const EcranContactsCarnet()),
    );
  }

  void _ajouter() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const EcranAjouterContact()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EnteteRetour(titre: 'Nouvelle conversation'),
              const SizedBox(height: 14),
              _BoutonAjouter(auAppui: _ajouter),
              const SizedBox(height: 12),
              _BoutonCarnet(auAppui: _depuisLeCarnet),
              const SizedBox(height: 18),
              Text('Mes contacts', style: Styles.gras(14, Colors.black)),
              const SizedBox(height: 6),
              Container(height: 1, color: Couleurs.grisBordure),
              Expanded(
                child: StreamBuilder<List<Contact>>(
                  stream: _flux,
                  builder: (context, instantane) {
                    if (instantane.hasError) {
                      return const _Message(
                        'Impossible de charger vos contacts. '
                        'Vérifiez votre connexion.',
                      );
                    }
                    final contacts = instantane.data;
                    if (contacts == null) {
                      return const Center(
                        child: CircularProgressIndicator(color: Couleurs.rouge),
                      );
                    }
                    if (contacts.isEmpty) {
                      return const _Message(
                        "Vous n'avez pas encore de contact.\n"
                        'Ajoutez quelqu\'un avec son numéro de téléphone '
                        'ou son e-mail : il doit avoir un compte StarPole.',
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        for (final contact in contacts)
                          _LigneContact(
                            contact: contact,
                            enOuverture: _ouvertureEn == contact.id,
                            auAppui: () => _ouvrir(contact),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gros bouton « Ajouter un contact ».
class _BoutonAjouter extends StatelessWidget {
  const _BoutonAjouter({required this.auAppui});

  final VoidCallback auAppui;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ajouter un contact',
      child: GestureDetector(
        onTap: auAppui,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Couleurs.rouge,
            borderRadius: BorderRadius.circular(14),
            boxShadow: Styles.ombre,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add_alt_1, size: 26, color: Colors.white),
              const SizedBox(width: 12),
              Text('Ajouter un contact', style: Styles.gras(16, Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton « Depuis mon carnet de contacts » : blanc avec un contour rouge.
class _BoutonCarnet extends StatelessWidget {
  const _BoutonCarnet({required this.auAppui});

  final VoidCallback auAppui;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Depuis mon carnet de contacts',
      child: GestureDetector(
        onTap: auAppui,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Couleurs.rouge, width: 1.5),
            boxShadow: Styles.ombre,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.contacts, size: 26, color: Couleurs.rouge),
              const SizedBox(width: 12),
              Text(
                'Depuis mon carnet de contacts',
                style: Styles.gras(15, Couleurs.rouge),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LigneContact extends StatelessWidget {
  const _LigneContact({
    required this.contact,
    required this.enOuverture,
    required this.auAppui,
  });

  final Contact contact;
  final bool enOuverture;
  final VoidCallback auAppui;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: auAppui,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                AvatarUtilisateur(id: contact.id, taille: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Styles.gras(15, Colors.black),
                      ),
                      if (contact.telephone.isNotEmpty)
                        Text(
                          contact.telephone,
                          style: Styles.gras(
                            11,
                            Couleurs.grisTexte,
                            poids: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (enOuverture)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Couleurs.rouge,
                    ),
                  )
                else
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 24,
                    color: Couleurs.rouge,
                  ),
              ],
            ),
          ),
          Container(height: 1, color: Couleurs.grisBordure),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          texte,
          textAlign: TextAlign.center,
          style: Styles.gras(13, Couleurs.grisTexte, hauteur: 1.5),
        ),
      ),
    );
  }
}
