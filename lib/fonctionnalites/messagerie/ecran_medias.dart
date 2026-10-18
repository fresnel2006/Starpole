import 'package:flutter/material.dart';

import '../../application/couleurs.dart';
import '../../noyau/format_temps.dart';
import '../../noyau/messagerie.dart';
import '../../partage/composants/entete_retour.dart';
import '../../partage/styles.dart';

/// Les photos et les positions échangées dans une conversation.
class EcranMedias extends StatelessWidget {
  const EcranMedias({super.key, required this.messages});

  /// Les messages de la conversation, en direct.
  final Stream<List<Message>> messages;

  /// Affiche une photo en grand ; un appui la ferme.
  void _agrandir(BuildContext context, Message message) {
    showDialog<void>(
      context: context,
      builder: (contexte) => GestureDetector(
        onTap: () => Navigator.of(contexte).pop(),
        child: InteractiveViewer(
          child: Center(child: Image.memory(message.photo!)),
        ),
      ),
    );
  }

  Widget _titre(String texte) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Text(texte, style: Styles.gras(13, Couleurs.rouge)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EnteteRetour(titre: 'Photos et positions'),
              Expanded(
                child: StreamBuilder<List<Message>>(
                  stream: messages,
                  builder: (context, instantane) {
                    final tous = instantane.data;
                    if (tous == null) {
                      return const Center(
                        child: CircularProgressIndicator(color: Couleurs.rouge),
                      );
                    }
                    final photos = tous.where((m) => m.photo != null).toList();
                    final positions = tous
                        .where((m) => m.aUnePosition)
                        .toList();
                    if (photos.isEmpty && positions.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucune photo ni position partagée pour le moment.',
                          textAlign: TextAlign.center,
                          style: Styles.gras(13, Couleurs.grisTexte),
                        ),
                      );
                    }
                    return ListView(
                      children: [
                        if (photos.isNotEmpty) ...[
                          _titre('Photos'),
                          GridView.count(
                            crossAxisCount: 3,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              for (final photo in photos.reversed)
                                GestureDetector(
                                  onTap: () => _agrandir(context, photo),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      photo.photo!,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        if (positions.isNotEmpty) ...[
                          _titre('Positions'),
                          for (final position in positions.reversed)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 24,
                                    color: Couleurs.rouge,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      position.texte,
                                      style: Styles.gras(
                                        12.5,
                                        Colors.black,
                                        poids: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    heureCourte(position.creeLe),
                                    style: Styles.gras(
                                      10,
                                      Couleurs.grisIndication,
                                      poids: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        const SizedBox(height: 20),
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
