import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/couleurs.dart';
import '../../noyau/alerte.dart';
import '../../noyau/format_temps.dart';
import '../../noyau/position_utilisateur.dart';
import '../../noyau/service_alertes.dart';
import '../../partage/composants/apparence_alerte.dart';
import '../../partage/composants/avatar_personne.dart';
import '../../partage/composants/entete_retour.dart';
import '../../partage/composants/puce.dart';
import '../../partage/composants/vibrant.dart';
import '../../partage/styles.dart';
import '../evaluation/ecran_noter_aidant.dart';

/// Détail d'une alerte en cours : auteur, description et progression.
/// Il se met à jour en direct. L'auteur et la personne qui aide peuvent y
/// écrire des messages d'avancement, et le terminer ou l'arrêter.
class EcranSuiviAlerte extends StatefulWidget {
  const EcranSuiviAlerte({super.key, required this.alerteId});

  final String alerteId;

  @override
  State<EcranSuiviAlerte> createState() => _EcranSuiviAlerteState();
}

class _EcranSuiviAlerteState extends State<EcranSuiviAlerte> {
  late final Stream<Alerte?> _flux = context.read<ServiceAlertes>().alerte(
    widget.alerteId,
  );
  late final Stream<List<MiseAJour>> _progression = context
      .read<ServiceAlertes>()
      .progression(widget.alerteId);

  final TextEditingController _message = TextEditingController();
  final GlobalKey<VibrantState> _cleSaisie = GlobalKey();
  final ScrollController _defilement = ScrollController();

  /// Vrai pendant une clôture (Terminé, Stopper).
  bool _enCours = false;

  /// Vrai pendant l'envoi d'un message.
  bool _envoiEnCours = false;

  @override
  void dispose() {
    _message.dispose();
    _defilement.dispose();
    super.dispose();
  }

