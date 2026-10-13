import 'package:flutter/foundation.dart';

import 'service_localisation.dart';

/// Garde en mémoire la dernière position trouvée, pour que tous les écrans
/// (accueil, carte, poster une alerte...) s'en servent sans la redemander.
class PositionUtilisateur extends ChangeNotifier {
  PositionUtilisateur(this._service);

  final ServiceLocalisation _service;

  ResultatLocalisation? _resultat;
  bool _enRecherche = false;

  /// Le dernier résultat, ou null tant qu'on n'a rien cherché.
  ResultatLocalisation? get resultat => _resultat;

  /// Le lieu trouvé, ou null (pas encore cherché, ou introuvable).
  LieuActuel? get lieu => _resultat?.lieu;

  bool get enRecherche => _enRecherche;

  /// Cherche la position (demande l'autorisation la première fois).
  Future<void> actualiser() async {
    if (_enRecherche) return;
    _enRecherche = true;
    notifyListeners();
    try {
      _resultat = await _service.localiser();
    } finally {
      _enRecherche = false;
      notifyListeners();
    }
  }

  /// Ouvre les réglages utiles (GPS ou autorisations), puis cherche de nouveau.
  Future<void> reessayer() async {
    final etat = _resultat?.etat;
    if (etat != null) await _service.ouvrirReglages(etat);
    await actualiser();
  }
}
