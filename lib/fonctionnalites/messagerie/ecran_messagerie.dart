import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/messagerie.dart';
import '../../noyau/service_messagerie.dart';
import '../../partage/composants/avatar_utilisateur.dart';
import '../../partage/composants/champ_recherche.dart';
import '../../partage/composants/puce.dart';
import '../../partage/styles.dart';
import 'ecran_contacts.dart';
import 'ecran_conversation.dart';

/// Onglet Message : la liste de mes vraies conversations, en direct.
class EcranMessagerie extends StatefulWidget {
  const EcranMessagerie({super.key});

  @override
  State<EcranMessagerie> createState() => _EcranMessagerieState();
}

class _EcranMessagerieState extends State<EcranMessagerie> {
  late final Stream<List<Conversation>> _flux = context
      .read<ServiceMessagerie>()
      .conversations();

  /// Filtre choisi : vrai pour « Tous », faux pour « Groupes ».
  bool _tousChoisi = true;
  String _recherche = '';

  void _ouvrir(Conversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EcranConversation(
          conversationId: conversation.id,
          autreId: conversation.autreId,
          autreNom: conversation.autreNom,
        ),
      ),
    );
  }

  void _nouvelleConversation() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const EcranContacts()));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Messagerie',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Styles.gras(24, Colors.black),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Puce(
                            texte: "Appels d'urgence",
                            fond: Couleurs.fondPuceRouge,
                            couleurTexte: Couleurs.rouge,
                            taille: 11,
                            ombre: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ChampRecherche(
                        indication: 'Rechercher une conversation',
                        auChangement: (texte) =>
                            setState(() => _recherche = texte),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _Filtre(
                            texte: 'Tous',
                            choisi: _tousChoisi,
                            auAppui: () => setState(() => _tousChoisi = true),
                          ),
                          const SizedBox(width: 12),
                          _Filtre(
                            texte: 'Groupes',
                            choisi: !_tousChoisi,
                            auAppui: () => setState(() => _tousChoisi = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(height: 1, color: Couleurs.grisBordure),
                    ],
                  ),
                ),
                Expanded(
                  child: !_tousChoisi
                      ? const _Message(
                          'Les groupes de discussion arrivent bientôt.',
                        )
                      : StreamBuilder<List<Conversation>>(
                          stream: _flux,
                          builder: (context, instantane) {
                            if (instantane.hasError) {
                              return const _Message(
                                'Impossible de charger vos conversations. '
                                'Vérifiez votre connexion.',
                              );
                            }
                            final toutes = instantane.data;
                            if (toutes == null) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Couleurs.rouge,
                                ),
                              );
                            }
                            final mot = _recherche.trim().toLowerCase();
                            final liste = toutes
                                .where(
                                  (c) =>
                                      mot.isEmpty ||
                                      c.autreNom.toLowerCase().contains(mot),
                                )
                                .toList();
                            if (liste.isEmpty) {
                              return _Message(
                                toutes.isEmpty
                                    ? "Aucune conversation pour l'instant.\n"
                                          'Appuyez sur le bouton en bas pour '
                                          'écrire à un contact.'
                                    : 'Aucun résultat pour cette recherche.',
                              );
                            }
                            return ListView(
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                0,
                                22,
                                110,
                              ),
                              children: [
                                for (var i = 0; i < liste.length; i++)
                                  _LigneConversation(
                                    conversation: liste[i],
                                    dernier: i == liste.length - 1,
                                    auAppui: () => _ouvrir(liste[i]),
                                  ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          // Bouton flottant « nouvelle conversation ».
          Positioned(
            right: 28,
            bottom: 28,
            child: Semantics(
              button: true,
              label: 'Nouvelle conversation',
              child: GestureDetector(
                onTap: _nouvelleConversation,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: Styles.ombre,
                  ),
                  child: const Icon(
                    Icons.forum,
                    size: 30,
                    color: Couleurs.rouge,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Étiquette de filtre (Tous, Groupes) : rouge quand elle est choisie, grise
/// sinon, toujours avec l'effet en creux.
class _Filtre extends StatelessWidget {
  const _Filtre({
    required this.texte,
    required this.choisi,
    required this.auAppui,
  });

  final String texte;
  final bool choisi;
  final VoidCallback auAppui;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: auAppui,
      child: Puce(
        texte: texte,
        fond: choisi ? Couleurs.rouge : const Color(0xFFE6E6E6),
        couleurTexte: choisi ? Colors.white : Couleurs.rouge,
        taille: 11.5,
        enCreux: true,
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 5),
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
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Text(
          texte,
          textAlign: TextAlign.center,
          style: Styles.gras(13, Couleurs.grisTexte, hauteur: 1.5),
        ),
      ),
    );
  }
}

/// « 14:25 » aujourd'hui, « Hier », sinon « 12/10 ».
String _heureOuJour(DateTime date) {
  final maintenant = DateTime.now();
  final aujourdhui = DateTime(
    maintenant.year,
    maintenant.month,
    maintenant.day,
  );
  final jour = DateTime(date.year, date.month, date.day);
  final ecart = aujourdhui.difference(jour).inDays;
  if (ecart <= 0) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
  if (ecart == 1) return 'Hier';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}';
}

class _LigneConversation extends StatelessWidget {
  const _LigneConversation({
    required this.conversation,
    required this.auAppui,
    required this.dernier,
  });

  final Conversation conversation;
  final VoidCallback auAppui;
  final bool dernier;

  @override
  Widget build(BuildContext context) {
    final apercu = conversation.dernierParMoi
        ? 'Vous : ${conversation.dernierMessage}'
        : conversation.dernierMessage;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: auAppui,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                AvatarUtilisateur(id: conversation.autreId, taille: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.autreNom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Styles.gras(15.5, Colors.black),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        apercu,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Styles.gras(
                          11,
                          Colors.black,
                          poids: conversation.nonLu
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _heureOuJour(conversation.dernierTemps),
                      style: Styles.gras(
                        10.5,
                        Couleurs.rouge,
                        poids: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (conversation.nonLu)
                      Container(
                        key: const ValueKey('non-lu'),
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Couleurs.rouge,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 14),
                  ],
                ),
              ],
            ),
          ),
          if (!dernier) Container(height: 1, color: Couleurs.grisBordure),
        ],
      ),
    );
  }
}
