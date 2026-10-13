import 'package:flutter/foundation.dart';

/// L'alerte que l'utilisateur a acceptée d'aider.
class AlerteEnCours {
  const AlerteEnCours({required this.titre, required this.lieu});

  final String titre;
  final String lieu;
}

/// Garde en mémoire l'alerte en cours, pour l'afficher sur tous les écrans.
/// (Plus tard, cette information viendra de la base de données.)
class AlerteEnCoursNotifier extends ChangeNotifier {
  AlerteEnCours? _courante;

  /// L'alerte acceptée, ou null s'il n'y en a pas.
  AlerteEnCours? get courante => _courante;

  /// Appelé quand l'utilisateur appuie sur « Je peux aider ».
  void accepter(AlerteEnCours alerte) {
    _courante = alerte;
    notifyListeners();
  }

  /// Appelé quand l'alerte est terminée ou arrêtée.
  void terminer() {
    _courante = null;
    notifyListeners();
  }
}
