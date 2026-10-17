import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/messagerie.dart';
import '../../noyau/service_carnet.dart';
import '../../noyau/service_messagerie.dart';
import '../../partage/composants/avatar_utilisateur.dart';
import '../../partage/composants/bouton_rouge.dart';
import '../../partage/styles.dart';
import 'ecran_ajouter_contact.dart';
import 'ecran_conversation.dart';

/// Une personne de la liste, avec une ligne d'information sous son nom.
class _Entree {
  const _Entree({required this.contact, this.info = ''});

  final Contact contact;
  final String info;
}

/// Où en est la synchronisation avec les contacts du téléphone.
enum _Synchro { enCours, ok, refuse, bloque, erreur }

/// Nouvelle conversation : dès l'ouverture, l'appli demande l'accès aux
/// contacts du téléphone et montre ceux qui ont StarPole (sans les enregistrer),
/// avec les contacts ajoutés à la main. Un appui ouvre la conversation ; l'icône
/// en haut à droite permet d'ajouter quelqu'un avec son numéro ou son e-mail.
class EcranContacts extends StatefulWidget {
  const EcranContacts({super.key});

  @override
  State<EcranContacts> createState() => _EcranContactsState();
}

class _EcranContactsState extends State<EcranContacts> {
  late final ServiceMessagerie _messagerie = context.read<ServiceMessagerie>();
  late final ServiceCarnet _carnet = context.read<ServiceCarnet>();

  /// Contacts ajoutés à la main (en direct).
  List<Contact>? _manuels;
  StreamSubscription<List<Contact>>? _abonnement;

  /// Proches du carnet qui ont StarPole, par identifiant de compte.
  Map<String, _Entree> _duCarnet = {};
  _Synchro _synchro = _Synchro.enCours;
  String _messageErreur = '';

  /// Identifiant du contact dont la conversation est en train de s'ouvrir.
  String? _ouvertureEn;

  @override
  void initState() {
    super.initState();
    _abonnement = _messagerie.contacts().listen(
      (liste) {
        if (mounted) setState(() => _manuels = liste);
      },
      onError: (_) {
        if (mounted) setState(() => _manuels = const []);
      },
    );
    // L'autorisation est demandée tout de suite, en même temps.
    _synchroniser();
  }

  @override
  void dispose() {
    _abonnement?.cancel();
    super.dispose();
  }

  /// Demande l'accès au carnet, le lit, puis cherche qui a StarPole.
  Future<void> _synchroniser() async {
    setState(() => _synchro = _Synchro.enCours);
    try {
      final resultat = await _carnet.lire();
      if (!mounted) return;
      if (resultat.etat != EtatCarnet.ok) {
        setState(() {
          _synchro = resultat.etat == EtatCarnet.bloque
              ? _Synchro.bloque
              : _Synchro.refuse;
        });
        return;
      }

      // Numéro -> nom dans le carnet.
      final nomParNumero = <String, String>{};
      for (final entree in resultat.entrees) {
        for (final numero in entree.numeros) {
          nomParNumero.putIfAbsent(numero, () => entree.nom);
        }
      }
      final inscrits = await _messagerie.trouverParTelephones(
        nomParNumero.keys,
      );

      // Une même personne n'apparaît qu'une fois, même avec plusieurs numéros.
      final parId = <String, _Entree>{};
      inscrits.forEach((numero, contact) {
        final nomCarnet = (nomParNumero[numero] ?? '').trim();
        final identique = nomCarnet.toLowerCase() == contact.nom.toLowerCase();
        parId.putIfAbsent(
          contact.id,
          () => _Entree(
            contact: contact,
            info: nomCarnet.isEmpty || identique
                ? ''
                : 'Dans votre carnet : $nomCarnet',
          ),
        );
      });
      if (!mounted) return;
      setState(() {
        _duCarnet = parId;
        _synchro = _Synchro.ok;
      });
    } on ErreurMessagerie catch (e) {
      if (mounted) {
        setState(() {
          _messageErreur = e.message;
          _synchro = _Synchro.erreur;
        });
      }
    }
  }

  /// Le carnet d'abord (avec la mention du nom du carnet), puis les contacts
  /// ajoutés à la main, sans doublon, par ordre alphabétique.
  List<_Entree> _liste() {
    final parId = {..._duCarnet};
    for (final contact in _manuels ?? const <Contact>[]) {
      parId.putIfAbsent(
        contact.id,
        () => _Entree(contact: contact, info: contact.telephone),
      );
    }
    return parId.values.toList()..sort(
      (a, b) =>
          a.contact.nom.toLowerCase().compareTo(b.contact.nom.toLowerCase()),
    );
  }

