import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/service_alertes.dart';
import '../../partage/composants/avatar_personne.dart';
import '../../partage/composants/entete_retour.dart';
import '../../partage/composants/puce.dart';
import '../../partage/styles.dart';

/// Note donnée à l'autre personne d'une alerte : étoiles, commentaire et
/// étiquettes. Elle est enregistrée dans la base à l'envoi.
class EcranNoterAidant extends StatefulWidget {
  const EcranNoterAidant({
    super.key,
    required this.alerteId,
    required this.personneId,
    required this.personneNom,
    this.titre = "Noter l'aidant",
    this.role = 'Citoyen benevol',
  });

  final String alerteId;

  /// La personne notée.
  final String personneId;
  final String personneNom;

  /// Le titre de l'écran (« Noter l'aidant » ou « Noter l'auteur »).
  final String titre;

  /// Le texte sous le nom (« Citoyen benevol », « Auteur de l'alerte »).
  final String role;

  @override
  State<EcranNoterAidant> createState() => _EcranNoterAidantState();
}

class _EcranNoterAidantState extends State<EcranNoterAidant> {
  static const int _longueurMax = 200;
  static const List<String> _etiquettes = [
    'Efficace',
    'Rapide',
    'mechant',
    'cool',
  ];

  final TextEditingController _commentaire = TextEditingController();
  final Set<String> _etiquettesChoisies = {};
  int _etoiles = 5;
  bool _enCours = false;

  @override
  void dispose() {
    _commentaire.dispose();
    super.dispose();
  }

  void _afficherMessage(String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texte)));
  }

  Future<void> _envoyer() async {
    final service = context.read<ServiceAlertes>();
    setState(() => _enCours = true);
    try {
      await service.noter(
        alerteId: widget.alerteId,
        pourId: widget.personneId,
        etoiles: _etoiles,
        commentaire: _commentaire.text,
        etiquettes: _etiquettesChoisies.toList(),
      );
      // La note est envoyée : on revient à l'écran principal.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on ErreurAlerte catch (e) {
      if (mounted) _afficherMessage(e.message);
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
          padding: const EdgeInsets.fromLTRB(34, 8, 32, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EnteteRetour(titre: widget.titre, tailleTitre: 22),
              const SizedBox(height: 18),
              Row(
                children: [
                  const AvatarPersonne(taille: 100, avecOmbre: true),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.personneNom,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Styles.gras(22.7, Colors.black),
                        ),
                        Text(
                          widget.role,
                          style: Styles.gras(16.5, Couleurs.grisIndication),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                "Comment s'est passé\nl'aide ?",
                style: Styles.gras(
                  20,
                  Colors.black,
                  hauteur: 1.4,
                  poids: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      GestureDetector(
                        onTap: () => setState(() => _etoiles = i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            Icons.star,
                            size: 40,
                            color: i <= _etoiles
                                ? const Color(0xFFFFB800)
                                : Couleurs.grisBordure,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Container(
                height: 124,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  color: Couleurs.grisFond,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: Styles.ombre,
                ),
                child: TextField(
                  controller: _commentaire,
                  maxLines: null,
                  expands: true,
                  maxLength: _longueurMax,
                  buildCounter: (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
                  onChanged: (_) => setState(() {}),
                  textAlignVertical: TextAlignVertical.top,
                  style: Styles.gras(15.7, Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Ecrivez un commentaire...',
                    hintStyle: Styles.gras(14, Couleurs.grisIndication),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${_commentaire.text.length}/$_longueurMax',
                    style: Styles.gras(12.5, Couleurs.grisTexte),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Ajouter un commentaire (optionel)',
                style: Styles.gras(16.3, Colors.black),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final etiquette in _etiquettes)
                    GestureDetector(
                      onTap: () => setState(() {
                        if (!_etiquettesChoisies.remove(etiquette)) {
                          _etiquettesChoisies.add(etiquette);
                        }
                      }),
                      child: _Etiquette(
                        etiquette,
                        choisie: _etiquettesChoisies.contains(etiquette),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _enCours ? null : _envoyer,
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Couleurs.rouge,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: Styles.ombre,
                  ),
                  child: _enCours
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : Text('Envoyer', style: Styles.gras(15.5, Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Étiquette à cocher : rose quand elle est libre, rouge quand elle est choisie.
class _Etiquette extends StatelessWidget {
  const _Etiquette(this.texte, {required this.choisie});

  final String texte;
  final bool choisie;

  @override
  Widget build(BuildContext context) {
    return Puce(
      texte: texte,
      fond: choisie ? Couleurs.rouge : const Color(0xFFF8CFCF),
      couleurTexte: choisie ? Colors.white : Couleurs.rouge,
      taille: 12.3,
      ombre: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    );
  }
}
