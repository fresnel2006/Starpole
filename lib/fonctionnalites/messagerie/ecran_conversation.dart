import 'package:flutter/material.dart';

import '../../application/couleurs.dart';
import '../../partage/composants/avatar_personne.dart';
import '../../partage/styles.dart';

/// Un message affiché dans une conversation.
class MessageDemo {
  const MessageDemo({
    this.texte = '',
    required this.envoye,
    required this.heure,
    this.avecCoeur = false,
    this.localisation = false,
  });

  final String texte;

  /// Vrai si le message vient de moi (bulle rouge à droite).
  final bool envoye;
  final String heure;

  /// Ajoute un petit coeur après le texte.
  final bool avecCoeur;

  /// Message de type « localisation » (vignette avec la photo du lieu).
  final bool localisation;
}

/// Une personne avec qui l'on discute (données de démonstration).
class ContactDemo {
  const ContactDemo({
    required this.nom,
    required this.enLigne,
    required this.couleurAvatar,
    required this.messages,
  });

  final String nom;
  final bool enLigne;
  final Color couleurAvatar;
  final List<MessageDemo> messages;

  static const ContactDemo mariam = ContactDemo(
    nom: 'Mariam',
    enLigne: true,
    couleurAvatar: Color(0xFFE7B7B7),
    messages: [
      MessageDemo(
        texte:
            'Bonjour, je peux vous vous aider.\nJ\'habite pas loin de votre\n'
            'localisation',
        envoye: false,
        heure: '14:01',
      ),
      MessageDemo(
        texte: 'Merci beaucoup !',
        envoye: true,
        heure: '14:02',
        avecCoeur: true,
      ),
    ],
  );

  static const ContactDemo kouadio = ContactDemo(
    nom: 'Kouadio Eliezer',
    enLigne: true,
    couleurAvatar: Color(0xFFBDBDBD),
    messages: [
      MessageDemo(
        texte: 'Bonjour monsieur est ce que l\'urgence est toujours valable ?',
        envoye: true,
        heure: '14:02',
      ),
      MessageDemo(
        texte: 'Oui oui je vous envois la localisation !',
        envoye: false,
        heure: '14:02',
      ),
      MessageDemo(envoye: false, heure: '14:03', localisation: true),
    ],
  );
}

/// Écran de conversation : en-tête, messages, zone de saisie et raccourcis.
class EcranConversation extends StatelessWidget {
  const EcranConversation({super.key, required this.contact});

  final ContactDemo contact;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _Entete(contact: contact),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
                children: [
                  for (final message in contact.messages)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _Bulle(message: message),
                    ),
                ],
              ),
            ),
            const _ZoneSaisie(),
          ],
        ),
      ),
    );
  }
}

class _Entete extends StatelessWidget {
  const _Entete({required this.contact});

  final ContactDemo contact;

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
          AvatarPersonne(taille: 46, couleurFond: contact.couleurAvatar),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Styles.gras(14.5, Colors.black),
                ),
                if (contact.enLigne)
                  Text('En ligne', style: Styles.gras(12, Couleurs.rouge)),
              ],
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
  const _Bulle({required this.message});

  final MessageDemo message;

  @override
  Widget build(BuildContext context) {
    final largeurMax = MediaQuery.sizeOf(context).width * 0.66;
    final couleurTexte = message.envoye ? Colors.white : Colors.black;
    final couleurHeure = message.envoye
        ? const Color(0xCCFFFFFF)
        : Couleurs.grisIndication;

    final contenu = message.localisation
        ? const _VignetteLocalisation()
        : Text.rich(
            TextSpan(
              style: Styles.gras(12.5, couleurTexte, hauteur: 1.5),
              children: [
                TextSpan(text: message.texte),
                if (message.avecCoeur) ...[
                  const TextSpan(text: ' '),
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      Icons.favorite,
                      size: 16,
                      color: Color(0xFFFFB300),
                    ),
                  ),
                ],
              ],
            ),
          );

    return Align(
      alignment: message.envoye ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: largeurMax),
        child: Container(
          padding: message.localisation
              ? EdgeInsets.zero
              : const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: message.envoye
                ? Couleurs.rouge
                : (message.localisation
                      ? Colors.transparent
                      : const Color(0xFFF1F6F4)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(alignment: Alignment.centerLeft, child: contenu),
              if (!message.localisation) ...[
                const SizedBox(height: 4),
                Text(
                  message.heure,
                  style: Styles.gras(9, couleurHeure, poids: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Vignette « Localisation » : la photo du lieu et son étiquette.
class _VignetteLocalisation extends StatelessWidget {
  const _VignetteLocalisation();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: Styles.ombre,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 96,
            color: const Color(0xFFD8D2CC),
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_outlined,
              size: 36,
              color: Colors.white,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.black),
                const SizedBox(width: 5),
                Text('Localisation', style: Styles.gras(10.5, Colors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Zone du bas : champ de saisie, bouton d'envoi et deux raccourcis.
class _ZoneSaisie extends StatelessWidget {
  const _ZoneSaisie();

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
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Couleurs.rouge,
                  shape: BoxShape.circle,
                  boxShadow: Styles.ombre,
                ),
                child: const Icon(Icons.send, size: 22, color: Colors.white),
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