  void _afficherMessage(String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texte)));
  }

  Future<void> _ouvrir(Contact contact) async {
    if (_ouvertureEn != null) return;
    setState(() => _ouvertureEn = contact.id);
    try {
      final id = await _messagerie.ouvrirConversation(contact);
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

  void _ajouter() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const EcranAjouterContact()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liste = _liste();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Entete(auAjout: _ajouter),
              const SizedBox(height: 18),
              Text(
                'Mes contacts',
                style: Styles.gras(
                  13,
                  Couleurs.grisIndication,
                  poids: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(height: 1, color: Couleurs.grisBordure),
              if (_synchro == _Synchro.enCours)
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: Couleurs.rouge,
                  backgroundColor: Colors.transparent,
                ),
              Expanded(child: _contenu(liste)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contenu(List<_Entree> liste) {
    final notice = switch (_synchro) {
      _Synchro.refuse => _Notice(
        texte:
            'Sans l\'accès à vos contacts, StarPole ne peut pas voir qui de '
            'vos proches est inscrit.',
        libelle: 'Autoriser',
        auAppui: _synchroniser,
      ),
      _Synchro.bloque => _Notice(
        texte:
            'L\'accès aux contacts est bloqué. Ouvrez les réglages du '
            'téléphone, autorisez « Contacts », puis revenez ici.',
        libelle: 'Ouvrir les réglages',
        auAppui: _carnet.ouvrirReglages,
        secondaire: 'Réessayer',
        auAppuiSecondaire: _synchroniser,
      ),
      _Synchro.erreur => _Notice(
        texte: _messageErreur,
        libelle: 'Réessayer',
        auAppui: _synchroniser,
      ),
      _ => null,
    };

    return ListView(
      padding: const EdgeInsets.only(top: 6, bottom: 24),
      children: [
        ?notice,
        if (liste.isEmpty && notice == null && _synchro == _Synchro.ok)
          const _Message(
            "Aucun de vos contacts n'est encore sur StarPole.\n"
            'Touchez l\'icône en haut à droite pour ajouter quelqu\'un avec '
            'son numéro ou son e-mail, et invitez vos proches !',
          ),
        for (final entree in liste)
          _LigneContact(
            entree: entree,
            enOuverture: _ouvertureEn == entree.contact.id,
            auAppui: () => _ouvrir(entree.contact),
          ),
        if (_synchro == _Synchro.ok && liste.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 14),
            child: _Message(
              'Synchronisé avec les contacts de votre téléphone. '
              'StarPole ne les enregistre pas.',
              petit: true,
            ),
          ),
      ],
    );
  }
}

/// Flèche retour, titre centré et icône « Ajouter un contact » à droite.
class _Entete extends StatelessWidget {
  const _Entete({required this.auAjout});

  final VoidCallback auAjout;

  @override
  Widget build(BuildContext context) {
    return Row(
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
          child: Text(
            'Nouvelle conversation',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Styles.gras(17, Colors.black),
          ),
        ),
        Semantics(
          button: true,
          label: 'Ajouter un contact',
          child: GestureDetector(
            onTap: auAjout,
            child: Container(
              width: 40,
              height: 40,
              color: Colors.transparent,
              alignment: Alignment.centerRight,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Couleurs.rouge, width: 1.8),
                ),
                child: const Icon(
                  Icons.person_add_alt_1,
                  size: 22,
                  color: Couleurs.rouge,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Message sur l'accès aux contacts, avec un bouton pour réessayer.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.texte,
    required this.libelle,
    required this.auAppui,
    this.secondaire,
    this.auAppuiSecondaire,
  });

  final String texte;
  final String libelle;
  final VoidCallback auAppui;
  final String? secondaire;
  final VoidCallback? auAppuiSecondaire;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Couleurs.grisFond,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _Message(texte),
          const SizedBox(height: 14),
          BoutonRouge(libelle: libelle, auAppui: auAppui),
          if (secondaire != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: auAppuiSecondaire,
              child: Text(secondaire!, style: Styles.gras(14, Couleurs.rouge)),
            ),
          ],
        ],
      ),
    );
  }
}

class _LigneContact extends StatelessWidget {
  const _LigneContact({
    required this.entree,
    required this.enOuverture,
    required this.auAppui,
  });

  final _Entree entree;
  final bool enOuverture;
  final VoidCallback auAppui;

  @override
  Widget build(BuildContext context) {
    final contact = entree.contact;
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
                      if (entree.info.isNotEmpty)
                        Text(
                          entree.info,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
  const _Message(this.texte, {this.petit = false});

  final String texte;
  final bool petit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        texte,
        textAlign: TextAlign.center,
        style: Styles.gras(
          petit ? 11 : 13,
          petit ? Couleurs.grisIndication : Couleurs.grisTexte,
          hauteur: 1.5,
          poids: FontWeight.w500,
        ),
      ),
    );
  }
}
