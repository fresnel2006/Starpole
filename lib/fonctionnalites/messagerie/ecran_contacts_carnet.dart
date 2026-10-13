import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/messagerie.dart';
import '../../noyau/service_carnet.dart';
import '../../noyau/service_messagerie.dart';
import '../../partage/composants/avatar_personne.dart';
import '../../partage/composants/bouton_rouge.dart';
import '../../partage/composants/entete_retour.dart';
import '../../partage/styles.dart';

/// Une personne du carnet qui a StarPole, avec le nom qu'elle porte dans le
/// carnet du téléphone.
class _Trouve {
  const _Trouve({required this.contact, required this.nomCarnet});

  final Contact contact;
  final String nomCarnet;
}

/// Retrouver ses proches depuis le carnet de contacts du téléphone : l'appli
/// compare les numéros du carnet avec ceux des inscrits et ne montre que ceux
/// qui ont StarPole.
class EcranContactsCarnet extends StatefulWidget {
  const EcranContactsCarnet({super.key});

  @override
  State<EcranContactsCarnet> createState() => _EcranContactsCarnetState();
}

/// Où en est l'écran.
enum _Etape { introduction, recherche, refuse, bloque, erreur, resultat }

class _EcranContactsCarnetState extends State<EcranContactsCarnet> {
  late final ServiceCarnet _carnet = context.read<ServiceCarnet>();
  late final ServiceMessagerie _messagerie = context.read<ServiceMessagerie>();

  _Etape _etape = _Etape.introduction;
  String _messageErreur = '';
  List<_Trouve> _trouves = [];

  /// Les identifiants des personnes déjà dans mes contacts.
  final Set<String> _ajoutes = {};

  /// Les identifiants en cours d'ajout.
  final Set<String> _enAjout = {};

  /// Demande l'autorisation, lit le carnet, puis cherche qui a StarPole.
  Future<void> _chercher() async {
    setState(() => _etape = _Etape.recherche);
    try {
      final resultat = await _carnet.lire();
      if (!mounted) return;
      if (resultat.etat == EtatCarnet.refuse) {
        setState(() => _etape = _Etape.refuse);
        return;
      }
      if (resultat.etat == EtatCarnet.bloque) {
        setState(() => _etape = _Etape.bloque);
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
      final deja = (await _messagerie.contacts().first).map((c) => c.id);

      // Une même personne n'apparaît qu'une fois, même avec plusieurs numéros.
      final parId = <String, _Trouve>{};
      inscrits.forEach((numero, contact) {
        parId.putIfAbsent(
          contact.id,
          () =>
              _Trouve(contact: contact, nomCarnet: nomParNumero[numero] ?? ''),
        );
      });
      final liste = parId.values.toList()
        ..sort((a, b) => a.contact.nom.compareTo(b.contact.nom));

      if (!mounted) return;
      setState(() {
        _trouves = liste;
        _ajoutes
          ..clear()
          ..addAll(deja);
        _etape = _Etape.resultat;
      });
    } on ErreurMessagerie catch (e) {
      if (mounted) {
        setState(() {
          _messageErreur = e.message;
          _etape = _Etape.erreur;
        });
      }
    }
  }

  Future<void> _ajouter(Contact contact) async {
    if (_enAjout.contains(contact.id)) return;
    setState(() => _enAjout.add(contact.id));
    try {
      await _messagerie.ajouterContact(contact);
      if (mounted) setState(() => _ajoutes.add(contact.id));
    } on ErreurMessagerie catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _enAjout.remove(contact.id));
    }
  }

  Future<void> _toutAjouter() async {
    for (final t in _trouves.where((t) => !_ajoutes.contains(t.contact.id))) {
      await _ajouter(t.contact);
    }
  }

  Future<void> _ouvrirReglages() async {
    await _carnet.ouvrirReglages();
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
              const EnteteRetour(titre: 'Mon carnet de contacts'),
              Expanded(child: _contenu()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contenu() {
    switch (_etape) {
      case _Etape.introduction:
        return _Introduction(
          icone: Icons.contacts_outlined,
          titre: 'Retrouvez vos proches sur StarPole',
          texte:
              'StarPole va comparer les numéros de votre carnet de contacts '
              'avec ceux des personnes inscrites, pour vous montrer qui est '
              'déjà sur l\'appli. Vos contacts ne sont pas enregistrés dans la '
              'base de StarPole.',
          libelleBouton: 'Autoriser et chercher',
          auAppui: _chercher,
        );
      case _Etape.recherche:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Couleurs.rouge),
              SizedBox(height: 18),
              _TexteCentre('Recherche de vos contacts sur StarPole...'),
            ],
          ),
        );
      case _Etape.refuse:
        return _Introduction(
          icone: Icons.lock_outline,
          titre: 'Accès refusé',
          texte:
              'Sans l\'accès à votre carnet, StarPole ne peut pas voir qui '
              'de vos proches est inscrit. Vous pouvez toujours ajouter '
              'quelqu\'un avec son numéro ou son e-mail.',
          libelleBouton: 'Réessayer',
          auAppui: _chercher,
        );
      case _Etape.bloque:
        return _Introduction(
          icone: Icons.lock_outline,
          titre: 'Accès bloqué',
          texte:
              'L\'accès aux contacts est bloqué pour StarPole. Ouvrez les '
              'réglages du téléphone, autorisez « Contacts », puis revenez ici.',
          libelleBouton: 'Ouvrir les réglages',
          auAppui: _ouvrirReglages,
          secondaire: 'Réessayer',
          auAppuiSecondaire: _chercher,
        );
      case _Etape.erreur:
        return _Introduction(
          icone: Icons.cloud_off_outlined,
          titre: 'Recherche impossible',
          texte: _messageErreur,
          libelleBouton: 'Réessayer',
          auAppui: _chercher,
        );
      case _Etape.resultat:
        return _Resultat(
          trouves: _trouves,
          ajoutes: _ajoutes,
          enAjout: _enAjout,
          ajouter: _ajouter,
          toutAjouter: _toutAjouter,
        );
    }
  }
}

