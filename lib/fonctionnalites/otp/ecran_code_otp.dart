import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/couleurs.dart';
import '../../noyau/service_auth.dart';
import '../../partage/composants/vibrant.dart';
import '../../partage/styles.dart';
import '../principal/ecran_principal.dart';

/// Nombre de chiffres du code de confirmation.
const int chiffresOtp = 4;

/// Écran de saisie du code de confirmation (OTP) reçu par e-mail, avec le
/// compte à rebours avant de pouvoir le renvoyer.
///
/// [verifier] reçoit le code complet et renvoie `null` s'il est bon, sinon le
/// message d'erreur à montrer. [renvoyer] demande l'envoi d'un nouveau code et
/// renvoie `null` si c'est fait, sinon le message d'erreur.
class EcranCodeOtp extends StatefulWidget {
  const EcranCodeOtp({
    super.key,
    required this.titre,
    required this.verifier,
    required this.renvoyer,
    this.delaiRenvoi = const Duration(seconds: 60),
  });

  /// « Création du compte » ou « Connexion ».
  final String titre;
  final Future<String?> Function(String code) verifier;
  final Future<String?> Function() renvoyer;

  /// Attente avant de pouvoir demander un nouveau code.
  final Duration delaiRenvoi;

  /// L'écran du code pour une adresse e-mail : le code est vérifié par le
  /// serveur puis [auth] connecte la personne ; « Renvoyer » demande un
  /// nouveau code. [nom] sert à créer le compte à l'inscription.
  factory EcranCodeOtp.parEmail({
    Key? key,
    required String titre,
    required ServiceAuth auth,
    required String email,
    String? nom,
  }) {
    return EcranCodeOtp(
      key: key,
      titre: titre,
      verifier: (code) async {
        try {
          await auth.verifierCode(email: email, code: code, nom: nom);
          return null;
        } on ErreurAuth catch (e) {
          return e.message;
        }
      },
      renvoyer: () async {
        try {
          await auth.demanderCode(email: email);
          return null;
        } on ErreurAuth catch (e) {
          return e.message;
        }
      },
    );
  }

  @override
  State<EcranCodeOtp> createState() => _EcranCodeOtpState();
}

class _EcranCodeOtpState extends State<EcranCodeOtp> {
  final TextEditingController _saisie = TextEditingController();
  final FocusNode _focus = FocusNode();
  final GlobalKey<VibrantState> _cleCases = GlobalKey();

  Timer? _compteARebours;
  late int _secondesRestantes = widget.delaiRenvoi.inSeconds;
  bool _enCours = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _demarrerCompteARebours();
  }

  @override
  void dispose() {
    _compteARebours?.cancel();
    _saisie.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _demarrerCompteARebours() {
    _compteARebours?.cancel();
    _secondesRestantes = widget.delaiRenvoi.inSeconds;
    _compteARebours = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_secondesRestantes > 0) _secondesRestantes--;
        if (_secondesRestantes == 0) t.cancel();
      });
    });
  }

  /// Quand les 4 chiffres sont tapés, le code est vérifié tout de suite.
  Future<void> _surChangement(String texte) async {
    setState(() => _erreur = null);
    if (texte.length < chiffresOtp || _enCours) return;
    FocusScope.of(context).unfocus();
    setState(() => _enCours = true);
    try {
      final erreur = await widget.verifier(texte);
      if (!mounted) return;
      if (erreur == null) {
        await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const EcranPrincipal()),
          (_) => false,
        );
        return;
      }
      // Mauvais code : les cases vibrent, on efface et on réessaie.
      setState(() => _erreur = erreur);
      _cleCases.currentState?.signalerErreur();
      _saisie.clear();
      _focus.requestFocus();
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _renvoyer() async {
    if (_secondesRestantes > 0 || _enCours) return;
    setState(() {
      _erreur = null;
      _saisie.clear();
    });
    _demarrerCompteARebours();
    final erreur = await widget.renvoyer();
    if (mounted && erreur != null) setState(() => _erreur = erreur);
  }

  String get _temps {
    final m = _secondesRestantes ~/ 60;
    final s = (_secondesRestantes % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final largeur = MediaQuery.sizeOf(context).width;
    final code = _saisie.text;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Logo : l'image a de grandes marges, on la recadre.
              SizedBox(
                height: largeur * 0.42,
                child: OverflowBox(
                  maxWidth: largeur * 0.79,
                  maxHeight: largeur * 0.79,
                  child: Image.asset(
                    'assets/images/Starpole logo.png',
                    width: largeur * 0.79,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Text('StarPole', style: Styles.gras(30, Couleurs.rougeMarque)),
              const SizedBox(height: 56),
              // Titre souligné.
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.titre,
                    textAlign: TextAlign.center,
                    style: Styles.gras(24, Couleurs.rougeFonce),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 3,
                    width: 210,
                    decoration: BoxDecoration(
                      color: Couleurs.rougeFonce,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Saisie du code OTP envoyé',
                textAlign: TextAlign.center,
                style: Styles.gras(17, Couleurs.grisTexte),
              ),
              const SizedBox(height: 12),
              Container(
                height: 4,
                width: 70,
                decoration: BoxDecoration(
                  color: Couleurs.rougeFonce,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 36),
              // Les cases : un champ caché reçoit les chiffres tapés.
              Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: _saisie,
                        focusNode: _focus,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(chiffresOtp),
                        ],
                        onChanged: _surChangement,
                        enableInteractiveSelection: false,
                        showCursor: false,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _focus.requestFocus(),
                    child: Vibrant(
                      key: _cleCases,
                      rayon: 10,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < chiffresOtp; i++) ...[
                            if (i > 0) const SizedBox(width: 14),
                            _Case(
                              chiffre: i < code.length ? code[i] : null,
                              active: i == code.length && _focus.hasFocus,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Un trait par chiffre : il se colore quand le chiffre est tapé.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < chiffresOtp; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Container(
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: i < code.length
                            ? Couleurs.rougeFonce
                            : const Color(0xFFCFCFCF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(
                height: 44,
                child: Center(
                  child: _enCours
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Couleurs.rouge,
                          ),
                        )
                      : _erreur != null
                      ? Text(
                          _erreur!,
                          textAlign: TextAlign.center,
                          style: Styles.gras(12.5, Couleurs.rouge),
                        )
                      : null,
                ),
              ),
              Text(
                'Vous avez rencontré un problème',
                style: Styles.gras(12.5, Couleurs.grisTexte),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _renvoyer,
                    child: Opacity(
                      opacity: _secondesRestantes == 0 ? 1 : 0.5,
                      child: Text(
                        'Renvoyer',
                        style: Styles.gras(13, Couleurs.rougeFonce),
                      ),
                    ),
                  ),
                  Text('  ?  ', style: Styles.gras(13, Couleurs.grisTexte)),
                  Text(_temps, style: Styles.gras(13, Couleurs.grisTexte)),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

/// Une case du code : fond gris, fine bordure rouge foncé, gros chiffre. Tant
/// qu'aucun chiffre n'est tapé, un « 0 » pâle montre ce qu'on attend.
class _Case extends StatelessWidget {
  const _Case({required this.chiffre, required this.active});

  final String? chiffre;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFDADADA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Couleurs.rougeFonce, width: active ? 2 : 1),
        boxShadow: Styles.ombre,
      ),
      child: Text(
        chiffre ?? '0',
        style: Styles.gras(
          30,
          chiffre == null
              ? Couleurs.rougeFonce.withValues(alpha: 0.4)
              : Couleurs.rougeFonce,
        ),
      ),
    );
  }
}
