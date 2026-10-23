import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'appel.dart';
import 'serveur_starpole.dart';
import 'messagerie.dart';

/// Un appel en cours (sortant ou entrant), vu par l'écran d'appel.
abstract class SessionAppel {
  bool get video;
  ValueListenable<EtatAppel> get etat;
  ValueListenable<bool> get microCoupe;
  ValueListenable<bool> get cameraCoupee;
  ValueListenable<bool> get hautParleur;

  void basculerMicro();
  void basculerCamera();
  void basculerHautParleur();

  /// L'image de l'autre personne, et la mienne en petit.
  Widget vueDistante();
  Widget vueLocale();

  /// Raccroche (ou annule l'appel s'il sonne encore).
  Future<void> raccrocher();

  /// Libère tout ce que l'appel utilisait (à appeler en quittant l'écran).
  void dispose();
}

/// Les appels voix et vidéo par Internet. Les écrans utilisent cette classe,
/// jamais WebRTC ni Firestore directement (ce qui permet de la remplacer dans
/// les tests).
abstract class ServiceAppel {
  /// Le premier appel qui sonne chez moi, ou null s'il n'y en a pas.
  Stream<AppelEntrant?> appelsEntrants();

  /// Appelle quelqu'un : l'appel sonne chez lui tant qu'il n'a pas répondu.
  Future<SessionAppel> appeler(Contact contact, {required bool video});

  /// Je réponds à un appel entrant.
  Future<SessionAppel> repondre(AppelEntrant appel);

  /// Je refuse un appel entrant.
  Future<void> refuser(AppelEntrant appel);
}

/// Version réelle : WebRTC pour le son et l'image, Firestore pour que les deux
/// téléphones s'échangent les informations de connexion (collection `appels`).
class ServiceAppelFirebase implements ServiceAppel {
  FirebaseFirestore get _base => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Combien de temps un appel sonne avant d'être « manqué ».
  static const Duration dureeSonnerie = Duration(seconds: 45);

