import 'package:flutter/material.dart';

/// Couleurs de la charte graphique StarPole.
abstract final class Couleurs {
  static const Color rouge = Color(0xFFE3060B);
  static const Color rougeFonce = Color(0xFF8A0003);

  /// Rouge sombre du nom « StarPole » sur la page de connexion.
  static const Color rougeMarque = Color(0xFFB00000);

  /// Rouge plus doux, pour une alerte « en cours ».
  static const Color rougeDoux = Color(0xFFF26B6B);

  static const Color vert = Color(0xFF0B7A4B);
  static const Color orange = Color(0xFFF08A00);
  static const Color bleu = Color(0xFF00AEFF);

  /// Vert vif du badge « 2 Alertes » et rose-rouge du bouton « Catégories ».
  static const Color vertVif = Color(0xFF1FA84A);
  static const Color rougeRose = Color(0xFFF5174B);

  /// Couleurs des trois tuiles de type d'alerte (Urgence, Dons, Services).
  static const Color tuileUrgence = Color(0xFFF4545B);
  static const Color tuileDon = Color(0xFF2EA872);
  static const Color tuileService = Color(0xFF3FB1E6);

  static const Color grisTexte = Color(0xFF555555);
  static const Color grisIndication = Color(0xFF8E8E8E);
  static const Color grisBordure = Color(0xFFE2E2E2);
  static const Color grisFond = Color(0xFFF1F1F1);

  // Fonds des petites étiquettes (Urgent, En cours, Résolue...).
  static const Color fondPuceRouge = Color(0xFFFFDADA);
  static const Color fondPuceOrange = Color(0xFFFFE6CC);
  static const Color fondPuceVerte = Color(0xFFD6EBDD);
}
