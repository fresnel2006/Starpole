import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/appel.dart';
import '../../noyau/service_appel.dart';
import '../../noyau/sonnerie.dart';
import '../../partage/composants/avatar_utilisateur.dart';
import '../../partage/styles.dart';
import 'ecran_appel.dart';

/// Quelqu'un m'appelle : le téléphone vibre et sonne, avec les boutons
/// Refuser et Répondre. L'écran se ferme tout seul si l'appelant raccroche.
class EcranAppelEntrant extends StatefulWidget {
  const EcranAppelEntrant({super.key, required this.appel});

  final AppelEntrant appel;

  @override
  State<EcranAppelEntrant> createState() => _EcranAppelEntrantState();
}

class _EcranAppelEntrantState extends State<EcranAppelEntrant> {
  late final ServiceAppel _service = context.read<ServiceAppel>();
  StreamSubscription<AppelEntrant?>? _abonnement;
  Timer? _sonnerie;
  bool _enReponse = false;
  bool _termine = false;

  @override
  void initState() {
    super.initState();
    // L'appelant a raccroché (ou l'appel est devenu inutile) : on ferme.
    _abonnement = _service.appelsEntrants().listen((appel) {
      if (appel?.id != widget.appel.id) _fermer();
    });
    SonnerieAppel.sonner();
    _sonner();
    _sonnerie = Timer.periodic(const Duration(seconds: 2), (_) => _sonner());
  }

  @override
  void dispose() {
    _abonnement?.cancel();
    _sonnerie?.cancel();
    SonnerieAppel.couper();
    super.dispose();
  }

  /// Une vibration, répétée tant que ça sonne (le son est celui de la
  /// sonnerie du téléphone).
  void _sonner() {
    HapticFeedback.vibrate();
  }

  void _fermer() {
    if (_termine || _enReponse || !mounted) return;
    _termine = true;
    Navigator.of(context).pop();
  }

  Future<void> _refuser() async {
    _termine = true;
    await _service.refuser(widget.appel);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _repondre() async {
    if (_enReponse) return;
    setState(() => _enReponse = true);
    _sonnerie?.cancel();
    SonnerieAppel.couper();
    final messager = ScaffoldMessenger.of(context);
    final navigateur = Navigator.of(context);
    try {
      final session = await _service.repondre(widget.appel);
      if (!mounted) {
        session.dispose();
        return;
      }
      await navigateur.pushReplacement(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => EcranAppel(
            session: session,
            autreId: widget.appel.appelantId,
            autreNom: widget.appel.appelantNom,
          ),
        ),
      );
    } on ErreurAppel catch (e) {
      messager
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
      if (mounted) navigateur.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appel = widget.appel;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: fondAppel,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AvatarUtilisateur(id: appel.appelantId, taille: 140),
                    const SizedBox(height: 22),
                    Text(
                      appel.appelantNom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Styles.gras(24, Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      appel.video
                          ? 'Appel vidéo StarPole'
                          : 'Appel vocal StarPole',
                      style: Styles.gras(
                        14,
                        const Color(0xFF9A9AA6),
                        poids: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BoutonRondAppel(
                    libelle: 'Refuser',
                    icone: Icons.call_end,
                    fond: Couleurs.rouge,
                    auAppui: _refuser,
                  ),
                  const SizedBox(width: 70),
                  BoutonRondAppel(
                    libelle: 'Répondre',
                    icone: appel.video ? Icons.videocam : Icons.call,
                    fond: Couleurs.vertVif,
                    auAppui: _repondre,
                  ),
                ],
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