  String _moi() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const ErreurAppel('Connectez-vous pour appeler.');
    }
    return uid;
  }

  String get _monNom {
    final nom = _auth.currentUser?.displayName;
    return (nom == null || nom.trim().isEmpty) ? 'Utilisateur' : nom.trim();
  }

  @override
  Stream<AppelEntrant?> appelsEntrants() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _base
        .collection('appels')
        .where('appeleId', isEqualTo: uid)
        .where('statut', isEqualTo: 'sonne')
        .snapshots()
        .map((s) {
          for (final doc in s.docs) {
            final d = doc.data();
            // Un vieil appel resté « en sonnerie » ne doit pas resonner.
            final cree = (d['creeLe'] as Timestamp?)?.toDate();
            if (cree != null &&
                DateTime.now().difference(cree) > dureeSonnerie) {
              continue;
            }
            return AppelEntrant(
              id: doc.id,
              appelantId: (d['appelantId'] as String?) ?? '',
              appelantNom: (d['appelantNom'] as String?) ?? 'Utilisateur',
              video: (d['video'] as bool?) ?? false,
            );
          }
          return null;
        });
  }

  @override
  Future<SessionAppel> appeler(Contact contact, {required bool video}) async {
    final moi = _moi();
    final ref = _base.collection('appels').doc();
    final session = _SessionWebRtc(
      ref: ref,
      moi: moi,
      estAppelant: true,
      video: video,
      // Même identifiant de conversation que la messagerie : les deux
      // identifiants triés, séparés par « _ ».
      conversationId: ([moi, contact.id]..sort()).join('_'),
    );
    try {
      await session.preparer();
      final offre = await session.creerOffre();
      await ref.set({
        'participants': [moi, contact.id],
        'appelantId': moi,
        'appelantNom': _monNom,
        'appeleId': contact.id,
        'appeleNom': contact.nom,
        'video': video,
        'statut': 'sonne',
        'creeLe': FieldValue.serverTimestamp(),
        'offre': offre,
      });
      session.documentPret();
      // Le serveur fait sonner le téléphone de l'autre, même appli fermée.
      unawaited(_prevenirLeServeur(ref.id));
    } on ErreurAppel {
      session.dispose();
      rethrow;
    } on FirebaseException {
      session.dispose();
      throw const ErreurAppel(
        "Impossible de lancer l'appel. Vérifiez votre connexion.",
      );
    }
    return session;
  }

  /// Demande au serveur la notification d'appel. Une erreur n'empêche pas
  /// l'appel : l'autre le voit quand même si son appli est ouverte.
  Future<void> _prevenirLeServeur(String appelId) async {
    try {
      final jeton = await _auth.currentUser?.getIdToken();
      if (jeton == null) return;
      await ServeurStarPole.envoyer('/notifications/appel', {
        'appelId': appelId,
      }, jeton: jeton);
    } catch (e) {
      debugPrint('Notification d\'appel non envoyée ($e)');
    }
  }

  @override
  Future<SessionAppel> repondre(AppelEntrant appel) async {
    final moi = _moi();
    final ref = _base.collection('appels').doc(appel.id);
    final session = _SessionWebRtc(
      ref: ref,
      moi: moi,
      estAppelant: false,
      video: appel.video,
    );
    try {
      final doc = await ref.get();
      final d = doc.data();
      if (d == null || d['statut'] != 'sonne') {
        throw const ErreurAppel('Cet appel est terminé.');
      }
      await session.preparer();
      final reponse = await session.creerReponse(
        Map<String, dynamic>.from(d['offre'] as Map),
      );
      await ref.update({'reponse': reponse, 'statut': 'accepte'});
      session.documentPret();
    } on ErreurAppel {
      session.dispose();
      rethrow;
    } on FirebaseException {
      session.dispose();
      throw const ErreurAppel(
        'Impossible de répondre. Vérifiez votre connexion.',
      );
    }
    return session;
  }

  @override
  Future<void> refuser(AppelEntrant appel) async {
    try {
      await _base.collection('appels').doc(appel.id).update({
        'statut': 'refuse',
      });
    } on FirebaseException {
      // Pas grave : l'appel finira par être « manqué » chez l'appelant.
    }
  }
}

/// Un appel WebRTC dont les échanges passent par un document Firestore.
class _SessionWebRtc implements SessionAppel {
  _SessionWebRtc({
    required this.ref,
    required this.moi,
    required this.estAppelant,
    required this.video,
    this.conversationId,
  });

  final DocumentReference<Map<String, dynamic>> ref;
  final String moi;
  final bool estAppelant;

  /// La conversation avec l'autre personne (connue de l'appelant).
  final String? conversationId;

  @override
  final bool video;

