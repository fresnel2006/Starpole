import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Quelqu'un que l'on a ajouté pour discuter avec lui.
class Contact {
  const Contact({
    required this.id,
    required this.nom,
    this.telephone = '',
    this.photo,
  });

  /// L'identifiant de son compte.
  final String id;
  final String nom;
  final String telephone;

  /// Sa photo de profil, quand on vient de le trouver (pas gardée dans la liste).
  final Uint8List? photo;
}

/// Une discussion avec une autre personne, telle qu'elle apparaît dans la liste.
class Conversation {
  const Conversation({
    required this.id,
    required this.autreId,
    required this.autreNom,
    required this.dernierMessage,
    required this.dernierTemps,
    required this.nonLu,
    this.dernierParMoi = false,
  });

  final String id;
  final String autreId;
  final String autreNom;
  final String dernierMessage;
  final DateTime dernierTemps;

  /// Vrai si le dernier message vient de moi.
  final bool dernierParMoi;

  /// Vrai si l'autre personne a écrit et que je n'ai pas encore ouvert la
  /// conversation depuis.
  final bool nonLu;

  /// Lit une conversation depuis un document Firestore, vue par [moi].
  factory Conversation.depuisDonnees(
    String id,
    Map<String, dynamic> d,
    String moi,
  ) {
    DateTime? date(Object? v) => v is Timestamp ? v.toDate() : null;

    final participants = List<String>.from(
      (d['participants'] as List?) ?? const [],
    );
    final autreId = participants.firstWhere((p) => p != moi, orElse: () => '');
    final noms = Map<String, dynamic>.from((d['noms'] as Map?) ?? const {});
    final lu = Map<String, dynamic>.from((d['lu'] as Map?) ?? const {});

    // Juste après l'envoi, la date du serveur n'est pas encore connue.
    final dernierTemps = date(d['dernierTemps']) ?? DateTime.now();
    final dernierAuteurId = (d['dernierAuteurId'] as String?) ?? '';
    final luLe = date(lu[moi]);

    return Conversation(
      id: id,
      autreId: autreId,
      autreNom: (noms[autreId] as String?) ?? '',
      dernierMessage: (d['dernierMessage'] as String?) ?? '',
      dernierTemps: dernierTemps,
      dernierParMoi: dernierAuteurId == moi,
      nonLu:
          dernierAuteurId.isNotEmpty &&
          dernierAuteurId != moi &&
          (luLe == null || luLe.isBefore(dernierTemps)),
    );
  }
}

/// Un message d'une conversation.
class Message {
  const Message({
    required this.id,
    required this.texte,
    required this.auteurId,
    required this.creeLe,
  });

  final String id;
  final String texte;
  final String auteurId;
  final DateTime creeLe;

  factory Message.depuisDonnees(String id, Map<String, dynamic> d) {
    final date = d['creeLe'];
    return Message(
      id: id,
      texte: (d['texte'] as String?) ?? '',
      auteurId: (d['auteurId'] as String?) ?? '',
      // Juste après l'envoi, la date du serveur n'est pas encore connue.
      creeLe: date is Timestamp ? date.toDate() : DateTime.now(),
    );
  }
}