/// Un écran simple : une grande icône, un titre, un texte et un bouton.
class _Introduction extends StatelessWidget {
  const _Introduction({
    required this.icone,
    required this.titre,
    required this.texte,
    required this.libelleBouton,
    required this.auAppui,
    this.secondaire,
    this.auAppuiSecondaire,
  });

  final IconData icone;
  final String titre;
  final String texte;
  final String libelleBouton;
  final VoidCallback auAppui;
  final String? secondaire;
  final VoidCallback? auAppuiSecondaire;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 40, 8, 24),
      child: Column(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
              color: Couleurs.fondPuceRouge,
              shape: BoxShape.circle,
            ),
            child: Icon(icone, size: 56, color: Couleurs.rouge),
          ),
          const SizedBox(height: 26),
          Text(
            titre,
            textAlign: TextAlign.center,
            style: Styles.gras(19, Colors.black),
          ),
          const SizedBox(height: 14),
          _TexteCentre(texte),
          const SizedBox(height: 30),
          BoutonRouge(libelle: libelleBouton, auAppui: auAppui),
          if (secondaire != null) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: auAppuiSecondaire,
              child: Text(secondaire!, style: Styles.gras(15, Couleurs.rouge)),
            ),
          ],
        ],
      ),
    );
  }
}

class _TexteCentre extends StatelessWidget {
  const _TexteCentre(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Text(
      texte,
      textAlign: TextAlign.center,
      style: Styles.gras(
        13,
        Couleurs.grisTexte,
        hauteur: 1.55,
        poids: FontWeight.w500,
      ),
    );
  }
}

/// La liste des proches qui ont StarPole.
class _Resultat extends StatelessWidget {
  const _Resultat({
    required this.trouves,
    required this.ajoutes,
    required this.enAjout,
    required this.ajouter,
    required this.toutAjouter,
  });

  final List<_Trouve> trouves;
  final Set<String> ajoutes;
  final Set<String> enAjout;
  final void Function(Contact) ajouter;
  final VoidCallback toutAjouter;

  @override
  Widget build(BuildContext context) {
    if (trouves.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Center(
          child: _TexteCentre(
            "Aucun de vos contacts n'est encore sur StarPole.\n"
            "Invitez-les à télécharger l'appli !",
          ),
        ),
      );
    }

    final aAjouter = trouves
        .where((t) => !ajoutes.contains(t.contact.id))
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          trouves.length == 1
              ? '1 de vos contacts est sur StarPole'
              : '${trouves.length} de vos contacts sont sur StarPole',
          style: Styles.gras(15, Colors.black),
        ),
        const SizedBox(height: 12),
        if (aAjouter > 1)
          GestureDetector(
            onTap: toutAjouter,
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Couleurs.rouge,
                borderRadius: BorderRadius.circular(14),
                boxShadow: Styles.ombre,
              ),
              child: Text(
                'Tout ajouter ($aAjouter)',
                style: Styles.gras(15, Colors.white),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Container(height: 1, color: Couleurs.grisBordure),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              for (final t in trouves)
                _LigneTrouve(
                  trouve: t,
                  ajoute: ajoutes.contains(t.contact.id),
                  enCours: enAjout.contains(t.contact.id),
                  ajouter: () => ajouter(t.contact),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LigneTrouve extends StatelessWidget {
  const _LigneTrouve({
    required this.trouve,
    required this.ajoute,
    required this.enCours,
    required this.ajouter,
  });

  final _Trouve trouve;
  final bool ajoute;
  final bool enCours;
  final VoidCallback ajouter;

  @override
  Widget build(BuildContext context) {
    final contact = trouve.contact;
    final memeNom =
        trouve.nomCarnet.trim().toLowerCase() ==
        contact.nom.trim().toLowerCase();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              AvatarPersonne(taille: 52, photo: contact.photo),
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
                    if (trouve.nomCarnet.isNotEmpty && !memeNom)
                      Text(
                        'Dans votre carnet : ${trouve.nomCarnet}',
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
              const SizedBox(width: 10),
              if (ajoute)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 22,
                      color: Couleurs.vert,
                    ),
                    const SizedBox(width: 6),
                    Text('Ajouté', style: Styles.gras(12.5, Couleurs.vert)),
                  ],
                )
              else
                GestureDetector(
                  onTap: enCours ? null : ajouter,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Couleurs.rouge,
                      borderRadius: BorderRadius.circular(19),
                      boxShadow: Styles.ombre,
                    ),
                    child: enCours
                        ? const SizedBox(
                            width: 18,
                            height: 18,
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
        ),
        Container(height: 1, color: Couleurs.grisBordure),
      ],
    );
  }
}
