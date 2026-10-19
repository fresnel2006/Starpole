import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/alerte.dart';
import '../../noyau/format_temps.dart';
import '../../noyau/invitation.dart';
import '../../noyau/messagerie.dart';
import '../../noyau/position_utilisateur.dart';
import '../../noyau/service_alertes.dart';
import '../../noyau/service_messagerie.dart';
import '../../partage/composants/apparence_alerte.dart';
import '../../partage/composants/avatar_personne.dart';
import '../../partage/composants/entete_retour.dart';
import '../../partage/composants/puce.dart';
import '../../partage/styles.dart';
import '../messagerie/ecran_conversation.dart';
import 'ecran_suivi_alerte.dart';

/// Détails d'une alerte : description, photo, lieu, et les boutons d'aide.
/// L'écran se met à jour en direct (par exemple si quelqu'un accepte d'aider).
class EcranDetailsAlerte extends StatefulWidget {
  const EcranDetailsAlerte({super.key, required this.alerte});

  /// L'alerte telle qu'elle était dans la liste (affichée tout de suite).
  final Alerte alerte;

  @override
  State<EcranDetailsAlerte> createState() => _EcranDetailsAlerteState();
}

class _EcranDetailsAlerteState extends State<EcranDetailsAlerte> {
  late final Stream<Alerte?> _flux = context.read<ServiceAlertes>().alerte(
    widget.alerte.id,
  );
  bool _enCours = false;

  /// Ouvre l'itinéraire jusqu'à l'alerte dans l'appli de cartes du téléphone.
  Future<void> _ouvrirItineraire(Alerte alerte) async {
    final ouvert = await ouvrirItineraire(alerte);
    if (!ouvert && mounted) {
      _afficherMessage("Impossible d'ouvrir l'itinéraire sur ce téléphone.");
    }
  }

