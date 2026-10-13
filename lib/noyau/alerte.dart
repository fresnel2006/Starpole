import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'quartiers.dart';

/// Les trois grands types d'alerte, comme sur l'écran « Poster une alerte ».
enum TypeAlerte {
  urgence('Urgence'),
  don('Dons'),
  service('Services');

  const TypeAlerte(this.libelle);

  final String libelle;

  /// Le mot enregistré dans la base (« urgence », « don », « service »).
  String get code => name;

  static TypeAlerte depuisCode(String? code) {
    return TypeAlerte.values.firstWhere(
      (type) => type.name == code,
      orElse: () => TypeAlerte.urgence,
    );
  }
}

/// Où en est l'alerte.
enum StatutAlerte {
  enCours('en_cours', 'En cours'),
  resolue('resolue', 'Résolue');

  const StatutAlerte(this.code, this.libelle);

  final String code;
  final String libelle;

  static StatutAlerte depuisCode(String? code) {
    return StatutAlerte.values.firstWhere(
      (statut) => statut.code == code,
      orElse: () => StatutAlerte.enCours,
    );
  }
}

/// Les catégories proposées pour chaque type d'alerte.
abstract final class CategoriesAlerte {
  static const Map<TypeAlerte, List<String>> parType = {
    TypeAlerte.urgence: [
      'Personne en detresse',
      'Urgence medicale',
      'Accident',
      'Incendie',
      'Securite',
      'Autre urgence',
    ],
    TypeAlerte.don: [
      'Don de vetement',
      'Don de nourriture',
      'Don de fournitures',
      'Don de meubles',
      'Autre don',
    ],
    TypeAlerte.service: [
      'Coup de main',
      'Objet perdu',
      'Objet trouve',
      'Autre service',
    ],
  };
}

/// Une alerte publiée par un utilisateur (urgence, don ou service).
class Alerte {
  const Alerte({
    required this.id,
    required this.type,
    required this.categorie,
    required this.description,
    required this.ville,
    required this.auteurId,
    required this.auteurNom,
    required this.creeLe,
    this.quartier,
    this.latitude,
    this.longitude,
    this.statut = StatutAlerte.enCours,
    this.aidantId,
    this.aidantNom,
    this.accepteLe,
    this.termineLe,
    this.photo,
  });

  final String id;
  final TypeAlerte type;

  /// Le titre affiché : « Personne en detresse », « Objet perdu »...
  final String categorie;
  final String description;
  final String ville;
  final String? quartier;
  final double? latitude;
  final double? longitude;
  final String auteurId;
  final String auteurNom;
  final StatutAlerte statut;
  final DateTime creeLe;

  /// La personne qui a accepté d'aider, s'il y en a une.
  final String? aidantId;
  final String? aidantNom;
  final DateTime? accepteLe;
  final DateTime? termineLe;
  final Uint8List? photo;

  /// Le lieu à montrer : le quartier, sinon la ville.
  String get lieu =>
      (quartier == null || quartier!.isEmpty) ? ville : quartier!;

  bool get aUnePosition => latitude != null && longitude != null;

  /// Distance en km depuis un point, ou null si l'une des positions manque.
  double? distanceKm(double? depuisLat, double? depuisLon) {
    if (!aUnePosition || depuisLat == null || depuisLon == null) return null;
    return Quartiers.distanceKm(depuisLat, depuisLon, latitude!, longitude!);
  }

  /// Lit une alerte depuis un document Firestore.
  factory Alerte.depuisDonnees(String id, Map<String, dynamic> d) {
    DateTime? date(Object? valeur) =>
        valeur is Timestamp ? valeur.toDate() : null;
    final photo = d['photo'] as String?;
    return Alerte(
      id: id,
      type: TypeAlerte.depuisCode(d['type'] as String?),
      categorie: (d['categorie'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      ville: (d['ville'] as String?) ?? '',
      quartier: d['quartier'] as String?,
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      auteurId: (d['auteurId'] as String?) ?? '',
      auteurNom: (d['auteurNom'] as String?) ?? '',
      statut: StatutAlerte.depuisCode(d['statut'] as String?),
      // Juste après l'envoi, la date du serveur n'est pas encore connue.
      creeLe: date(d['creeLe']) ?? DateTime.now(),
      aidantId: d['aidantId'] as String?,
      aidantNom: d['aidantNom'] as String?,
      accepteLe: date(d['accepteLe']),
      termineLe: date(d['termineLe']),
      photo: (photo == null || photo.isEmpty) ? null : base64Decode(photo),
    );
  }
}

/// Les chiffres affichés sur l'écran Profil.
class StatistiquesProfil {
  const StatistiquesProfil({
    this.alertesPubliees = 0,
    this.aidesApportees = 0,
    this.donsEffectues = 0,
    this.noteMoyenne,
    this.nombreAvis = 0,
  });

  final int alertesPubliees;
  final int aidesApportees;
  final int donsEffectues;

  /// La note moyenne (de 1 à 5), ou null tant que personne ne l'a notée.
  final double? noteMoyenne;
  final int nombreAvis;
}

/// Un message d'avancement écrit sur une alerte (par son auteur ou par la
/// personne qui aide), par exemple « Je suis en route ».
class MiseAJour {
  const MiseAJour({
    required this.id,
    required this.texte,
    required this.auteurId,
    required this.auteurNom,
    required this.creeLe,
  });

  final String id;
  final String texte;
  final String auteurId;
  final String auteurNom;
  final DateTime creeLe;

  /// Lit un message depuis un document Firestore.
  factory MiseAJour.depuisDonnees(String id, Map<String, dynamic> d) {
    final date = d['creeLe'];
    return MiseAJour(
      id: id,
      texte: (d['texte'] as String?) ?? '',
      auteurId: (d['auteurId'] as String?) ?? '',
      auteurNom: (d['auteurNom'] as String?) ?? '',
      // Juste après l'envoi, la date du serveur n'est pas encore connue.
      creeLe: date is Timestamp ? date.toDate() : DateTime.now(),
    );
  }
}