  // Serveurs STUN gratuits : ils aident les deux téléphones à se trouver.
  static const Map<String, dynamic> _configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
        ],
      },
    ],
    'sdpSemantics': 'unified-plan',
  };

  final ValueNotifier<EtatAppel> _etat = ValueNotifier(EtatAppel.sonne);
  final ValueNotifier<bool> _micro = ValueNotifier(false);
  final ValueNotifier<bool> _camera = ValueNotifier(false);
  late final ValueNotifier<bool> _haut = ValueNotifier(video);

  final RTCVideoRenderer _vueLocale = RTCVideoRenderer();
  final RTCVideoRenderer _vueDistante = RTCVideoRenderer();

  RTCPeerConnection? _connexion;
  MediaStream? _flux;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _abonDocument;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _abonCandidats;
  Timer? _delai;

  bool _documentPret = false;
  bool _distantDefini = false;
  bool _arrete = false;
  bool _libere = false;
  final List<Map<String, dynamic>> _aEnvoyer = [];
  final List<RTCIceCandidate> _enAttente = [];

  @override
  ValueListenable<EtatAppel> get etat => _etat;
  @override
  ValueListenable<bool> get microCoupe => _micro;
  @override
  ValueListenable<bool> get cameraCoupee => _camera;
  @override
  ValueListenable<bool> get hautParleur => _haut;

  /// Micro, caméra et connexion : tout est prêt, mais rien n'est encore envoyé.
  Future<void> preparer() async {
    await _vueLocale.initialize();
    await _vueDistante.initialize();
    try {
      _flux = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': video ? {'facingMode': 'user'} : false,
      });
    } catch (_) {
      throw ErreurAppel(
        video
            ? "Autorisez le micro et la caméra pour passer un appel vidéo."
            : 'Autorisez le micro pour passer un appel.',
      );
    }
    _vueLocale.srcObject = _flux;
    final connexion = await createPeerConnection(_configuration);
    _connexion = connexion;
    for (final piste in _flux!.getTracks()) {
      await connexion.addTrack(piste, _flux!);
    }
    connexion.onTrack = (RTCTrackEvent e) {
      if (e.streams.isNotEmpty) _vueDistante.srcObject = e.streams.first;
    };
    connexion.onIceCandidate = _envoyerCandidat;
    connexion.onConnectionState = (RTCPeerConnectionState s) {
      if (s == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _delai?.cancel();
        if (!_arrete) _etat.value = EtatAppel.enCours;
      } else if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _signalerFin('termine');
        _terminer(EtatAppel.echec);
      }
    };
    await Helper.setSpeakerphoneOn(video);
  }

  /// L'appelant crée son offre (sa description du son et de l'image).
  Future<Map<String, dynamic>> creerOffre() async {
    final offre = await _connexion!.createOffer();
    await _connexion!.setLocalDescription(offre);
    return {'sdp': offre.sdp, 'type': offre.type};
  }

  /// La personne appelée reçoit l'offre et crée sa réponse.
  Future<Map<String, dynamic>> creerReponse(Map<String, dynamic> offre) async {
    await _connexion!.setRemoteDescription(
      RTCSessionDescription(offre['sdp'] as String, offre['type'] as String),
    );
    _distantDefini = true;
    final reponse = await _connexion!.createAnswer();
    await _connexion!.setLocalDescription(reponse);
    _etat.value = EtatAppel.connexion;
    return {'sdp': reponse.sdp, 'type': reponse.type};
  }

  /// Le document existe : on envoie les candidats gardés en attente et on
  /// écoute l'autre personne.
  void documentPret() {
    _documentPret = true;
    for (final c in _aEnvoyer) {
      ref.collection('candidats').add(c);
    }
    _aEnvoyer.clear();
    _ecouter();
    if (estAppelant) {
      _delai = Timer(ServiceAppelFirebase.dureeSonnerie, () {
        if (_etat.value == EtatAppel.sonne) {
          _signalerFin('manque');
          _terminer(EtatAppel.manque);
        }
      });
    }
  }

  void _envoyerCandidat(RTCIceCandidate candidat) {
    final donnees = {...candidat.toMap() as Map<String, dynamic>, 'de': moi};
    if (_documentPret) {
      ref.collection('candidats').add(donnees);
    } else {
      _aEnvoyer.add(donnees);
    }
  }

  void _ecouter() {
    _abonDocument = ref.snapshots().listen((doc) async {
      final d = doc.data();
      if (d == null || _arrete) return;
      // L'appelant reçoit la réponse de l'autre personne.
      if (estAppelant && !_distantDefini && d['reponse'] != null) {
        _distantDefini = true;
        final r = Map<String, dynamic>.from(d['reponse'] as Map);
        await _connexion?.setRemoteDescription(
          RTCSessionDescription(r['sdp'] as String, r['type'] as String),
        );
        for (final c in _enAttente) {
          await _connexion?.addCandidate(c);
        }
        _enAttente.clear();
        if (_etat.value == EtatAppel.sonne) _etat.value = EtatAppel.connexion;
      }
      switch (d['statut']) {
        case 'refuse':
          _terminer(EtatAppel.refuse);
        case 'termine' || 'annule':
          _terminer(EtatAppel.termine);
        case 'manque':
          _terminer(EtatAppel.manque);
      }
    });
    _abonCandidats = ref.collection('candidats').snapshots().listen((s) {
      for (final c in s.docChanges) {
        if (c.type != DocumentChangeType.added) continue;
        final d = c.doc.data();
        if (d == null || d['de'] == moi) continue;
        final candidat = RTCIceCandidate(
          d['candidate'] as String?,
          d['sdpMid'] as String?,
          d['sdpMLineIndex'] as int?,
        );
        if (_distantDefini) {
          _connexion?.addCandidate(candidat);
        } else {
          _enAttente.add(candidat);
        }
      }
    });
  }

  /// Écrit la fin de l'appel pour que l'autre personne la voie.
  void _signalerFin(String statut) {
    if (!_documentPret) return;
    ref.update({'statut': statut}).catchError((_) {});
    // Sans réponse (ou annulé avant qu'on décroche) : l'autre personne verra
    // « Appel manqué » dans la conversation en se connectant.
    if (statut == 'manque' || statut == 'annule') _noterAppelManque();
  }

  /// Laisse un message « Appel manqué » dans la conversation, comme un message
  /// envoyé par l'appelant (la liste montre alors qu'il y a du nouveau).
  void _noterAppelManque() {
    final id = conversationId;
    if (id == null) return;
    final base = FirebaseFirestore.instance;
    final conversation = base.collection('conversations').doc(id);
    final texte = video ? 'Appel vidéo manqué' : 'Appel vocal manqué';
    final lot = base.batch();
    lot.set(conversation.collection('messages').doc(), {
      'texte': texte,
      'auteurId': moi,
      'creeLe': FieldValue.serverTimestamp(),
    });
    lot.update(conversation, {
      'dernierMessage': texte,
      'dernierAuteurId': moi,
      'dernierTemps': FieldValue.serverTimestamp(),
      'lu.$moi': FieldValue.serverTimestamp(),
    });
    lot.commit().catchError((_) {});
  }

  /// Coupe tout (son, image, connexion) et annonce l'état final.
  void _terminer(EtatAppel fin) {
    if (_arrete) return;
    _arrete = true;
    _etat.value = fin;
    _delai?.cancel();
    _abonDocument?.cancel();
    _abonCandidats?.cancel();
    for (final piste in _flux?.getTracks() ?? <MediaStreamTrack>[]) {
      piste.stop();
    }
    _connexion?.close();
  }

  @override
  void basculerMicro() {
    _micro.value = !_micro.value;
    for (final p in _flux?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      p.enabled = !_micro.value;
    }
  }

  @override
  void basculerCamera() {
    _camera.value = !_camera.value;
    for (final p in _flux?.getVideoTracks() ?? <MediaStreamTrack>[]) {
      p.enabled = !_camera.value;
    }
  }

  @override
  void basculerHautParleur() {
    _haut.value = !_haut.value;
    Helper.setSpeakerphoneOn(_haut.value);
  }

  @override
  Widget vueDistante() => RTCVideoView(
    _vueDistante,
    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
  );

  @override
  Widget vueLocale() => RTCVideoView(
    _vueLocale,
    mirror: true,
    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
  );

  @override
  Future<void> raccrocher() async {
    if (_arrete) return;
    // Tant que ça sonne, c'est une annulation ; ensuite, une fin d'appel.
    _signalerFin(
      estAppelant && _etat.value == EtatAppel.sonne ? 'annule' : 'termine',
    );
    _terminer(EtatAppel.termine);
  }

  @override
  void dispose() {
    if (_libere) return;
    _libere = true;
    _terminer(_etat.value.estFini ? _etat.value : EtatAppel.termine);
    _vueLocale.srcObject = null;
    _vueDistante.srcObject = null;
    _vueLocale.dispose();
    _vueDistante.dispose();
    _flux?.dispose();
  }
}
