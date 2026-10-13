import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../noyau/messagerie.dart';
import '../../noyau/service_messagerie.dart';
import 'avatar_personne.dart';

/// L'avatar d'un utilisateur à partir de son identifiant : sa photo de profil
/// si elle existe, sinon l'icône de compte. La photo est cherchée une fois
/// (puis gardée en mémoire par le service).
class AvatarUtilisateur extends StatefulWidget {
  const AvatarUtilisateur({
    super.key,
    required this.id,
    this.taille = 48,
    this.avecOmbre = false,
  });

  final String id;
  final double taille;
  final bool avecOmbre;

  @override
  State<AvatarUtilisateur> createState() => _AvatarUtilisateurState();
}

class _AvatarUtilisateurState extends State<AvatarUtilisateur> {
  late final Future<Contact?> _profil = context
      .read<ServiceMessagerie>()
      .profilDe(widget.id);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Contact?>(
      future: _profil,
      builder: (context, instantane) => AvatarPersonne(
        taille: widget.taille,
        photo: instantane.data?.photo,
        avecOmbre: widget.avecOmbre,
      ),
    );
  }
}
