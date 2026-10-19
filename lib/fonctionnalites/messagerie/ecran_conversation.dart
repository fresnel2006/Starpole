import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/format_temps.dart';
import '../../noyau/messagerie.dart';
import '../../noyau/position_utilisateur.dart';
import '../../noyau/service_localisation.dart';
import '../../noyau/service_photo.dart';
import '../../noyau/appel.dart';
import '../../noyau/service_appel.dart';
import '../../noyau/service_messagerie.dart';
import '../../noyau/service_notifications.dart';
import '../../partage/composants/avatar_utilisateur.dart';
import '../../partage/composants/vibrant.dart';
import '../../partage/composants/couche_tuiles.dart';
import '../../partage/composants/menu_trois_points.dart';
import '../../partage/styles.dart';
import '../appel/ecran_appel.dart';
import 'ecran_medias.dart';

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

  late final Stream<DateTime?> _luParAutre = _service.luParAutre(
    widget.conversationId,
    widget.autreId,
  );
  late final Stream<DateTime?> _presenceAutre = _service.presenceDe(
    widget.autreId,
  );

  final TextEditingController _saisie = TextEditingController();
  final FocusNode _focusSaisie = FocusNode();

  /// Vrai quand le panneau des emojis remplace le clavier.
  bool _emojisOuverts = false;

  /// Recherche dans la conversation (ouverte par le menu des trois points).
  final TextEditingController _requete = TextEditingController();
  bool _rechercheOuverte = false;
  final GlobalKey<VibrantState> _cleSaisie = GlobalKey();

  /// Le dernier message que j'ai marqué comme lu (pour ne pas le refaire).
  String? _dernierLu;
  bool _envoiEnCours = false;

  /// L'identifiant du dernier message de la conversation.
  String? _idDernier;

  /// Le message auquel je suis en train de répondre (glissé vers la gauche).
  Message? _reponseA;

  /// Mon message que je suis en train de modifier.
  Message? _enModification;

  @override
  void initState() {
    super.initState();
    _service.marquerLu(widget.conversationId);
    conversationAffichee.value = widget.conversationId;
  }

  @override
  void dispose() {
    if (conversationAffichee.value == widget.conversationId) {
      conversationAffichee.value = null;
    }
    _saisie.dispose();
    _focusSaisie.dispose();
    _requete.dispose();
    super.dispose();
  }

  void _afficherMessage(String texte, {String? action, VoidCallback? auAppui}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texte),
          action: action == null || auAppui == null
              ? null
              : SnackBarAction(label: action, onPressed: auAppui),
        ),
      );
  }

  /// Le nom à afficher pour l'auteur d'un message cité.
  String _nomDe(String? auteurId) =>
      auteurId == _service.utilisateurId ? 'Vous' : widget.autreNom;

  /// Prépare une réponse au message [message].
  void _repondre(Message message) {
    setState(() {
      if (_enModification != null) _saisie.clear();
      _enModification = null;
      _reponseA = message;
    });
  }

  /// Passe en mode modification : le texte du message revient dans la zone.
  void _modifier(Message message) {
    setState(() {
      _reponseA = null;
      _enModification = message;
      _saisie.text = message.texte;
      _saisie.selection = TextSelection.collapsed(offset: message.texte.length);
    });
  }

  void _annulerBandeau() {
    setState(() {
      if (_enModification != null) _saisie.clear();
      _reponseA = null;
      _enModification = null;
    });
  }

  /// Bascule entre le clavier et le panneau des emojis.
  void _basculerEmojis() {
    if (_emojisOuverts) {
      setState(() => _emojisOuverts = false);
      _focusSaisie.requestFocus();
    } else {
      _focusSaisie.unfocus();
      setState(() => _emojisOuverts = true);
    }
  }

  void _fermerRecherche() {
    setState(() {
      _rechercheOuverte = false;
      _requete.clear();
    });
  }

  /// Ce qui est choisi dans le menu des trois points de l'en-tête.
  Future<void> _choisirDansMenu(String choix) async {
    if (choix == 'rechercher') setState(() => _rechercheOuverte = true);
    if (choix == 'medias') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              EcranMedias(messages: _service.messages(widget.conversationId)),
        ),
      );
    }
  }

  /// Menu d'un message (appui long) : répondre, et modifier si c'est le mien.
  Future<void> _ouvrirMenu(Message message) async {
    final estMien = message.auteurId == _service.utilisateurId;
    final modifiable =
        estMien && message.photo == null && !message.aUnePosition;
    final choix = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (contexte) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _ActionMenu(
              icone: Icons.reply,
              texte: 'Répondre',
              auAppui: () => Navigator.of(contexte).pop('repondre'),
            ),
            if (modifiable)
              _ActionMenu(
                icone: Icons.edit_outlined,
                texte: 'Modifier',
                auAppui: () => Navigator.of(contexte).pop('modifier'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (choix == 'repondre') _repondre(message);
    if (choix == 'modifier') _modifier(message);
  }

  /// Le nombre de coches d'un message que j'ai envoyé : 1 envoyé, 2 la personne
  /// est connectée (reçu), 3 elle a lu la conversation.
  int _coches(Message message, DateTime? luLe, DateTime? vuLe) {
    if (luLe != null && !luLe.isBefore(message.creeLe)) return 3;
    if (vuLe != null &&
        (!vuLe.isBefore(message.creeLe) ||
            DateTime.now().difference(vuLe) < const Duration(seconds: 90))) {
      return 2;
    }
    return 1;
  }

  /// Le texte qu'on cite : celui du message, ou un mot pour une photo.
  String _resume(Message message) =>
      message.photo != null ? 'Photo' : message.texte;

  /// Envoie le message écrit (ou enregistre la modification). S'il est vide,
  /// la zone vibre et clignote.
  Future<void> _envoyer() async {
    final texte = _saisie.text.trim();
    if (texte.isEmpty) {
      _cleSaisie.currentState?.signalerErreur();
      return;
    }
    setState(() => _envoiEnCours = true);
    try {
      final modification = _enModification;
      if (modification != null) {
        if (texte != modification.texte) {
          await _service.modifierMessage(
            widget.conversationId,
            modification.id,
            texte,
            dernier: modification.id == _idDernier,
          );
        }
      } else {
        final citation = _reponseA;
        await _service.envoyerMessage(
          widget.conversationId,
          texte,
          reponseTexte: citation == null ? null : _resume(citation),
          reponseAuteurId: citation?.auteurId,
        );
      }
      if (mounted) {
        _saisie.clear();
        setState(() {
          _reponseA = null;
          _enModification = null;
        });
      }
    } on ErreurMessagerie catch (e) {
      if (mounted) _afficherMessage(e.message);
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  /// Envoie ma position actuelle, qui s'affiche sur une petite carte.
  Future<void> _envoyerPosition() async {
    if (_envoiEnCours) return;
    final position = context.read<PositionUtilisateur>();
    setState(() => _envoiEnCours = true);
    try {
      // À chaque appui, on demande l'autorisation si besoin et on prend la
      // position du moment.
      await position.actualiser();
      final lieu = position.lieu;
      final latitude = lieu?.latitude;
      final longitude = lieu?.longitude;
      if (lieu == null || latitude == null || longitude == null) {
        if (mounted) _expliquerPositionImpossible(position);
        return;
      }
      await _service.envoyerMessage(
        widget.conversationId,
        'Ma localisation : ${lieu.libelle}',
        latitude: latitude,
        longitude: longitude,
      );
    } on ErreurMessagerie catch (e) {
      if (mounted) _afficherMessage(e.message);
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  /// Dit pourquoi la position n'a pas pu être envoyée, avec un bouton pour
  /// y remédier (réglages du téléphone ou nouvelle demande).
  void _expliquerPositionImpossible(PositionUtilisateur position) {
    switch (position.resultat?.etat) {
      case EtatLocalisation.serviceDesactive:
        _afficherMessage(
          'Activez la localisation du téléphone pour envoyer votre position.',
          action: 'Réglages',
          auAppui: () => context.read<ServiceLocalisation>().ouvrirReglages(
            EtatLocalisation.serviceDesactive,
          ),
        );
      case EtatLocalisation.permissionBloquee:
        _afficherMessage(
          'Autorisez la localisation de StarPole dans les réglages.',
          action: 'Réglages',
          auAppui: () => context.read<ServiceLocalisation>().ouvrirReglages(
            EtatLocalisation.permissionBloquee,
          ),
        );
      case EtatLocalisation.permissionRefusee:
        _afficherMessage(
          'Sans autorisation, votre position ne peut pas être envoyée.',
          action: 'Réessayer',
          auAppui: _envoyerPosition,
        );
      default:
        _afficherMessage(
          'Position introuvable. Réessayez dans un instant.',
          action: 'Réessayer',
          auAppui: _envoyerPosition,
        );
    }
  }

  /// Ouvre le sélecteur de photos du téléphone, puis envoie la photo.
  Future<void> _envoyerPhoto() async {
    if (_envoiEnCours) return;
    final photos = context.read<ServicePhoto>();
    setState(() => _envoiEnCours = true);
    try {
      final octets = await photos.choisir(forme: FormePhoto.paysage);
      if (octets == null) return; // l'utilisateur a annulé
      await _service.envoyerMessage(
        widget.conversationId,
        'Photo',
        photo: octets,
      );
    } on ErreurPhoto catch (e) {
      if (mounted) _afficherMessage(e.message);
    } on ErreurMessagerie catch (e) {
      if (mounted) _afficherMessage(e.message);
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  /// Lance un appel (voix ou vidéo) avec l'autre personne, par Internet.
  Future<void> _appeler({required bool video}) async {
    try {
      final session = await context.read<ServiceAppel>().appeler(
        Contact(id: widget.autreId, nom: widget.autreNom),
        video: video,
      );
      if (!mounted) {
        session.dispose();
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => EcranAppel(
            session: session,
            autreId: widget.autreId,
            autreNom: widget.autreNom,
          ),
        ),
      );
    } on ErreurAppel catch (e) {
      if (mounted) _afficherMessage(e.message);
    }
  }

  /// Quand l'autre personne écrit pendant que la conversation est ouverte, on
  /// la marque comme lue.
  void _marquerLuSiBesoin(List<Message> messages) {
    if (messages.isEmpty) return;
    final dernier = messages.last;
    _idDernier = dernier.id;
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
            if (_rechercheOuverte)
              _EnteteRecherche(
                controleur: _requete,
                auChangement: () => setState(() {}),
                auFermer: _fermerRecherche,
              )
            else
              _Entete(
                autreId: widget.autreId,
                autreNom: widget.autreNom,
                auAppel: () => _appeler(video: false),
                auVideo: () => _appeler(video: true),
                auChoix: _choisirDansMenu,
              ),
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
                  final recherche = _requete.text.trim().toLowerCase();
                  final visibles = recherche.isEmpty
                      ? messages
                      : messages
                            .where(
                              (m) => m.texte.toLowerCase().contains(recherche),
                            )
                            .toList();
                  final inverses = visibles.reversed.toList();
                  return _Statuts(
                    luParAutre: _luParAutre,
                    presenceAutre: _presenceAutre,
                    builder: (luLe, vuLe) => visibles.isEmpty
                        ? const _Centre('Aucun message.')
                        : ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                            itemCount: inverses.length,
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _Glissable(
                                auGlisse: () => _repondre(inverses[i]),
                                auLongAppui: () => _ouvrirMenu(inverses[i]),
                                child: _Bulle(
                                  message: inverses[i],
                                  envoye: inverses[i].auteurId == moi,
                                  nomCite: _nomDe(inverses[i].reponseAuteurId),
                                  coches: inverses[i].auteurId == moi
                                      ? _coches(inverses[i], luLe, vuLe)
                                      : 0,
                                ),
                              ),
                            ),
                          ),
                  );
                },
              ),
            ),
            if (_reponseA != null || _enModification != null)
              _BandeauReponse(
                titre: _enModification != null
                    ? 'Modification du message'
                    : 'Réponse à ${_nomDe(_reponseA!.auteurId)}',
                texte: _resume(_enModification ?? _reponseA!),
                auFermer: _annulerBandeau,
              ),
            _ZoneSaisie(
              controleur: _saisie,
              cle: _cleSaisie,
              envoiEnCours: _envoiEnCours,
              envoyer: _envoyer,
              envoyerPosition: _envoyerPosition,
              envoyerPhoto: _envoyerPhoto,
              focus: _focusSaisie,
              emojisOuverts: _emojisOuverts,
              auEmoji: _basculerEmojis,
              auChampTouche: () {
                if (_emojisOuverts) setState(() => _emojisOuverts = false);
              },
            ),
            if (_emojisOuverts)
              EmojiPicker(
                textEditingController: _saisie,
                config: Config(
                  height: 260,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    backgroundColor: Colors.white,
                    emojiSizeMax: 28,
                  ),
                  categoryViewConfig: const CategoryViewConfig(
                    backgroundColor: Colors.white,
                    indicatorColor: Couleurs.rouge,
                    iconColorSelected: Couleurs.rouge,
                  ),
                  bottomActionBarConfig: const BottomActionBarConfig(
                    backgroundColor: Colors.white,
                    buttonColor: Colors.white,
                    buttonIconColor: Couleurs.rouge,
                  ),
                  searchViewConfig: const SearchViewConfig(
                    backgroundColor: Colors.white,
                  ),
                ),
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
  const _Entete({
    required this.autreId,
    required this.autreNom,
    required this.auAppel,
    required this.auVideo,
    required this.auChoix,
  });

  final String autreId;
  final String autreNom;
  final VoidCallback auAppel;
  final VoidCallback auVideo;
  final ValueChanged<String> auChoix;

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
          Semantics(
            button: true,
            label: 'Appeler',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: auAppel,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.phone_in_talk_outlined,
                  size: 26,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            label: 'Appel vidéo',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: auVideo,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.videocam_outlined,
                  size: 30,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          MenuTroisPoints(
            auChoix: auChoix,
            entrees: const [
              EntreeMenu(
                valeur: 'rechercher',
                icone: Icons.search,
                texte: 'Rechercher un message',
              ),
              EntreeMenu(
                valeur: 'medias',
                icone: Icons.photo_library_outlined,
                texte: 'Photos et positions',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// En-tête de la recherche : flèche pour fermer et champ de saisie.
class _EnteteRecherche extends StatelessWidget {
  const _EnteteRecherche({
    required this.controleur,
    required this.auChangement,
    required this.auFermer,
  });

  final TextEditingController controleur;
  final VoidCallback auChangement;
  final VoidCallback auFermer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 10),
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
            onTap: auFermer,
            child: const SizedBox(
              width: 38,
              height: 40,
              child: Icon(Icons.chevron_left, size: 34, color: Colors.black),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controleur,
              autofocus: true,
              onChanged: (_) => auChangement(),
              style: Styles.gras(13, Colors.black),
              decoration: InputDecoration(
                hintText: 'Rechercher un message',
                hintStyle: Styles.gras(12.5, Couleurs.grisIndication),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bulle extends StatelessWidget {
  const _Bulle({
    required this.message,
    required this.envoye,
    required this.nomCite,
    required this.coches,
  });

  final Message message;
  final bool envoye;

  /// Coches d'un message envoyé (0 pour un message reçu).
  final int coches;

  /// Le nom de l'auteur du message cité (« Vous » ou l'autre personne).
  final String nomCite;

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
              if (message.estUneReponse) ...[
                _Citation(
                  nom: nomCite,
                  texte: message.reponseTexte!,
                  surRouge: envoye,
                ),
                const SizedBox(height: 6),
              ],
              if (message.photo != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 2,
                    child: Image.memory(
                      message.photo!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              if (message.aUnePosition) ...[
                _CartePosition(
                  latitude: message.latitude!,
                  longitude: message.longitude!,
                ),
                const SizedBox(height: 6),
              ],
              // Une photo seule n'a pas besoin du mot « Photo » sous l'image.
              if (message.photo == null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    message.texte,
                    style: Styles.gras(12.5, couleurTexte, hauteur: 1.5),
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.modifie
                        ? 'Modifié  ${heureCourte(message.creeLe)}'
                        : heureCourte(message.creeLe),
                    style: Styles.gras(9, couleurHeure, poids: FontWeight.w500),
                  ),
                  if (coches > 0) ...[
                    const SizedBox(width: 5),
                    _Coches(nombre: coches),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Suit en direct la lecture et la présence de l'autre personne.
class _Statuts extends StatelessWidget {
  const _Statuts({
    required this.luParAutre,
    required this.presenceAutre,
    required this.builder,
  });

  final Stream<DateTime?> luParAutre;
  final Stream<DateTime?> presenceAutre;
  final Widget Function(DateTime? luLe, DateTime? vuLe) builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime?>(
      stream: luParAutre,
      builder: (context, lu) => StreamBuilder<DateTime?>(
        stream: presenceAutre,
        builder: (context, presence) => builder(lu.data, presence.data),
      ),
    );
  }
}

/// Les coches d'un message envoyé : une (envoyé), deux (reçu) ou trois (vu).
class _Coches extends StatelessWidget {
  const _Coches({required this.nombre});

  final int nombre;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: switch (nombre) {
        1 => 'Envoyé',
        2 => 'Reçu',
        _ => 'Vu',
      },
      child: SizedBox(
        width: 12 + (nombre - 1) * 5.0,
        height: 12,
        child: Stack(
          children: [
            for (var i = 0; i < nombre; i++)
              Positioned(
                left: i * 5.0,
                child: Icon(
                  Icons.check,
                  size: 12,
                  color: nombre == 3 ? Colors.white : const Color(0xB3FFFFFF),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Le message cité dans une réponse.
class _Citation extends StatelessWidget {
  const _Citation({
    required this.nom,
    required this.texte,
    required this.surRouge,
  });

  final String nom;
  final String texte;
  final bool surRouge;

  @override
  Widget build(BuildContext context) {
    final fond = surRouge ? const Color(0x33FFFFFF) : const Color(0xFFE3EBE8);
    final couleurNom = surRouge ? Colors.white : Couleurs.rouge;
    final couleurTexte = surRouge ? const Color(0xE6FFFFFF) : Colors.black87;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nom, style: Styles.gras(10.5, couleurNom)),
          Text(
            texte,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Styles.gras(
              11,
              couleurTexte,
              hauteur: 1.4,
              poids: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fait glisser un message vers la droite pour y répondre (comme WhatsApp) ;
/// un appui long ouvre le menu du message.
class _Glissable extends StatefulWidget {
  const _Glissable({
    required this.child,
    required this.auGlisse,
    required this.auLongAppui,
  });

  final Widget child;
  final VoidCallback auGlisse;
  final VoidCallback auLongAppui;

  @override
  State<_Glissable> createState() => _GlissableState();
}

class _GlissableState extends State<_Glissable> {
  static const double _seuil = 56;
  double _decalage = 0;

  @override
  Widget build(BuildContext context) {
    final progression = (_decalage / _seuil).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: widget.auLongAppui,
      onHorizontalDragUpdate: (d) => setState(
        () => _decalage = (_decalage + d.delta.dx).clamp(0.0, _seuil * 1.4),
      ),
      onHorizontalDragEnd: (_) {
        if (_decalage >= _seuil) widget.auGlisse();
        setState(() => _decalage = 0);
      },
      onHorizontalDragCancel: () => setState(() => _decalage = 0),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Opacity(
            opacity: progression,
            child: const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.reply, size: 22, color: Couleurs.grisTexte),
            ),
          ),
          Transform.translate(
            offset: Offset(_decalage, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// Une ligne du menu d'un message.
class _ActionMenu extends StatelessWidget {
  const _ActionMenu({
    required this.icone,
    required this.texte,
    required this.auAppui,
  });

  final IconData icone;
  final String texte;
  final VoidCallback auAppui;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: auAppui,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        child: Row(
          children: [
            Icon(icone, size: 24, color: Colors.black),
            const SizedBox(width: 16),
            Text(texte, style: Styles.gras(14, Colors.black)),
          ],
        ),
      ),
    );
  }
}

/// Bandeau au-dessus de la zone de saisie : message auquel on répond, ou
/// message en cours de modification.
class _BandeauReponse extends StatelessWidget {
  const _BandeauReponse({
    required this.titre,
    required this.texte,
    required this.auFermer,
  });

  final String titre;
  final String texte;
  final VoidCallback auFermer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: Styles.gras(11, Couleurs.rouge)),
                Text(
                  texte,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Styles.gras(
                    11.5,
                    Colors.black87,
                    poids: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'Annuler',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: auFermer,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.close, size: 20, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une petite carte avec l'épingle, pour une position reçue ou envoyée.
class _CartePosition extends StatelessWidget {
  const _CartePosition({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: 2,
        child: IgnorePointer(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              tuilesCarte(context),
              mentionCarte(petite: true),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 30,
                    height: 30,
                    child: const Icon(
                      Icons.location_on,
                      size: 30,
                      color: Couleurs.rouge,
                    ),
                  ),
                ],
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
    required this.envoyerPosition,
    required this.envoyerPhoto,
    required this.focus,
    required this.emojisOuverts,
    required this.auEmoji,
    required this.auChampTouche,
  });

  final FocusNode focus;
  final bool emojisOuverts;
  final VoidCallback auEmoji;
  final VoidCallback auChampTouche;
  final TextEditingController controleur;
  final GlobalKey<VibrantState> cle;
  final bool envoiEnCours;
  final VoidCallback envoyer;
  final VoidCallback envoyerPosition;
  final VoidCallback envoyerPhoto;

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
                        Semantics(
                          button: true,
                          label: emojisOuverts ? 'Clavier' : 'Emojis',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: auEmoji,
                            child: Icon(
                              emojisOuverts
                                  ? Icons.keyboard_outlined
                                  : Icons.sentiment_satisfied_alt,
                              size: 24,
                              color: const Color(0xFFFFB300),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: controleur,
                            focusNode: focus,
                            onTap: auChampTouche,
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
          Row(
            children: [
              _BoutonRaccourci(
                icone: Icons.location_on_outlined,
                texte: 'Localisation',
                auAppui: envoyerPosition,
              ),
              const SizedBox(width: 14),
              _BoutonRaccourci(
                icone: Icons.photo_camera,
                texte: 'Photo',
                auAppui: envoyerPhoto,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BoutonRaccourci extends StatelessWidget {
  const _BoutonRaccourci({
    required this.icone,
    required this.texte,
    required this.auAppui,
  });

  final IconData icone;
  final String texte;
  final VoidCallback auAppui;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: auAppui, child: _contenu());
  }

  Widget _contenu() {
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
