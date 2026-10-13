import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/format_temps.dart';
import '../../noyau/messagerie.dart';
import '../../noyau/service_messagerie.dart';
import '../../partage/composants/avatar_utilisateur.dart';
import '../../partage/composants/vibrant.dart';
import '../../partage/styles.dart';

/// Une conversation avec une autre personne : ses messages en direct, la zone
/// pour écrire et l'envoi.
class EcranConversation extends StatefulWidget {
  const EcranConversation({
    super.key,
    required this.conversationId,
    required this.autreId,
    required this.autreNom,
  });

  final String conversationId;
  final String autreId;
  final String autreNom;

  @override
  State<EcranConversation> createState() => _EcranConversationState();
}

class _EcranConversationState extends State<EcranConversation> {
  late final ServiceMessagerie _service = context.read<ServiceMessagerie>();
  late final Stream<List<Message>> _flux = _service.messages(
    widget.conversationId,
  );

  final TextEditingController _saisie = TextEditingController();
  final GlobalKey<VibrantState> _cleSaisie = GlobalKey();

  /// Le dernier message que j'ai marqué comme lu (pour ne pas le refaire).
  String? _dernierLu;
  bool _envoiEnCours = false;

  @override
  void initState() {
    super.initState();
    _service.marquerLu(widget.conversationId);
  }

  @override
  void dispose() {
    _saisie.dispose();
    super.dispose();
  }

  void _afficherMessage(String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texte)));
  }

  /// Envoie le message écrit. S'il est vide, la zone vibre et clignote.
  Future<void> _envoyer() async {
    final texte = _saisie.text.trim();
    if (texte.isEmpty) {
      _cleSaisie.currentState?.signalerErreur();
      return;
    }
    setState(() => _envoiEnCours = true);
    try {
      await _service.envoyerMessage(widget.conversationId, texte);
      if (mounted) _saisie.clear();
    } on ErreurMessagerie catch (e) {
      if (mounted) _afficherMessage(e.message);
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  /// Quand l'autre personne écrit pendant que la conversation est ouverte, on
  /// la marque comme lue.
  void _marquerLuSiBesoin(List<Message> messages) {
    if (messages.isEmpty) return;
    final dernier = messages.last;
    if (dernier.auteurId == _service.utilisateurId) return;
    if (dernier.id == _dernierLu) return;
    _dernierLu = dernier.id;
    _service.marquerLu(widget.conversationId);
  }

  @override
  Widget build(BuildContext context) {
    final moi = _service.utilisateurId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _Entete(autreId: widget.autreId, autreNom: widget.autreNom),
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: _flux,
                builder: (context, instantane) {
                  if (instantane.hasError) {
                    return const _Centre(
                      'Impossible de charger les messages. '
                      'Vérifiez votre connexion.',
                    );
                  }
                  final messages = instantane.data;
                  if (messages == null) {
                    return const Center(
                      child: CircularProgressIndicator(color: Couleurs.rouge),
                    );
                  }
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _marquerLuSiBesoin(messages),
                  );
                  if (messages.isEmpty) {
                    return _Centre('Dites bonjour à ${widget.autreNom}.');
                  }
                  // La liste est « à l'envers » : le dernier message est en bas
                  // et reste visible quand il arrive.
                  final inverses = messages.reversed.toList();
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                    itemCount: inverses.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _Bulle(
                        message: inverses[i],
                        envoye: inverses[i].auteurId == moi,
                      ),
                    ),
                  );
                },
              ),
            ),
            _ZoneSaisie(
              controleur: _saisie,
              cle: _cleSaisie,
              envoiEnCours: _envoiEnCours,
              envoyer: _envoyer,
            ),
          ],
        ),
      ),
    );
  }
}

class _Centre extends StatelessWidget {
  const _Centre(this.texte);

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

class _Entete extends StatelessWidget {
  const _Entete({required this.autreId, required this.autreNom});

  final String autreId;
  final String autreNom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const SizedBox(
              width: 38,
              height: 40,
              child: Icon(Icons.chevron_left, size: 34, color: Colors.black),
            ),
          ),
          const SizedBox(width: 6),
          AvatarUtilisateur(id: autreId, taille: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              autreNom,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Styles.gras(15, Colors.black),
            ),
          ),
          const Icon(
            Icons.phone_in_talk_outlined,
            size: 26,
            color: Colors.black,
          ),
          const SizedBox(width: 18),
          const Icon(Icons.videocam_outlined, size: 30, color: Colors.black),
          const SizedBox(width: 12),
          const Icon(Icons.more_vert, size: 24, color: Colors.black),
        ],
      ),
    );
  }
}

class _Bulle extends StatelessWidget {
  const _Bulle({required this.message, required this.envoye});

  final Message message;
  final bool envoye;

  @override
  Widget build(BuildContext context) {
    final largeurMax = MediaQuery.sizeOf(context).width * 0.72;
    final couleurTexte = envoye ? Colors.white : Colors.black;
    final couleurHeure = envoye
        ? const Color(0xCCFFFFFF)
        : Couleurs.grisIndication;

    return Align(
      alignment: envoye ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: largeurMax),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: envoye ? Couleurs.rouge : const Color(0xFFF1F6F4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message.texte,
                  style: Styles.gras(12.5, couleurTexte, hauteur: 1.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                heureCourte(message.creeLe),
                style: Styles.gras(9, couleurHeure, poids: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Zone du bas : champ de saisie, bouton d'envoi et deux raccourcis.
class _ZoneSaisie extends StatelessWidget {
  const _ZoneSaisie({
    required this.controleur,
    required this.cle,
    required this.envoiEnCours,
    required this.envoyer,
  });

  final TextEditingController controleur;
  final GlobalKey<VibrantState> cle;
  final bool envoiEnCours;
  final VoidCallback envoyer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Vibrant(
                  key: cle,
                  rayon: 22,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Couleurs.grisBordure),
                      boxShadow: Styles.ombre,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sentiment_satisfied_alt,
                          size: 24,
                          color: Color(0xFFFFB300),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: controleur,
                            maxLength: 1000,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => envoyer(),
                            buildCounter: (
                              _, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) => null,
                            style: Styles.gras(12, Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Ecrivez un message...',
                              hintStyle: Styles.gras(
                                11.5,
                                Couleurs.grisIndication,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Semantics(
                button: true,
                label: 'Envoyer le message',
                child: GestureDetector(
                  onTap: envoiEnCours ? null : envoyer,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Couleurs.rouge,
                      shape: BoxShape.circle,
                      boxShadow: Styles.ombre,
                    ),
                    child: envoiEnCours
                        ? const Padding(
                            padding: EdgeInsets.all(11),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, size: 22, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _BoutonRaccourci(
                icone: Icons.location_on_outlined,
                texte: 'Localisation',
              ),
              SizedBox(width: 14),
              _BoutonRaccourci(icone: Icons.photo_camera, texte: 'Photo'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BoutonRaccourci extends StatelessWidget {
  const _BoutonRaccourci({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Couleurs.rouge,
        borderRadius: BorderRadius.circular(15),
        boxShadow: Styles.ombre,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(texte, style: Styles.gras(11, Colors.white)),
        ],
      ),
    );
  }
}
