import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/couleurs.dart';
import '../../noyau/appel.dart';
import '../../noyau/service_appel.dart';
import '../../noyau/sonnerie.dart';
import '../../partage/composants/avatar_utilisateur.dart';
import '../../partage/styles.dart';

/// Fond sombre des écrans d'appel.
const Color fondAppel = Color(0xFF0D0D11);

/// Un appel en cours (voix ou vidéo) : l'autre personne, l'état de l'appel, la
/// durée et les boutons micro, haut-parleur, caméra et raccrocher.
class EcranAppel extends StatefulWidget {
  const EcranAppel({
    super.key,
    required this.session,
    required this.autreId,
    required this.autreNom,
  });

  final SessionAppel session;
  final String autreId;
  final String autreNom;

  @override
  State<EcranAppel> createState() => _EcranAppelState();
}

class _EcranAppelState extends State<EcranAppel> {
  Timer? _chrono;
  int _secondes = 0;
  bool _fermeture = false;

  /// Vrai pendant que la tonalité « tuuut... tuuut... » joue.
  bool _tonalite = false;

  SessionAppel get _session => widget.session;

  @override
  void initState() {
    super.initState();
    _session.etat.addListener(_surChangement);
    _surChangement();
  }

  @override
  void dispose() {
    _session.etat.removeListener(_surChangement);
    _chrono?.cancel();
    if (_tonalite) SonnerieAppel.arreter();
    _session.raccrocher();
    _session.dispose();
    super.dispose();
  }

  void _surChangement() {
    final etat = _session.etat.value;
    // Tant que ça sonne chez l'autre personne, l'appelant entend la tonalité ;
    // elle s'arrête dès qu'on décroche, qu'on refuse ou qu'on raccroche.
    if (etat == EtatAppel.sonne && !_tonalite) {
      _tonalite = true;
      SonnerieAppel.demarrer(hautParleur: _session.video);
    } else if (etat != EtatAppel.sonne && _tonalite) {
      _tonalite = false;
      SonnerieAppel.arreter();
    }
    if (etat == EtatAppel.enCours && _chrono == null) {
      _chrono = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _secondes++);
      });
    }
    if (etat.estFini) {
      _chrono?.cancel();
      // On laisse lire « Appel terminé » un instant avant de fermer.
      if (!_fermeture) {
        _fermeture = true;
        Timer(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    }
    if (mounted) setState(() {});
  }

  /// Je raccroche : on ferme tout de suite, sans attendre.
  Future<void> _raccrocher() async {
    if (_fermeture) return;
    _fermeture = true;
    await _session.raccrocher();
    if (mounted) Navigator.of(context).pop();
  }

  String _libelle(EtatAppel etat) {
    switch (etat) {
      case EtatAppel.sonne:
        return 'Appel en cours...';
      case EtatAppel.connexion:
        return 'Connexion...';
      case EtatAppel.enCours:
        final m = (_secondes ~/ 60).toString().padLeft(2, '0');
        final s = (_secondes % 60).toString().padLeft(2, '0');
        return '$m:$s';
      case EtatAppel.termine:
        return 'Appel terminé';
      case EtatAppel.refuse:
        return 'Appel refusé';
      case EtatAppel.manque:
        return 'Pas de réponse';
      case EtatAppel.echec:
        return 'Connexion impossible';
    }
  }

  @override
  Widget build(BuildContext context) {
    final etat = _session.etat.value;
    final voirVideo = _session.video && etat == EtatAppel.enCours;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _raccrocher();
      },
      child: Scaffold(
        backgroundColor: fondAppel,
        body: Stack(
          children: [
            if (voirVideo) Positioned.fill(child: _session.vueDistante()),
            if (voirVideo)
              Positioned(
                top: 90,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 100,
                    height: 140,
                    child: _session.vueLocale(),
                  ),
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  if (!voirVideo)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AvatarUtilisateur(id: widget.autreId, taille: 140),
                          const SizedBox(height: 22),
                          _Titre(nom: widget.autreNom, libelle: _libelle(etat)),
                        ],
                      ),
                    )
                  else ...[
                    _Titre(nom: widget.autreNom, libelle: _libelle(etat)),
                    const Spacer(),
                  ],
                  _Boutons(session: _session, auRaccrocher: _raccrocher),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Titre extends StatelessWidget {
  const _Titre({required this.nom, required this.libelle});

  final String nom;
  final String libelle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          nom,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Styles.gras(24, Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          libelle,
          style: Styles.gras(
            14,
            const Color(0xFF9A9AA6),
            poids: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Micro, haut-parleur, caméra (en vidéo) et le gros bouton raccrocher.
class _Boutons extends StatelessWidget {
  const _Boutons({required this.session, required this.auRaccrocher});

  final SessionAppel session;
  final VoidCallback auRaccrocher;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: session.microCoupe,
          builder: (context, coupe, _) => BoutonRondAppel(
            libelle: 'Micro',
            icone: coupe ? Icons.mic_off : Icons.mic,
            actif: coupe,
            auAppui: session.basculerMicro,
          ),
        ),
        const SizedBox(width: 20),
        ValueListenableBuilder<bool>(
          valueListenable: session.hautParleur,
          builder: (context, haut, _) => BoutonRondAppel(
            libelle: 'Haut-parleur',
            icone: Icons.volume_up,
            actif: haut,
            auAppui: session.basculerHautParleur,
          ),
        ),
        if (session.video) ...[
          const SizedBox(width: 20),
          ValueListenableBuilder<bool>(
            valueListenable: session.cameraCoupee,
            builder: (context, coupee, _) => BoutonRondAppel(
              libelle: 'Caméra',
              icone: coupee ? Icons.videocam_off : Icons.videocam,
              actif: coupee,
              auAppui: session.basculerCamera,
            ),
          ),
        ],
        const SizedBox(width: 20),
        BoutonRondAppel(
          libelle: 'Raccrocher',
          icone: Icons.call_end,
          fond: Couleurs.rouge,
          auAppui: auRaccrocher,
        ),
      ],
    );
  }
}

/// Un gros bouton rond des écrans d'appel.
class BoutonRondAppel extends StatelessWidget {
  const BoutonRondAppel({
    super.key,
    required this.libelle,
    required this.icone,
    required this.auAppui,
    this.fond,
    this.actif = false,
  });

  final String libelle;
  final IconData icone;
  final VoidCallback auAppui;

  /// Couleur de fond imposée (rouge pour raccrocher, vert pour répondre).
  final Color? fond;

  /// Vrai quand la fonction est activée (le bouton devient blanc).
  final bool actif;

  @override
  Widget build(BuildContext context) {
    final couleurFond =
        fond ?? (actif ? Colors.white : const Color(0xFF26262E));
    final couleurIcone = fond == null && actif ? fondAppel : Colors.white;
    return Semantics(
      button: true,
      label: libelle,
      child: GestureDetector(
        onTap: auAppui,
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(color: couleurFond, shape: BoxShape.circle),
          child: Icon(icone, size: 28, color: couleurIcone),
        ),
      ),
    );
  }
}