  void _afficherMessage(String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texte)));
  }

  void _ouvrirSuivi(Alerte alerte) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EcranSuiviAlerte(alerteId: alerte.id),
      ),
    );
  }

  /// Ouvre la messagerie directe avec la personne qui a signalé l'alerte.
  Future<void> _ecrireA(Alerte alerte) async {
    final messagerie = context.read<ServiceMessagerie>();
    final auteur = Contact(id: alerte.auteurId, nom: alerte.auteurNom);
    try {
      final id = await messagerie.ouvrirConversation(auteur);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EcranConversation(
            conversationId: id,
            autreId: auteur.id,
            autreNom: auteur.nom,
          ),
        ),
      );
    } on ErreurMessagerie catch (e) {
      if (mounted) _afficherMessage(e.message);
    }
  }

  /// J'accepte d'aider : l'alerte m'est attribuée, puis on ouvre son suivi.
  Future<void> _aider(Alerte alerte) async {
    final service = context.read<ServiceAlertes>();
    setState(() => _enCours = true);
    try {
      await service.accepter(alerte.id);
      if (!mounted) return;
      _ouvrirSuivi(alerte);
    } on ErreurAlerte catch (e) {
      if (mounted) _afficherMessage(e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<ServiceAlertes>();
    final lieu = context.watch<PositionUtilisateur>().lieu;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<Alerte?>(
          stream: _flux,
          initialData: widget.alerte,
          builder: (context, instantane) {
            final alerte = instantane.data;
            if (alerte == null) {
              return const _AlerteIntrouvable();
            }
            final moi = service.utilisateurId;
            final distance = alerte.distanceKm(lieu?.latitude, lieu?.longitude);
            final couleur = alerte.type.couleur;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EnteteRetour(
                    titre: "Details de l'alerte",
                    tailleTitre: 18.5,
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: couleur,
                            shape: BoxShape.circle,
                            boxShadow: Styles.ombre,
                          ),
                          child: alerte.type == TypeAlerte.urgence
                              ? const Icon(
                                  Icons.volunteer_activism,
                                  size: 34,
                                  color: Colors.white,
                                )
                              : alerte.type.icone(taille: 34),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alerte.categorie,
                                style: Styles.gras(19.4, couleur),
                              ),
                              const SizedBox(height: 4),
                              Puce(
                                texte: alerte.statut == StatutAlerte.resolue
                                    ? 'Résolue'
                                    : switch (alerte.type) {
                                        TypeAlerte.urgence => 'Urgent',
                                        TypeAlerte.don => 'Don',
                                        TypeAlerte.service => 'Service',
                                      },
                                fond: alerte.statut == StatutAlerte.resolue
                                    ? Couleurs.fondPuceVerte
                                    : switch (alerte.type) {
                                        TypeAlerte.urgence =>
                                          Couleurs.fondPuceRouge,
                                        TypeAlerte.don =>
                                          Couleurs.fondPuceVerte,
                                        TypeAlerte.service =>
                                          Couleurs.fondPuceOrange,
                                      },
                                couleurTexte:
                                    alerte.statut == StatutAlerte.resolue
                                    ? Couleurs.vert
                                    : couleur,
                                taille: 10.5,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 14, right: 20),
                    child: Text(
                      alerte.description,
                      style: Styles.gras(15.5, Colors.black, hauteur: 1.5),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: Styles.ombre,
                    ),
                    child: PhotoAlerte(
                      photo: alerte.photo,
                      ratio: 2,
                      entiere: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        _LigneInfo(
                          icone: Icons.location_on,
                          texte:
                              (alerte.quartier == null ||
                                  alerte.quartier!.isEmpty)
                              ? alerte.ville
                              : '${alerte.quartier}, ${alerte.ville}',
                        ),
                        const SizedBox(height: 14),
                        _LigneInfo(
                          icone: Icons.schedule,
                          texte: tempsEcoule(alerte.creeLe).toLowerCase(),
                        ),
                        if (distance != null) ...[
                          const SizedBox(height: 14),
                          _LigneInfo(
                            icone: Icons.gps_fixed,
                            texte: libelleDistance(distance),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _Actions(
                    alerte: alerte,
                    moi: moi,
                    enCours: _enCours,
                    aider: () => _aider(alerte),
                    voirSuivi: () => _ouvrirSuivi(alerte),
                    partager: () => partagerAlerte(alerte),
                    itineraire: () => _ouvrirItineraire(alerte),
                  ),
                  const SizedBox(height: 22),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    // Un appui sur l'auteur ouvre la discussion avec lui.
                    onTap: alerte.auteurId == moi
                        ? null
                        : () => _ecrireA(alerte),
                    child: Row(
                      children: [
                        const AvatarPersonne(taille: 52, avecOmbre: true),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Signalé par',
                                style: Styles.gras(
                                  15,
                                  Couleurs.grisTexte,
                                  poids: FontWeight.w500,
                                ),
                              ),
                              Text(
                                alerte.auteurId == moi
                                    ? '${alerte.auteurNom} (vous)'
                                    : alerte.auteurNom,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Styles.gras(15.1, Colors.black),
                              ),
                            ],
                          ),
                        ),
                        if (alerte.auteurId != moi)
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 24,
                            color: Couleurs.rouge,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Les boutons du bas, selon qui regarde l'alerte et où elle en est.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.alerte,
    required this.moi,
    required this.enCours,
    required this.aider,
    required this.voirSuivi,
    required this.partager,
    required this.itineraire,
  });

  final Alerte alerte;
  final String? moi;
  final bool enCours;
  final VoidCallback aider;
  final VoidCallback voirSuivi;
  final VoidCallback partager;
  final VoidCallback itineraire;

  @override
  Widget build(BuildContext context) {
    final estAuteur = alerte.auteurId == moi;
    final estAidant = alerte.aidantId != null && alerte.aidantId == moi;

    final Widget principal;
    if (alerte.statut == StatutAlerte.resolue) {
      principal = const _BoutonAction(
        libelle: 'Alerte résolue',
        icone: Icons.check_circle_outline,
        fond: Couleurs.grisFond,
        couleurTexte: Couleurs.grisTexte,
      );
    } else if (estAuteur || estAidant) {
      principal = _BoutonAction(
        libelle: 'Voir le suivi',
        icone: Icons.timeline,
        fond: Couleurs.vert,
        couleurTexte: Colors.white,
        auAppui: voirSuivi,
      );
    } else if (alerte.aidantId == null) {
      principal = _BoutonAction(
        libelle: 'Je peux aider',
        icone: Icons.handshake_outlined,
        fond: Couleurs.vert,
        couleurTexte: Colors.white,
        enCours: enCours,
        auAppui: aider,
      );
    } else {
      principal = const _BoutonAction(
        libelle: 'Déjà prise en charge',
        icone: Icons.handshake_outlined,
        fond: Couleurs.grisFond,
        couleurTexte: Couleurs.grisTexte,
      );
    }

    return Column(
      children: [
        principal,
        // L'itinéraire n'est proposé que si l'alerte a une position.
        if (alerte.aUnePosition) ...[
          const SizedBox(height: 14),
          _BoutonAction(
            libelle: 'Itinéraire',
            icone: Icons.directions,
            fond: Colors.white,
            couleurTexte: Couleurs.vert,
            auAppui: itineraire,
          ),
        ],
        const SizedBox(height: 14),
        _BoutonAction(
          libelle: 'Partager',
          icone: Icons.share,
          fond: Colors.white,
          couleurTexte: Couleurs.vert,
          auAppui: partager,
        ),
      ],
    );
  }
}

class _AlerteIntrouvable extends StatelessWidget {
  const _AlerteIntrouvable();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EnteteRetour(titre: "Details de l'alerte", tailleTitre: 18.5),
          const SizedBox(height: 60),
          Center(
            child: Text(
              "Cette alerte n'existe plus.",
              style: Styles.gras(14, Couleurs.grisTexte),
            ),
          ),
        ],
      ),
    );
  }
}

class _LigneInfo extends StatelessWidget {
  const _LigneInfo({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 22, color: Colors.black),
        const SizedBox(width: 12),
        Expanded(
          child: Text(texte, style: Styles.gras(14.7, Couleurs.grisTexte)),
        ),
      ],
    );
  }
}

/// Bouton large avec un texte centré et une icône à droite.
class _BoutonAction extends StatelessWidget {
  const _BoutonAction({
    required this.libelle,
    required this.icone,
    required this.fond,
    required this.couleurTexte,
    this.auAppui,
    this.enCours = false,
  });

  final String libelle;
  final IconData icone;
  final Color fond;
  final Color couleurTexte;
  final VoidCallback? auAppui;
  final bool enCours;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: libelle,
      child: GestureDetector(
        onTap: enCours ? null : auAppui,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: fond,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Couleurs.grisBordure),
            boxShadow: Styles.ombre,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (enCours)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: couleurTexte,
                  ),
                )
              else
                Text(libelle, style: Styles.gras(18.5, couleurTexte)),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(icone, size: 24, color: couleurTexte),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