  void _afficherMessage(String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texte)));
  }

  /// Envoie le message d'avancement écrit dans le champ. S'il est vide, le
  /// champ vibre et clignote.
  Future<void> _envoyerMessage(Alerte alerte) async {
    final texte = _message.text.trim();
    if (texte.isEmpty) {
      _cleSaisie.currentState?.signalerErreur();
      return;
    }
    final service = context.read<ServiceAlertes>();
    setState(() => _envoiEnCours = true);
    try {
      await service.envoyerProgression(alerte.id, texte);
      if (!mounted) return;
      _message.clear();
      // On descend en bas de la liste pour voir le nouveau message.
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _defilement.hasClients) {
          _defilement.animateTo(
            _defilement.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } on ErreurAlerte catch (e) {
      if (mounted) _afficherMessage(e.message);
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  /// « Terminé » et « Stopper » : on clôture l'alerte, puis on ouvre la note
  /// de l'autre personne (l'aidant si je suis l'auteur, l'auteur si j'aide).
  ///
  /// [arret] est vrai pour « Stopper ». Un aidant qui s'arrête libère l'alerte
  /// (elle redevient disponible) ; l'auteur qui s'arrête la ferme.
  Future<void> _cloturer(Alerte alerte, {required bool arret}) async {
    final service = context.read<ServiceAlertes>();
    final estAuteur = alerte.auteurId == service.utilisateurId;

    setState(() => _enCours = true);
    try {
      if (arret && !estAuteur) {
        await service.arreter(alerte.id);
      } else {
        await service.terminer(alerte.id);
      }
    } on ErreurAlerte catch (e) {
      if (mounted) {
        setState(() => _enCours = false);
        _afficherMessage(e.message);
      }
      return;
    }
    if (!mounted) return;

    final personneId = estAuteur ? alerte.aidantId : alerte.auteurId;
    final personneNom = estAuteur ? alerte.aidantNom : alerte.auteurNom;
    if (personneId == null) {
      // Personne n'avait accepté d'aider : il n'y a personne à noter.
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    // On remplace cet écran : après « Envoyer », on revient où l'on était.
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => EcranNoterAidant(
          alerteId: alerte.id,
          personneId: personneId,
          personneNom: personneNom ?? '',
          titre: estAuteur ? "Noter l'aidant" : "Noter l'auteur",
          role: estAuteur ? 'Citoyen benevol' : "Auteur de l'alerte",
        ),
      ),
    );
  }

  /// Les étapes de la timeline, de la plus ancienne à la plus récente :
  /// création, acceptation, messages d'avancement, résolution.
  List<_Etape> _etapes(Alerte alerte, List<MiseAJour> messages, String? moi) {
    final etapes = <_Etape>[
      _Etape(alerte.creeLe, 'Alerte crée'),
      if (alerte.aidantNom != null)
        _Etape(alerte.accepteLe ?? alerte.creeLe, '${alerte.aidantNom} repond'),
      for (final m in messages)
        _Etape(
          m.creeLe,
          '${m.auteurId == moi ? 'Vous' : m.auteurNom} : ${m.texte}',
        ),
      if (alerte.statut == StatutAlerte.resolue)
        _Etape(alerte.termineLe ?? alerte.creeLe, 'Alerte résolue'),
    ]..sort((a, b) => a.date.compareTo(b.date));
    return etapes;
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
          builder: (context, instantane) {
            final alerte = instantane.data;
            if (alerte == null) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const EnteteRetour(titre: "Detail de l'alerte"),
                    const SizedBox(height: 60),
                    Center(
                      child:
                          instantane.connectionState == ConnectionState.waiting
                          ? const CircularProgressIndicator(
                              color: Couleurs.rouge,
                            )
                          : Text(
                              "Cette alerte n'existe plus.",
                              style: Styles.gras(14, Couleurs.grisTexte),
                            ),
                    ),
                  ],
                ),
              );
            }

            final moi = service.utilisateurId;
            final estAuteur = alerte.auteurId == moi;
            final estAidant = alerte.aidantId != null && alerte.aidantId == moi;
            // Écrire, terminer ou arrêter : seulement l'auteur et la personne
            // qui aide, tant que l'alerte est en cours.
            final participant =
                alerte.statut == StatutAlerte.enCours &&
                (estAuteur || estAidant);
            final distance = alerte.distanceKm(lieu?.latitude, lieu?.longitude);
            final resolue = alerte.statut == StatutAlerte.resolue;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _defilement,
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const EnteteRetour(titre: "Detail de l'alerte"),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: alerte.type.couleur,
                                shape: BoxShape.circle,
                                boxShadow: Styles.ombre,
                              ),
                              child: alerte.type.icone(taille: 30),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          alerte.categorie,
                                          maxLines: 2,
                                          style: Styles.gras(
                                            15,
                                            alerte.type.couleur,
                                          ),
                                        ),
                                      ),
                                      Puce(
                                        texte: alerte.statut.libelle,
                                        fond: resolue
                                            ? Couleurs.fondPuceVerte
                                            : Couleurs.fondPuceOrange,
                                        couleurTexte: resolue
                                            ? Couleurs.vert
                                            : Couleurs.orange,
                                        taille: 10,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    distance == null
                                        ? alerte.lieu
                                        : '${alerte.lieu} • ${libelleDistance(distance)}',
                                    style: Styles.gras(11.5, Colors.black),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.schedule,
                                        size: 15,
                                        color: Couleurs.grisTexte,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Reçu ${tempsEcoule(alerte.creeLe).toLowerCase()}',
                                        style: Styles.gras(
                                          10.5,
                                          Couleurs.grisTexte,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(height: 1, color: Couleurs.grisBordure),
                        const SizedBox(height: 12),
                        Text(
                          'Temoin / auteur',
                          style: Styles.gras(
                            11.5,
                            Couleurs.grisTexte,
                            poids: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const AvatarPersonne(taille: 52, avecOmbre: true),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                estAuteur
                                    ? '${alerte.auteurNom} (vous)'
                                    : alerte.auteurNom,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Styles.gras(14.5, Colors.black),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(height: 1, color: Couleurs.grisBordure),
                        const SizedBox(height: 14),
                        Text(
                          'Description',
                          style: Styles.gras(14, Colors.black),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          alerte.description,
                          style: Styles.gras(
                            12.5,
                            Colors.black,
                            hauteur: 1.55,
                            poids: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text('Timeline', style: Styles.gras(14, Colors.black)),
                        const SizedBox(height: 12),
                        // La progression : étapes de l'alerte et messages.
                        StreamBuilder<List<MiseAJour>>(
                          stream: _progression,
                          builder: (context, progression) {
                            final etapes = _etapes(
                              alerte,
                              progression.data ?? const [],
                              moi,
                            );
                            return Column(
                              children: [
                                for (var i = 0; i < etapes.length; i++)
                                  _EtapeTimeline(
                                    heure: heureCourte(etapes[i].date),
                                    texte: etapes[i].texte,
                                    faite: true,
                                    derniere: i == etapes.length - 1 && resolue,
                                  ),
                                if (!resolue)
                                  const _EtapeTimeline(
                                    heure: '',
                                    texte: '-',
                                    faite: false,
                                    derniere: true,
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (participant)
                  _BasDePage(
                    controleur: _message,
                    cleSaisie: _cleSaisie,
                    envoiEnCours: _envoiEnCours,
                    enCours: _enCours,
                    envoyer: () => _envoyerMessage(alerte),
                    termine: () => _cloturer(alerte, arret: false),
                    stoppe: () => _cloturer(alerte, arret: true),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Une étape à montrer dans la timeline.
class _Etape {
  const _Etape(this.date, this.texte);

  final DateTime date;
  final String texte;
}

/// Une étape de la timeline : pastille verte cochée (ou rouge) et texte.
class _EtapeTimeline extends StatelessWidget {
  const _EtapeTimeline({
    required this.heure,
    required this.texte,
    required this.faite,
    this.derniere = false,
  });

  final String heure;
  final String texte;
  final bool faite;
  final bool derniere;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: derniere ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: faite ? Couleurs.vert : Couleurs.rouge,
              shape: BoxShape.circle,
            ),
            child: faite
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 14),
          if (heure.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(heure, style: Styles.gras(13, Couleurs.grisTexte)),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                texte,
                style: Styles.gras(13, Couleurs.grisTexte, hauteur: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bas de page : champ d'avancement avec son bouton d'envoi, puis les
/// boutons Terminé et Stopper.
class _BasDePage extends StatelessWidget {
  const _BasDePage({
    required this.controleur,
    required this.cleSaisie,
    required this.envoiEnCours,
    required this.enCours,
    required this.envoyer,
    required this.termine,
    required this.stoppe,
  });

  final TextEditingController controleur;
  final GlobalKey<VibrantState> cleSaisie;
  final bool envoiEnCours;
  final bool enCours;
  final VoidCallback envoyer;
  final VoidCallback termine;
  final VoidCallback stoppe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Vibrant(
                  key: cleSaisie,
                  rayon: 22,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Couleurs.grisBordure),
                      boxShadow: Styles.ombre,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sentiment_satisfied_alt,
                          size: 24,
                          color: Color(0xFFFFB300),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: controleur,
                            maxLength: 300,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => envoyer(),
                            buildCounter: (
                              _, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) => null,
                            style: Styles.gras(12, Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Decrivez la situation ...',
                              hintStyle: Styles.gras(
                                11.5,
                                Couleurs.grisIndication,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Semantics(
                button: true,
                label: 'Envoyer le message',
                child: GestureDetector(
                  onTap: envoiEnCours ? null : envoyer,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Couleurs.rouge,
                      shape: BoxShape.circle,
                      boxShadow: Styles.ombre,
                    ),
                    child: envoiEnCours
                        ? const Padding(
                            padding: EdgeInsets.all(11),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, size: 22, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: enCours ? null : termine,
                child: const Puce(
                  texte: 'Terminé',
                  fond: Couleurs.rouge,
                  couleurTexte: Colors.white,
                  taille: 11,
                  ombre: true,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: enCours ? null : stoppe,
                child: const Puce(
                  texte: 'Stopper',
                  fond: Colors.white,
                  couleurTexte: Couleurs.rouge,
                  taille: 11,
                  ombre: true,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
