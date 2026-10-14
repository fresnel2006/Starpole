import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../noyau/service_auth.dart';
import '../../noyau/service_photo.dart';
import '../styles.dart';
import 'avatar_personne.dart';
import 'choix_source_photo.dart';

/// Photo de profil ronde avec la pastille de modification (le crayon). Un
/// appui sur la photo ou sur le crayon propose caméra ou galerie, puis
/// enregistre la photo choisie. [auChangement] est appelé une fois la photo
/// enregistrée, pour que l'écran recharge le profil.
class PhotoProfilModifiable extends StatefulWidget {
  const PhotoProfilModifiable({
    super.key,
    required this.profil,
    required this.auChangement,
    this.taille = 120,
  });

  /// Null tant que le profil est en cours de chargement.
  final ProfilUtilisateur? profil;
  final VoidCallback auChangement;

  /// Diamètre du cercle.
  final double taille;

  @override
  State<PhotoProfilModifiable> createState() => _PhotoProfilModifiableState();
}

class _PhotoProfilModifiableState extends State<PhotoProfilModifiable> {
  /// Vrai pendant que la nouvelle photo est enregistrée.
  bool _enCours = false;

  void _afficherMessage(String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texte)));
  }

  Future<void> _modifier() async {
    final source = await choisirSourcePhoto(context);
    if (source == null || !mounted) return;

    final photos = context.read<ServicePhoto>();
    final auth = context.read<ServiceAuth>();
    setState(() => _enCours = true);
    try {
      final octets = await photos.choisir(source);
      if (octets == null) return; // l'utilisateur a annulé
      await auth.changerPhoto(octets);
      if (mounted) widget.auChangement();
    } on ErreurPhoto catch (e) {
      if (mounted) _afficherMessage(e.message);
    } on ErreurAuth catch (e) {
      if (mounted) _afficherMessage(e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  /// La photo à montrer, de côté [cote] : la sienne, sinon celle de Google,
  /// sinon l'icône de compte. Elle remplit tout le cercle, centrée (on garde
  /// le milieu de l'image et on coupe ce qui dépasse).
  Widget _contenu(double cote) {
    const icone = IconeCompte();
    final photo = widget.profil?.photo;
    final url = widget.profil?.photoUrl;
    if (photo != null) {
      return Image.memory(
        photo,
        width: cote,
        height: cote,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => icone,
      );
    }
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: cote,
        height: cote,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, _, _) => icone,
      );
    }
    return icone;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.taille;
    final badge = t / 4;
    return Semantics(
      button: true,
      label: 'Modifier la photo de profil',
      child: GestureDetector(
        onTap: _enCours ? null : _modifier,
        child: SizedBox(
          width: t + 6,
          height: t + 6,
          child: Stack(
            children: [
              Container(
                width: t,
                height: t,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: Styles.ombre,
                ),
                // On retire les 2 bordures de 3.
                child: ClipOval(child: _contenu(t - 6)),
              ),
              if (_enCours)
                Container(
                  width: t,
                  height: t,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0x80000000),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 6,
                child: Container(
                  width: badge,
                  height: badge,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: Styles.ombre,
                  ),
                  child: Icon(
                    Icons.edit,
                    size: badge * 0.55,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
