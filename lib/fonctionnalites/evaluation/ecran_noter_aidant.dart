import 'package:flutter/material.dart';

import '../../application/couleurs.dart';
import '../../partage/composants/avatar_personne.dart';
import '../../partage/composants/entete_retour.dart';
import '../../partage/composants/puce.dart';
import '../../partage/styles.dart';

/// Note donnée à la personne qui a aidé : étoiles, commentaire et étiquettes.
class EcranNoterAidant extends StatefulWidget {
  const EcranNoterAidant({super.key});

  @override
  State<EcranNoterAidant> createState() => _EcranNoterAidantState();
}

class _EcranNoterAidantState extends State<EcranNoterAidant> {
  static const int _longueurMax = 200;

  final TextEditingController _commentaire = TextEditingController(
    text: 'Il a ete tres rapide et tres gentil',
  );
  int _etoiles = 5;

  @override
  void dispose() {
    _commentaire.dispose();
    super.dispose();
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
              const EnteteRetour(titre: "Noter l'aidant"),
              const SizedBox(height: 18),
              Row(
                children: [
                  const AvatarPersonne(
                    taille: 84,
                    couleurFond: Color(0xFFD9A58B),
                    avecOmbre: true,
                  ),
                  const SizedBox(width: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kouadio', style: Styles.gras(18, Colors.black)),
                      Text(
                        'Citoyen benevol',
                        style: Styles.gras(12.5, Couleurs.grisIndication),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                "Comment s'est passé\nl'aide ?",
                style: Styles.gras(
                  15.5,
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
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.star,
                            size: 46,
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
                height: 120,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                decoration: BoxDecoration(
                  color: Couleurs.grisFond,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Couleurs.grisBordure),
                ),
                child: Column(
                  children: [
                    Expanded(
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
                        style: Styles.gras(13, Colors.black),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_commentaire.text.length}/$_longueurMax',
                        style: Styles.gras(10.5, Couleurs.grisTexte),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Ajouter un commentaire (optionel)',
                style: Styles.gras(12.5, Colors.black),
              ),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _Etiquette('Efficace'),
                  _Etiquette('Rapide'),
                  _Etiquette('mechant'),
                  _Etiquette('cool'),
                ],
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Couleurs.rouge,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: Styles.ombre,
                  ),
                  child: Text('Envoyer', style: Styles.gras(15, Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Etiquette extends StatelessWidget {
  const _Etiquette(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Puce(
      texte: texte,
      fond: const Color(0xFFF8CFCF),
      couleurTexte: Couleurs.rouge,
      taille: 10.5,
      ombre: true,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    );
  }
}
