import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../application/couleurs.dart';
import '../../noyau/alerte.dart';
import '../../noyau/cle_mapbox.dart';
import '../styles.dart';
import 'apparence_alerte.dart';
import 'bouton_rouge.dart';

/// Ce qu'il faut pour afficher la carte : les alertes à montrer (avec leur
/// position), celle qui est choisie, et ma position.
class DonneesCarte {
  const DonneesCarte({
    required this.alertes,
    required this.choisieId,
    required this.auChoix,
    required this.hautEntete,
    required this.basFiche,
    this.latitude,
    this.longitude,
  });

  final List<Alerte> alertes;

  /// L'alerte choisie (son repère grossit, la carte se place dessus).
  final String? choisieId;

  /// Appelé quand on touche le repère d'une alerte.
  final ValueChanged<String> auChoix;

  /// Hauteur cachée par le bandeau du haut et par la fiche du bas : la carte
  /// centre ce qu'elle montre dans l'espace restant.
  final double hautEntete;
  final double basFiche;

  /// Ma position, si elle est connue.
  final double? latitude;
  final double? longitude;

  /// « #E3060B » pour une couleur.
  static String couleurHex(Color couleur) =>
      '#${(couleur.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  /// Ce qui est envoyé à la page de la carte 3D.
  Map<String, dynamic> versJson() => {
    'haut': hautEntete,
    'bas': basFiche,
    'moi': latitude != null && longitude != null
        ? {'lat': latitude, 'lng': longitude}
        : null,
    'alertes': [
      for (final a in alertes)
        if (a.aUnePosition)
          {
            'id': a.id,
            'lat': a.latitude,
            'lng': a.longitude,
            'couleur': couleurHex(a.type.couleur),
            'choisie': a.id == choisieId,
            'urgence': a.type == TypeAlerte.urgence,
          },
    ],
  };
}

/// Fabrique la carte. Les écrans la prennent dans les `Provider` (ce qui permet
/// de la remplacer par une fausse carte dans les tests).
typedef ConstructeurCarte = Widget Function(
  BuildContext context,
  DonneesCarte donnees,
);

/// La vraie carte : Mapbox en 3D.
Widget construireCarte3d(BuildContext context, DonneesCarte donnees) =>
    Carte3D(donnees: donnees);

/// Carte Mapbox en 3D (bâtiments en volume, vue inclinée), affichée avec
/// Mapbox GL JS dans une page web intégrée (`assets/carte/carte_3d.html`).
/// L'appli envoie à la page les alertes et ma position ; la page prévient
/// l'appli quand on touche le repère d'une alerte.
class Carte3D extends StatefulWidget {
  const Carte3D({super.key, required this.donnees});

  final DonneesCarte donnees;

  @override
  State<Carte3D> createState() => _Carte3DState();
}

enum _Etat { chargement, prete, erreur }

class _Carte3DState extends State<Carte3D> {
  late final WebViewController _controleur;
  _Etat _etat = _Etat.chargement;
  String? _dernierEnvoi;
  Timer? _delai;

  @override
  void initState() {
    super.initState();
    _controleur = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFE9EDF1))
      ..addJavaScriptChannel('Carte', onMessageReceived: _surMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (erreur) {
            if (erreur.isForMainFrame ?? false) _signalerErreur();
          },
        ),
      );
    _charger();
  }

  @override
  void dispose() {
    _delai?.cancel();
    super.dispose();
  }

  /// Charge (ou recharge) la page de la carte avec mon jeton Mapbox.
  Future<void> _charger() async {
    setState(() => _etat = _Etat.chargement);
    _dernierEnvoi = null;
    // Si la carte n'est pas prête au bout de 25 secondes : connexion trop
    // lente ou absente, on propose de réessayer.
    _delai?.cancel();
    _delai = Timer(const Duration(seconds: 25), () {
      if (mounted && _etat == _Etat.chargement) _signalerErreur();
    });
    try {
      final page = await rootBundle.loadString('assets/carte/carte_3d.html');
      await _controleur.loadHtmlString(
        page.replaceAll('__JETON__', jetonMapbox),
        baseUrl: 'https://localhost',
      );
    } catch (e) {
      // La page n'a pas pu être chargée (par exemple appli pas recompilée
      // après l'ajout du composant natif) : on le montre au lieu de planter.
      debugPrint('Carte 3D : chargement impossible ($e)');
      _signalerErreur();
    }
  }

  void _signalerErreur() {
    if (mounted && _etat != _Etat.prete) setState(() => _etat = _Etat.erreur);
  }

  /// Les messages de la page : carte prête, alerte touchée, erreur.
  void _surMessage(JavaScriptMessage message) {
    try {
      final donnees = jsonDecode(message.message) as Map<String, dynamic>;
      switch (donnees['type']) {
        case 'pret':
          _delai?.cancel();
          if (mounted) setState(() => _etat = _Etat.prete);
          _envoyer();
        case 'alerte':
          widget.donnees.auChoix(donnees['id'] as String);
        case 'erreur':
          // Une erreur avant que la carte soit prête (jeton, style) : on le dit.
          _signalerErreur();
      }
    } catch (_) {
      // Message inattendu : on l'ignore.
    }
  }

  /// Envoie les alertes et ma position à la page (seulement si ça a changé).
  void _envoyer() {
    if (_etat != _Etat.prete) return;
    final json = jsonEncode(widget.donnees.versJson());
    if (json == _dernierEnvoi) return;
    _dernierEnvoi = json;
    _controleur.runJavaScript('miseAJour($json);');
  }

  @override
  void didUpdateWidget(Carte3D ancien) {
    super.didUpdateWidget(ancien);
    _envoyer();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: WebViewWidget(
            controller: _controleur,
            // La carte reçoit tous les gestes (déplacer, zoomer, incliner).
            gestureRecognizers: {
              Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
            },
          ),
        ),
        if (_etat == _Etat.chargement)
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE9EDF1),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Couleurs.rouge),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement de la carte...',
                    style: Styles.gras(13, Couleurs.grisTexte),
                  ),
                ],
              ),
            ),
          ),
        if (_etat == _Etat.erreur)
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE9EDF1),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_off,
                    size: 48,
                    color: Couleurs.grisIndication,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'La carte n\'a pas pu se charger. Vérifiez votre connexion Internet.',
                    textAlign: TextAlign.center,
                    style: Styles.gras(13.5, Couleurs.grisTexte),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 180,
                    child: BoutonRouge(libelle: 'Réessayer', auAppui: _charger),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
